#import <Foundation/Foundation.h>
#import <DiskArbitration/DiskArbitration.h>
#import "NTFSDisk.h"
#import "FileSystemTableParser.h"
#import "Tools.h"
#import "Constants.h"
#include <signal.h>
#include <pthread.h>

/* Global vars */
NSURL* _iconUrl = nil;
NSString* _defaultLang = nil;

DADissenterRef diskDidMount(DADiskRef, void*);
void* handleDisk_Thread(void*);
void SIGTERM_handler(const int);

int main(int argc, const char* argv[])
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if (geteuid() != 0)
		NSLog(@"Not running as root... Enabling NTFS writing will fail.");
	
	/* Check if prefPane exists */
	if (![Tools prefPaneExists])
		return EXIT_FAILURE;
	_iconUrl = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@/Contents/Resources/slntfs.icns", SLNTFS_PATH]];
	
	NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
	NSArray* languages = [defs objectForKey:@"AppleLanguages"];
	_defaultLang = [[NSString alloc] initWithString:[languages objectAtIndex:0]];

	signal(SIGTERM, (sig_t)SIGTERM_handler);
	signal(SIGINT, (sig_t)SIGTERM_handler);
	signal(SIGKILL, (sig_t)SIGTERM_handler);

	DASessionRef session = DASessionCreate(kCFAllocatorDefault);
    DARegisterDiskMountApprovalCallback(session, NULL, diskDidMount, NULL);
    DASessionScheduleWithRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	CFRunLoopRun();

	DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	CFRelease(session);
	NICE_RELEASE(_iconUrl);
	NICE_RELEASE(_defaultLang);

	[pool drain];
	return 0;
}

DADissenterRef diskDidMount(DADiskRef dsk, void* context)
{
	NSDictionary* SLNTFSpref = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Preferences/slntfspref_copy.plist"];
	if (SLNTFSpref)
	{
		if (![[SLNTFSpref objectForKey:PREF_DAEMON] boolValue])
			return NULL;
	}
	else
		return NULL;
	NSString* name = [[NSString alloc] initWithUTF8String:DADiskGetBSDName(dsk)];	
	NSArray* args = [[NSArray alloc] initWithObjects:@"info", name, nil];
	[name release];
	NSData* data = [Tools executeCommand:BIN_DISKUTIL_PATH withArguments:args];
	[args release];
	NSString* info = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if ([info rangeOfString:@"NTFS"].location != NSNotFound) // NTFS disk
	{
		NTFSDisk* disk = [[[NTFSDisk alloc] initWithDiskutilInfo:info] autorelease];
		pthread_t pth;
		pthread_create(&pth, NULL, handleDisk_Thread, disk);
	}
	[info release];
	return NULL;
}

void* handleDisk_Thread(void* arg)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NTFSDisk* disk = (NTFSDisk*)arg;
	FileSystemTableParser* fstabParser = [[FileSystemTableParser alloc] initWithCopyPath:@"./"];
	[fstabParser fstabRead];
	if (![fstabParser isWrittingEnabledOn:disk.Name]) // Not enabled on NAME
	{
		if (![fstabParser isWrittingEnabledOn:disk.UUID]) // Nor on UUID
		{
			NSDictionary* SLNTFSpref = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Preferences/slntfspref_copy.plist"];
			if (SLNTFSpref)
			{
				void (^enableWriting)() = ^
				{
					if (![disk.UUID isEqualToString:@""])
						[fstabParser addUUIDline:disk.UUID]; // Add UUID line
					[fstabParser addLABELline:disk.Name]; // Also add LABEL line
					if (![fstabParser save])
					{
						[fstabParser restoreBackup];
					}
					[disk unmount];
					[disk mount];
				};
				
				NSString* actionToPerformValue = [SLNTFSpref objectForKey:PREF_ATP];
				if ([actionToPerformValue isEqualToString:PREF_ATP_OPTION_ASK]) // Check Action to perform
				{
					NSString* title = nil;
					NSString* text = nil;
					NSString* btnDismiss = nil;
					NSString* btnEnable = nil;
					if ([_defaultLang isEqualToString:@"de"])
					{
						title = [NSString stringWithFormat:@"NTFS-Volume wurde erkann (%@)", disk.Name];
						text = @"Schreibzugriff aktivieren ?";
						btnEnable = @"Ja";
						btnDismiss = @"Nein";
					}
					else if ([_defaultLang isEqualToString:@"fr"])
					{
						title = [NSString stringWithFormat:@"Détection d'un disque NTFS (%@)", disk.Name];
						text = @"Voulez vous activer l'écriture sur celui-ci ?";
						btnEnable = @"Activer";
						btnDismiss = @"Ignorer";
					}
					else if ([_defaultLang isEqualToString:@"es"])
					{
						title = [NSString stringWithFormat:@"Detección de un disco NTFS (%@)", disk.Name];
						text = @"Quieres activar la escritura sobre este ?";
						btnEnable = @"Activar";
						btnDismiss = @"Ignorar";
					}
					else
					{
						title = [NSString stringWithFormat:@"NTFS Disk mounted (%@)", disk.Name];
						text = @"Would you like to enable writing on it ?";
						btnEnable = @"Enable";
						btnDismiss = @"Dismiss";
					}
							 
					CFOptionFlags resp;
					CFUserNotificationDisplayAlert(
																15,
																0,
																(CFURLRef)_iconUrl,
																NULL,
																NULL,
																(CFStringRef)title,
																(CFStringRef)text,
																(CFStringRef)btnEnable,
																(CFStringRef)btnDismiss,
																NULL,
																&resp);
					if (kCFUserNotificationDefaultResponse == resp) // Enable
					{
						enableWriting();
					}		
				}
				else if ([actionToPerformValue isEqualToString:PREF_ATP_OPTION_ENABLE]) // Automatically enable
				{
					enableWriting();
				}
			}
		}
	}
	[fstabParser release];
	[pool release];
	return NULL;
}

void SIGTERM_handler(const int sigid)
{
	if (SIGTERM == sigid || SIGINT == sigid || SIGKILL == sigid)
		CFRunLoopStop(CFRunLoopGetCurrent());
}

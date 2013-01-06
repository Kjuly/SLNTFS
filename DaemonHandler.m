#import "DaemonHandler.h"
#import "ProcessHelper.h"
#import "Constants.h"
#import "Tools.h"

@implementation DaemonHandler

+(BOOL)helperIsLaunchedAtLogin:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString*)path
{
	UInt32 seedValue;
	NSArray* loginItemsArray = (NSArray*)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
	for (id item in loginItemsArray)
	{		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*)&url, NULL) == noErr) // Helper is launched at login
		{
			[loginItemsArray release];
			return YES;
		}
	}
	[loginItemsArray release];
	return NO;
}

+(BOOL)daemonIsLaunchedAtLogin
{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	return ([fileManager fileExistsAtPath:[NSString stringWithCString:LAUNCHCTL_PLIST_PATH encoding:NSASCIIStringEncoding]]);
}

+(BOOL)helperIsLaunched
{
	ProcessHelper* procInfo = [[ProcessHelper alloc] init];
	[procInfo obtainFreshProcessList]; // Get a list of process
	BOOL helperLaunched = [procInfo findProcessWithName:@"SLNTFS Helper"];
	[procInfo release];
	return helperLaunched;
}

+(BOOL)daemonIsLaunched
{
	ProcessHelper* procInfo = [[ProcessHelper alloc] init];
	[procInfo obtainFreshProcessList]; // Get a list of process
	BOOL daemonLaunched = [procInfo findProcessWithName:@"SLNTFS Daemon"];
	[procInfo release];
	return daemonLaunched;
}

+(BOOL)launchHelper:(NSString*)path
{
	return [[NSWorkspace sharedWorkspace] launchApplication:path]; // Launch helper
}

+(BOOL)launchDaemon:(SFAuthorization*)auth
{
	char* loadArgs[3] = {"load", LAUNCHCTL_PLIST_PATH, NULL}; // Launch daemon
	OSStatus ret = AuthorizationExecuteWithPrivileges([auth authorizationRef], [BIN_LAUNCHCTL_PATH cStringUsingEncoding:NSASCIIStringEncoding], kAuthorizationFlagDefaults, loadArgs, NULL);
	return (ret == errAuthorizationSuccess);
}

+(void)terminateHelper
{
	NSArray* apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:HELPER_BUNDLE_ID];
	for (NSRunningApplication* app in apps)
		[app terminate];
}

+(BOOL)terminateDaemon:(SFAuthorization*)auth
{
	char* unloadArgs[3] = {"unload", LAUNCHCTL_PLIST_PATH, NULL}; // Stop daemon
	OSStatus ret = AuthorizationExecuteWithPrivileges([auth authorizationRef], [BIN_LAUNCHCTL_PATH cStringUsingEncoding:NSASCIIStringEncoding], kAuthorizationFlagDefaults, unloadArgs, NULL);
	return (ret == errAuthorizationSuccess);
}

+(void)enableHelperAtLoginWithItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString*)path
{
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);		
	if (item)
		CFRelease(item);
}

+(void)enableDaemonAtLoginWithAuthorization:(SFAuthorization*)auth
{
	NSString* plistPath = [NSString stringWithFormat:@"%@/com.juicybinary.slntfsDaemon.plist", [[NSBundle bundleForClass:[self class]] resourcePath]];
	char* cpArgs[3] = {(char*)[plistPath cStringUsingEncoding:NSASCIIStringEncoding], LAUNCHCTL_PLIST_PATH, NULL};
	AuthorizationExecuteWithPrivileges([auth authorizationRef], [BIN_CP_PATH cStringUsingEncoding:NSASCIIStringEncoding], kAuthorizationFlagDefaults, cpArgs, NULL);
}

+(void)disableHelperAtLoginWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString*)path
{
	UInt32 seedValue;
	NSArray* loginItemsArray = (NSArray*)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
	for (id item in loginItemsArray)
	{		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*)&url, NULL) == noErr)
		{
			if ([[(NSURL*)url path] hasPrefix:path])
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef);
		}
	}
	[loginItemsArray release];
}

+(void)disableDaemonAtLoginWithAuthorization:(SFAuthorization*)auth
{
	char* rmArgs[2] = {LAUNCHCTL_PLIST_PATH, NULL};
	AuthorizationExecuteWithPrivileges([auth authorizationRef], [BIN_RM_PATH cStringUsingEncoding:NSASCIIStringEncoding], kAuthorizationFlagDefaults, rmArgs, NULL);
}

+(void)launchDaemonsAtLogin:(BOOL)state withAuthorization:(SFAuthorization*)auth
{
	LSSharedFileListRef loginItems = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, NULL);
	NSString* helperPath = [NSString stringWithFormat:@"%@/Contents/Resources/SLNTFS Helper.app", [[NSBundle bundleForClass:[self class]] bundlePath]];
	if (state) // Launch at login
	{
		/* Check if daemons are registered as login apps */
		ALog(@"Registering daemons to login items...");
		if (![DaemonHandler helperIsLaunchedAtLogin:loginItems forPath:helperPath])
			[DaemonHandler enableHelperAtLoginWithItemsReference:loginItems forPath:helperPath];
		if (![DaemonHandler daemonIsLaunchedAtLogin])
			[DaemonHandler enableDaemonAtLoginWithAuthorization:auth];
		/* Launch them if needed */
		ALog(@"Launching daemons...");
		if (![DaemonHandler helperIsLaunched]) // Launching helper
			[self launchHelper:helperPath];
		if (![DaemonHandler daemonIsLaunched]) // Launching daemon
			[self launchDaemon:auth];		
	}
	else
	{
		ALog(@"Terminating daemons...");
		if ([DaemonHandler daemonIsLaunched]) // Terminate daemon
			[self terminateDaemon:auth];
		if ([DaemonHandler helperIsLaunched]) // Terminate helper
			[self terminateHelper];
		ALog(@"Removing daemons from login items...");
		if ([DaemonHandler helperIsLaunchedAtLogin:loginItems forPath:helperPath])
			[self disableHelperAtLoginWithLoginItemsReference:loginItems forPath:helperPath];
		if ([DaemonHandler daemonIsLaunchedAtLogin])
			[self disableDaemonAtLoginWithAuthorization:auth];
	}
	CFRelease(loginItems);
}

@end

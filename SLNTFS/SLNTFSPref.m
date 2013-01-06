
#import "SLNTFSPref.h"
#import "FileSystemTableParser.h"
#import "NTFSDisk.h"
#import "Tools.h"
#import "Constants.h"
#import "DaemonHandler.h"
#import <SecurityFoundation/SFAuthorization.h>
#import <Sparkle/Sparkle.h>
#import <sys/types.h>
#import <sys/stat.h>

@implementation SLNTFSPref

#pragma mark -
#pragma mark Constructors / Destructors

+ (void)initialize {
	const char * const appID =
  [[Tools getBundleIdentifierForClass:[self class]] cStringUsingEncoding:NSASCIIStringEncoding];
	CFStringRef bundleID = CFStringCreateWithCString(kCFAllocatorDefault, appID, kCFStringEncodingASCII);
	CFBooleanRef b = NULL;
	CFStringRef  r = NULL;
	b = (CFBooleanRef)CFPreferencesCopyAppValue((CFStringRef)PREF_DAEMON_KEY, bundleID); // Daemon pref
	if (!b) CFPreferencesSetAppValue((CFStringRef)PREF_DAEMON_KEY, kCFBooleanFalse, bundleID);
	else    CFRelease(b);
  
	b = (CFBooleanRef)CFPreferencesCopyAppValue(CFSTR("SUEnableAutomaticChecks"), bundleID);
	if (!b) CFPreferencesSetAppValue(CFSTR("SUEnableAutomaticChecks"), kCFBooleanTrue, bundleID);
	else    CFRelease(b);
  
	r = (CFStringRef)CFPreferencesCopyAppValue((CFStringRef)PREF_ATP_KEY, bundleID); // Action to perform pref
	if (!r) CFPreferencesSetAppValue((CFStringRef)PREF_ATP_KEY, (CFStringRef)PREF_ATP_OPT_ASK, bundleID);
	else    CFRelease(r);
  
	CFPreferencesAppSynchronize(bundleID);
	CFRelease(bundleID);
}

- (id)initWithBundle:(NSBundle *)bundle {
	if (self = [super initWithBundle:bundle]) {
		const char * const appID =
    [[Tools getBundleIdentifierForClass:[self class]] cStringUsingEncoding:NSASCIIStringEncoding];
		_bundleIdentifier = CFStringCreateWithCString(kCFAllocatorDefault, appID, kCFStringEncodingASCII);
	}
	return self;
}

- (void)mainViewDidLoad {
	[self setInstalledVersionString];
	[self setTooltips];
  
	/* Authorization view configuration */
	[_authorizationView setString:"system.privilege.admin"];
	[_authorizationView setDelegate:self];
	[_authorizationView updateStatus:self];
	[_authorizationView setAutoupdate:YES];
  
	/* Attributes configurations */
	_tryEnableWriting = NO;
	_disks = [[NSMutableArray alloc] init];
	_fstabParser = [[FileSystemTableParser alloc] initWithCopyPath:@"/tmp/"];
	[_fstabParser fstabRead]; // Read the fstab file
	
	/* Configure GUI */
	CFBooleanRef daemonEnabled =
  (CFBooleanRef)CFPreferencesCopyAppValue((CFStringRef)PREF_DAEMON_KEY, _bundleIdentifier);
	[_btnDaemon setState:CFBooleanGetValue(daemonEnabled)];
	[_actionToPerform setEnabled:CFBooleanGetValue(daemonEnabled)];
	CFRelease(daemonEnabled);
	[self enableControls:NO];
  
	[self listDisks]; // Get the mounted disk list
  
	/* About configuration */
	NSAttributedString * about =
  [[NSAttributedString alloc] initWithPath:[[self bundle] pathForResource:@"Read Me" ofType:@"rtf"]
                         documentAttributes:nil];
	[[_aboutView textStorage] setAttributedString:about];
	
	/* Notifications configuration */
	NSNotificationCenter * center = [[NSWorkspace sharedWorkspace] notificationCenter];
	[center addObserver:self selector:@selector(diskDidMount:)   name:NSWorkspaceDidMountNotification   object:nil];
	[center addObserver:self selector:@selector(diskDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
}

- (void)didUnselect {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	CFRelease(_bundleIdentifier);
}

#pragma mark -
#pragma mark TableView delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
#pragma unused(aTableView)
	return [_disks count];
}

- (id)          tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
                      row:(NSInteger)row {
  // Confirm the TableView
	if (aTableView == _disksView) {
    NTFSDisk * disk = [_disks objectAtIndex:row];
		if (aTableColumn == _tcDiskNameColumn)
      return (disk.name) ? disk.name : @"???";
    else if (aTableColumn == _tcStateColumn)
      return [NSNumber numberWithUnsignedInteger:disk.isWrittingEnabled];
    else {
			NSString * str = nil;
			NSString * ressourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
			if (P_USB == disk.protocol)
				str = [NSString stringWithFormat:@"%@/disk_usb.icns", ressourcePath];
			else if (P_FIREWIRE == disk.protocol)
				str = [NSString stringWithFormat:@"%@/disk_firewire.icns", ressourcePath];
			else if (P_SATA == disk.protocol)
				str = [NSString stringWithFormat:@"%@/disk_internal.icns", ressourcePath];
			else
				str = [NSString stringWithFormat:@"%@/disk_external.icns", ressourcePath];
			return [[NSImage alloc] initWithContentsOfFile:str];
    }
  }
  return nil;
}

- (void)tableView:(NSTableView *)aTableView
  willDisplayCell:(id)aCell
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)row {
#pragma unused(aTableView)
#pragma unused(aTableColumn)
	if ([aCell respondsToSelector:@selector(setTextColor:)]) {
		NTFSDisk * disk = [_disks objectAtIndex:row];
    if (disk.isMounted) [aCell setTextColor:[NSColor blackColor]];
		else              [aCell setTextColor:[NSColor grayColor]];
	}
}

#pragma mark -
#pragma mark SFAuthorizationView delegates

- (void)authorizationViewCreatedAuthorization:(SFAuthorizationView *)view {
#pragma unused(view)
	[self enableControls:NO];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
#pragma unused(view)
	[self enableControls:YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
#pragma unused(view)
	[self enableControls:NO];
}

#pragma mark -
#pragma mark IBActions

- (IBAction)launchWebSite:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:WEBSITE]];
}

- (IBAction)checkForUpdates:(id)sender {
	SUUpdater * updater = [SUUpdater updaterForBundle:[NSBundle bundleForClass:[self class]]];
	[updater checkForUpdates:sender];
}

- (IBAction)performMountingAction:(id)sender {
	NSInteger row = [_disksView selectedRow];
	if (row > -1) {
		NTFSDisk * disk = [_disks objectAtIndex:row];
		if (sender == _btnMount)        [disk mount];
		else if (sender == _btnUnmount) [disk unmount];
		//[_disksView reloadData];
	}
}

- (IBAction)switchRights:(id)sender {
#pragma unused(sender)
	[_errorLabel setHidden:YES];
	[_errorLabel setStringValue:@""];
	NTFSDisk * disk = [_disks objectAtIndex:[_disksView selectedRow]];
  // Delete the line
	if (disk.isWrittingEnabled) {
		if (disk.uuid != nil) [_fstabParser removeLine:disk.uuid]; // Try remove UUID line
		[_fstabParser removeLine:disk.name];                       // Try remove LABEL line
	}
  // Add the line
	else {
		if (disk.uuid != nil) [_fstabParser addUUIDline:disk.uuid]; // Add UUID line
		[_fstabParser addLABELline:disk.name];                      // Also add LABEL line
		_tryEnableWriting = YES;
	}
	if (![_fstabParser saveWithAuthorization:[_authorizationView authorization]]) {
		NSBundle * b = [NSBundle bundleForClass:[self class]];
		[_errorLabel setStringValue:[b localizedStringForKey:@"AUTHENTIFICATION_FAILED"
                                                   value:@"Authentification failed"
                                                   table:nil]];
		[_errorLabel setHidden:NO];
		[_disksView setObjectValue:[NSNumber numberWithBool:disk.isWrittingEnabled]];
		[_fstabParser restoreBackup];
		return;
	}
	[disk unmount];
	[disk mount];
	[_disksView reloadData];
}

- (IBAction)daemonStatusChanged:(id)sender {
#pragma unused(sender)
	[_actionToPerform setEnabled:[_btnDaemon state]];
	CFPreferencesSetAppValue((CFStringRef)PREF_DAEMON_KEY,
                           ([_btnDaemon state]) ? kCFBooleanTrue : kCFBooleanFalse,
                           _bundleIdentifier);
	CFPreferencesAppSynchronize(_bundleIdentifier);
	NSString * str =
    [NSString stringWithFormat:@"%@/Library/Preferences/com.juicybinary.SLNTFS.plist", NSHomeDirectory()];
	char * cpArgs[3] = {
    (char *)[str cStringUsingEncoding:NSASCIIStringEncoding],
    "/Library/Preferences/slntfspref_copy.plist",
    NULL};
	AuthorizationExecuteWithPrivileges([[_authorizationView authorization] authorizationRef],
                                     [BIN_CP_PATH cStringUsingEncoding:NSASCIIStringEncoding],
                                     kAuthorizationFlagDefaults,
                                     cpArgs,
                                     NULL);
	[DaemonHandler launchDaemonsAtLogin:[_btnDaemon state]
                    withAuthorization:[_authorizationView authorization]];
	[_errorLabel setHidden:NO];
	[_errorLabel setStringValue:
    [[NSBundle bundleForClass:[self class]]
      localizedStringForKey:@"DAEMON_STATUS" value:@"Change will take effect after reboot." table:nil]];
}

- (IBAction)ActionToPerformChanged:(id)sender {
#pragma unused(sender)
	if (![_actionToPerform indexOfSelectedItem])
		CFPreferencesSetAppValue((CFStringRef)PREF_ATP_KEY, (CFStringRef)PREF_ATP_OPT_ASK, _bundleIdentifier);
	else
		CFPreferencesSetAppValue((CFStringRef)PREF_ATP_KEY, (CFStringRef)PREF_ATP_OPT_ENABLE, _bundleIdentifier);
	CFPreferencesAppSynchronize(_bundleIdentifier);
}

- (IBAction)reset_fstab:(id)sender {
#pragma unused(sender)
	[_fstabParser resetWithAuthorization:[_authorizationView authorization]];
	for (NTFSDisk * disk in _disks) {
		[disk unmount];
		[disk mount];
	}
}

- (IBAction)uninstall:(id)sender {
#pragma unused(sender)
	[DaemonHandler launchDaemonsAtLogin:NO withAuthorization:[_authorizationView authorization]];
	NSString * str =
    [NSString stringWithFormat:@"%@/Library/Preferences/com.juicybinary.SLNTFS.plist", NSHomeDirectory()];
	char * rmArgs[6] = {
    "-rf",
    (char *)[str cStringUsingEncoding:NSASCIIStringEncoding],
    "/Library/Application Support/SLNTFS",
    "/Library/PreferencePanes/SLNTFS.prefPane",
    "/Library/Preferences/slntfspref_copy.plist",
    NULL
  };
	AuthorizationExecuteWithPrivileges([[_authorizationView authorization] authorizationRef],
                                     [BIN_RM_PATH cStringUsingEncoding:NSASCIIStringEncoding],
                                     kAuthorizationFlagDefaults,
                                     rmArgs,
                                     NULL);
	[_uninstallLabel setStringValue:
    [[NSBundle bundleForClass:[self class]]
      localizedStringForKey:@"UNINSTALL_OK" value:@"Uninstall OK. Quit to complete." table:nil]];
	[_uninstallLabel setHidden:NO];
}

#pragma mark -
#pragma mark Notifications

- (void)diskDidMount:(NSNotification *)aNotification {
	NSString * name =
    [[aNotification userInfo] objectForKey:@"NSWorkspaceVolumeLocalizedNameKey"];
	BOOL exist = NO;
	for (NTFSDisk * disk in _disks) {
		if ([disk.name isEqualToString:name]) {
			[disk updateStatus];
			exist = YES;
			if (_tryEnableWriting && !disk.isWrittingEnabled) {
				[_errorLabel setHidden:NO];
				[_errorLabel setStringValue:
          [[NSBundle bundleForClass:[self class]]
            localizedStringForKey:@"ERR_ENABLE" value:@"Can't enable writing on this disk." table:nil]];
			}
			break;
		}
	}
	if (!exist) [self getDiskInformation:[NSString stringWithFormat:@"%@%@", VOLUMES_PATH, name]];
	_tryEnableWriting = NO;
	[_disks removeAllObjects];
	[self listDisks];
	[_disksView reloadData];
}

- (void)diskDidUnmount:(NSNotification *)aNotification {
	NSString * name =
    [[aNotification userInfo] objectForKey:@"NSWorkspaceVolumeLocalizedNameKey"];
	NSUInteger ui = 0;
	BOOL exist = NO;
	for (ui = 0 ; ui < [_disks count] ; ++ui) {
		NTFSDisk * disk = [_disks objectAtIndex:ui];
		if ([disk.name isEqualToString:name]) {
			[disk updateStatus];
			exist = YES;
			break;
		}
	}
	if (exist) [_disks removeObjectAtIndex:ui];
	[_disks removeAllObjects];
	[self listDisks];
	[_disksView reloadData];
}

#pragma mark -
#pragma mark Generals methods

- (void)listDisks {
	NSDirectoryEnumerator * enumerator =
    [[NSFileManager defaultManager] enumeratorAtPath:DEVICES_PATH];
	NSString * file = nil;
	while (file = [enumerator nextObject]) {
		if (([file rangeOfString:@"disk"].location != NSNotFound) && ([file length] == 7)) // 7 diskXsX
			[self getDiskInformation:[NSString stringWithFormat:@"%@%@", DEVICES_PATH, file]];
	}
}

- (void)getDiskInformation:(NSString *)diskName {
	NSArray  * args = [NSArray arrayWithObjects:@"info", diskName, nil];
	NSData   * data = [Tools executeCommand:BIN_DISKUTIL_PATH withArguments:args];
	NSString * info = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
  
	if ([info rangeOfString:@"NTFS"].location != NSNotFound) { // NTFS disk
		NTFSDisk * disk = [[NTFSDisk alloc] initWithDiskutilInfo:info];
		[_disks addObject:disk];
		NSLog(@"disk name = %@", disk.name);
	}
}

- (void)setInstalledVersionString {
	NSDictionary * infoDict = [[NSBundle bundleForClass:[self class]] infoDictionary];
	[_versionLabel setStringValue:
   [NSString stringWithFormat:@"Version %@", [infoDict objectForKey:@"CFBundleVersion"]]];
}

- (void)enableControls:(BOOL)state {
	[_btnDaemon setEnabled:state];
	[_btnReset setEnabled:state];
	[_actionToPerform setEnabled:((state) ? (([_btnDaemon state]) ? YES : NO) : NO)];
}

- (void)setTooltips {
	NSBundle * b = [NSBundle bundleForClass:[self class]];
	[_btnMount setToolTip:[b localizedStringForKey:@"BTN_MOUNT_TT" value:@"Mount the selected disk" table:nil]];
	[_btnUnmount setToolTip:[b localizedStringForKey:@"BTN_UNMOUNT_TT" value:@"Unmount the selected disk" table:nil]];
	[_btnDaemon setToolTip:[b localizedStringForKey:@"BTN_DAEMON_TT" value:@"Enable a daemon which check in real time if NTFS disks are plugged" table:nil]];
	[_btnReset setToolTip:[b localizedStringForKey:@"BTN_RESET_TT" value:@"Restore default settings, NTFS writting disabled on all disk" table:nil]];
	[_btnCheckForUpdates setToolTip:[b localizedStringForKey:@"BTN_CHKUPD_TT" value:@"Check if a newer version of SL-NTFS is available" table:nil]];
	[_actionToPerform setToolTip:[b localizedStringForKey:@"BTN_ACTTOPERF_TT" value:@"Action to perform when a NTFS disk is plugged" table:nil]];
	[_btnUninstall setToolTip:[b localizedStringForKey:@"BTN_UNINSTALL_TT" value:@"Uninstall SL-NTFS" table:nil]];
}

@end

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>
@class FileSystemTableParser;
@class NTFSDisk;

@interface SLNTFSPref : NSPreferencePane <NSTableViewDelegate>
{
	/// Disks list view
	IBOutlet NSTableView* _disksView;
	/// Column for the disk name
	IBOutlet NSTableColumn* _tcDiskNameColumn;
	/// Column for the write state
	IBOutlet NSTableColumn* _tcStateColumn;
	/// Column for image disk
	IBOutlet NSTableColumn* _tcImageColumn;
	/// About content
	IBOutlet NSTextView* _aboutView;
	/// Version string
	IBOutlet NSTextField* _versionLabel;
	/// Authorization view
	IBOutlet SFAuthorizationView* _authorizationView;
	/// Progress label
	IBOutlet NSTextField* _errorLabel;
	/// Uninstall label
	IBOutlet NSTextField* _uninstallLabel;
	/// Mount disk button
	IBOutlet NSButton* _btnMount;
	/// Unmount button
	IBOutlet NSButton* _btnUnmount;
	/// Check for updates button
	IBOutlet NSButton* _btnCheckForUpdates;
	/// Enable daemon checkbox
	IBOutlet NSButton* _btnDaemon;
	/// Reset button
	IBOutlet NSButton* _btnReset;
	/// Uninstall button
	IBOutlet NSButton* _btnUninstall;
	/// daemon action
	IBOutlet NSPopUpButton* _actionToPerform;
	/// List of NTFS disks
	NSMutableArray* _disks;
	/// fstab file parser
	FileSystemTableParser* _fstabParser;
	/// Flag to indicate if events must be ignored or not
	BOOL _tryEnableWriting;
	/// Bundle identifier (com.juicybinary...)
	CFStringRef _bundleIdentifier;
}
#pragma mark -
#pragma mark Constructors / Destructors
+(void)initialize;
-(id)initWithBundle:(NSBundle*)bundle;
-(void)mainViewDidLoad;
-(void)didUnselect;

#pragma mark -
#pragma mark TableView delegates
-(NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView;
-(id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)row;
-(void)tableView:(NSTableView*)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)row;

#pragma mark -
#pragma mark SFAuthorizationView delegates
-(void)authorizationViewCreatedAuthorization:(SFAuthorizationView*)view;
-(void)authorizationViewDidAuthorize:(SFAuthorizationView*)view;
-(void)authorizationViewDidDeauthorize:(SFAuthorizationView*)view;

#pragma mark -
#pragma mark IBActions
-(IBAction)launchWebSite:(id)sender;
-(IBAction)checkForUpdates:(id)sender;
-(IBAction)performMountingAction:(id)sender;
-(IBAction)switchRights:(id)sender;
-(IBAction)daemonStatusChanged:(id)sender;
-(IBAction)ActionToPerformChanged:(id)sender;
-(IBAction)reset_fstab:(id)sender;
-(IBAction)uninstall:(id)sender;

#pragma mark -
#pragma mark Notifications
-(void)diskDidMount:(NSNotification*)aNotification;
-(void)diskDidUnmount:(NSNotification*)aNotification;

#pragma mark -
#pragma mark Generals methods
-(void)listDisks;
-(void)getDiskInformation:(NSString*)diskName;
-(void)setInstalledVersionString;
-(void)enableControls:(BOOL)enable;
-(void)setTooltips;

@end

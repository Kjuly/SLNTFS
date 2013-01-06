#import <Foundation/Foundation.h>
#import <SecurityFoundation/SFAuthorization.h>

#define HELPER_BUNDLE_ID @"com.juicybinary.SLNTFS_Helper"
#define LAUNCHCTL_PLIST_PATH "/Library/LaunchDaemons/com.juicybinary.slntfsDaemon.plist"

@interface DaemonHandler : NSObject
{
}
+(BOOL)helperIsLaunchedAtLogin:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString*)path;
+(BOOL)daemonIsLaunchedAtLogin;

+(BOOL)helperIsLaunched;
+(BOOL)daemonIsLaunched;

+(BOOL)launchHelper:(NSString*)path;
+(BOOL)launchDaemon:(SFAuthorization*)auth;

+(void)terminateHelper;
+(BOOL)terminateDaemon:(SFAuthorization*)auth;

+(void)enableHelperAtLoginWithItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString*)path;
+(void)enableDaemonAtLoginWithAuthorization:(SFAuthorization*)auth;

+(void)disableHelperAtLoginWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString*)path;
+(void)disableDaemonAtLoginWithAuthorization:(SFAuthorization*)auth;

+(void)launchDaemonsAtLogin:(BOOL)state withAuthorization:(SFAuthorization*)auth;

@end

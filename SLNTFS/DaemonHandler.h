#import <Foundation/Foundation.h>
#import <SecurityFoundation/SFAuthorization.h>

#define LAUNCHCTL_PLIST_PATH "/Library/LaunchDaemons/com.juicybinary.slntfsDaemon.plist"

@interface DaemonHandler : NSObject
{
}
+(BOOL)daemonIsLaunchedAtLogin;

+(BOOL)daemonIsLaunched;

+(BOOL)launchDaemon:(SFAuthorization*)auth;

+(BOOL)terminateDaemon:(SFAuthorization*)auth;

+(void)enableDaemonAtLoginWithAuthorization:(SFAuthorization*)auth;

+(void)disableDaemonAtLoginWithAuthorization:(SFAuthorization*)auth;

+(void)launchDaemonsAtLogin:(BOOL)state withAuthorization:(SFAuthorization*)auth;

@end

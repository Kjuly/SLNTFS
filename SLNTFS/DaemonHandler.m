
#import "DaemonHandler.h"
#import "ProcessHelper.h"
#import "Constants.h"
#import "Tools.h"

@implementation DaemonHandler

+ (BOOL)daemonIsLaunchedAtLogin {
	NSFileManager * fileManager = [NSFileManager defaultManager];
	return ([fileManager fileExistsAtPath:[NSString stringWithCString:LAUNCHCTL_PLIST_PATH
                                                           encoding:NSASCIIStringEncoding]]);
}

+ (BOOL)daemonIsLaunched {
	ProcessHelper * procInfo = [[ProcessHelper alloc] init];
	[procInfo obtainFreshProcessList]; // Get a list of process
	BOOL daemonLaunched = [procInfo findProcessWithName:@"SLNTFS Daemon"];
	[procInfo release];
	return daemonLaunched;
}

+ (BOOL)launchDaemon:(SFAuthorization *)auth {
	char * loadArgs[3] = {"load", LAUNCHCTL_PLIST_PATH, NULL}; // Launch daemon
	OSStatus ret = AuthorizationExecuteWithPrivileges([auth authorizationRef],
                                                    [BIN_LAUNCHCTL_PATH cStringUsingEncoding:NSASCIIStringEncoding],
                                                    kAuthorizationFlagDefaults,
                                                    loadArgs,
                                                    NULL);
	return (ret == errAuthorizationSuccess);
}

+ (BOOL)terminateDaemon:(SFAuthorization *)auth {
	char * unloadArgs[3] = {"unload", LAUNCHCTL_PLIST_PATH, NULL}; // Stop daemon
	OSStatus ret = AuthorizationExecuteWithPrivileges([auth authorizationRef],
                                                    [BIN_LAUNCHCTL_PATH cStringUsingEncoding:NSASCIIStringEncoding],
                                                    kAuthorizationFlagDefaults,
                                                    unloadArgs,
                                                    NULL);
	return (ret == errAuthorizationSuccess);
}

+ (void)enableDaemonAtLoginWithAuthorization:(SFAuthorization *)auth {
	char * cpArgs[4] = {
    "-f",
    "/Library/PreferencePanes/SLNTFS.prefPane/Contents/Resources/com.juicybinary.slntfsDaemon.plist",
    "/Library/LaunchDaemons/com.juicybinary.slntfsDaemon.plist",
    NULL
  };
	OSStatus ret = AuthorizationExecuteWithPrivileges([auth authorizationRef],
                                                    [BIN_CP_PATH cStringUsingEncoding:NSASCIIStringEncoding],
                                                    kAuthorizationFlagDefaults,
                                                    cpArgs,
                                                    NULL);
	ALog(@"%d", ret);
}

+ (void)disableDaemonAtLoginWithAuthorization:(SFAuthorization *)auth {
	char * rmArgs[3] = {"-rf", LAUNCHCTL_PLIST_PATH, NULL};
	AuthorizationExecuteWithPrivileges([auth authorizationRef],
                                     [BIN_RM_PATH cStringUsingEncoding:NSASCIIStringEncoding],
                                     kAuthorizationFlagDefaults,
                                     rmArgs,
                                     NULL);
}

+ (void)launchDaemonsAtLogin:(BOOL)state
           withAuthorization:(SFAuthorization *)auth {
	if (state) [DaemonHandler enableDaemonAtLoginWithAuthorization:auth];
	else       [DaemonHandler disableDaemonAtLoginWithAuthorization:auth];
}

@end

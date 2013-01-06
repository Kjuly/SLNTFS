/* Preferences keys */
#define PREF_DAEMON_KEY @"DaemonEnabled"
#define PREF_ATP_KEY @"ActionToPerform"
#define PREF_ATP_OPT_ENABLE @"AutomaticallyEnable"
#define PREF_ATP_OPT_ASK @"Always Ask"

/* binaries path */
#define BIN_CP_PATH @"/bin/cp"
#define BIN_RM_PATH @"/bin/rm"
#define BIN_OPEN_PATH @"/usr/bin/open"
#define BIN_CHOWN_PATH @"/usr/sbin/chown"
#define BIN_MKDIR_PATH @"/bin/mkdir"
#define BIN_DISKUTIL_PATH @"/usr/sbin/diskutil"
#define BIN_LAUNCHCTL_PATH @"/bin/launchctl"

/* Exceptions */
#define EX_WRONG_INIT @"Wrong initializer"

/* others */
#define VOLUMES_PATH @"/Volumes/"
#define DEVICES_PATH @"/dev/"
#define SLNTFS_BUNDLE_ID @"com.juicybinary.SLNTFS"
#define WEBSITE @"http://www.whine.fr/SLNTFS/"
#define REGISTERED_VOLUMES_PATH @"/Library/Application Support/SLNTFS/.volumes"

#define NICE_RELEASE(__POINTER) { [__POINTER release]; __POINTER = nil; }

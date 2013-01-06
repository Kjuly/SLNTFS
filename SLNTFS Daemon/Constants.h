/* Preferences keys */
#define PREF_DAEMON @"DaemonEnabled"
#define PREF_ATP @"ActionToPerform"
#define PREF_ATP_OPTION_ENABLE @"AutomaticallyEnable"
#define PREF_ATP_OPTION_ASK @"Always Ask"

/* binaries path */
#define BIN_CP_PATH @"/bin/cp"
#define BIN_OPEN_PATH @"/usr/bin/open"
#define BIN_DISKUTIL_PATH @"/usr/sbin/diskutil"

/* Exceptions */
#define EX_WRONG_INIT @"Wrong initializer"

/* others */
#define VOLUMES_PATH @"/Volumes/"
#define DEVICES_PATH @"/dev/"
#define SLNTFS_BUNDLE_ID @"com.juicybinary.SLNTFS"
#define SLNTFS_PATH @"/Library/PreferencePanes/SLNTFS.prefPane"

#define NICE_RELEASE(__POINTER) { [__POINTER release]; __POINTER = nil; }

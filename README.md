SL-NTFS
=======

# Description

SL-NTFS is a preference Pane that allow you to enable writing on NTFS disks via the Apple driver. A daemon is also available, it warns you when a NTFS disk is mounted and if writing is not enabled it asks you if you want to enable it, or can enable it automatically.

# Requirement

Intel, Mac OS X 10.6 or later

# Project Setup

1. Edit Scheme;  
2. Set the __"Executable"__ to __"System Preferences.app"__;  
3. In __"Arguments"__ tab, add `$USER_LIBRARY_DIR/PreferencePanes/$FULL_PRODUCT_NAME` on __"Arguments Passed On Launch"__;  
4. Set `SLNTFS` as the __"Expand Variables Based On"__'s value;  
5. Expand the Run/Debug scheme (click the little triangle button on the left), click on __"Pre-actions"__;  
6. Add __"New Run Script Action"__:  

        cp -a "$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME" "$USER_LIBRARY_DIR/PreferencePanes/"

7. Okay, build & run.

# Change Log

__v2.1.x @ Dev__

  - ...

__v2.0.5 @ 2013-01-06__

  - Reactivate the project by Kjuly.

__v2.0.4 @ 2010-05-16__

  - Add : Italian localization;
  - Add : Spanish localization.

# Feedback

Please email your comments, suggestions and questions to `dev#kjuly.com`.  
Or you can just post a bug report or a feature request [__HERE__](https://github.com/Kjuly/SLNTFS/issues/new).

Thank you! :)



#import <Foundation/Foundation.h>

#define FSTAB_NAME @"fstab"
#define FSTAB_PATH @"/etc/fstab"
#define BACKUP_NAME @".fstabackup"

@interface FileSystemTableParser : NSObject {
	/// Lines of the fstab file
	NSMutableArray * _lines;
	/// fstab copy path
	NSString * _copyPath;
	/// Backup path
	NSString * _backupPath;
	/// Default file manager
	NSFileManager * _fileManager;
}

#pragma mark -
#pragma mark Constructors / Destructors

- (id)init;
- (id)initWithCopyPath:(NSString *)copyPath;
- (void)dealloc;

#pragma mark -
#pragma mark General methods

- (void)restoreBackup;
- (void)fstabRead;
- (BOOL)save;
- (void)addUUIDline:(NSString *)uuid;
- (void)addLABELline:(NSString *)label;
- (BOOL)isWrittingEnabledOn:(NSString *)nameOrUUID;

@end

#pragma mark -
#pragma mark Private methods

@interface FileSystemTableParser (PrivateMethods)

- (void)copyForReading;
- (void)removeCopy;
- (void)addLine:(NSString *)line;

@end

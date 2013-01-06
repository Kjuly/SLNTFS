
#import <Foundation/Foundation.h>
#import <SecurityFoundation/SFAuthorization.h>

#define FSTAB_NAME @"fstab"
#define FSTAB_PATH @"/etc/fstab"
#define BACKUP_NAME @".fstabackup"

@interface FileSystemTableParser : NSObject {
	/// Lines of the fstab file
	NSMutableArray * _lines;
	/// fstab copy path
	NSString * _copyPath;
	/// fstab backup path
	NSString * _backupPath;
	///
	NSFileManager * _fileManager;
}

#pragma mark -
#pragma mark Constructors / Destructors

- (id)init;
- (id)initWithCopyPath:(NSString *)path;
- (void)dealloc;

#pragma mark -
#pragma mark General methods

- (void)restoreBackup;
- (void)fstabRead;
- (BOOL)saveWithAuthorization:(SFAuthorization *)auth;
- (BOOL)isWrittingEnabledOn:(NSString *)nameOrUUID;
- (BOOL)removeLine:(NSString *)nameOrUUID;
- (void)addUUIDline:(NSString *)uuid;
- (void)addLABELline:(NSString *)label;
- (void)resetWithAuthorization:(SFAuthorization *)auth;

@end

#pragma mark -
#pragma mark Private methods

@interface FileSystemTableParser (PrivateMethods)

- (void)copyForReading;
- (void)removeCopy;
- (void)addLine:(NSString *)line;

@end


#import "FileSystemTableParser.h"
#import "Tools.h"
#import "Constants.h"

@implementation FileSystemTableParser

#pragma mark -
#pragma mark Constructors / Destructors

- (id)init {
	@throw([NSException exceptionWithName:EX_WRONG_INIT
                                 reason:@"Use -(id)initWithCopyPath:(NSString*)path instead"
                               userInfo:nil]);
}

- (id)initWithCopyPath:(NSString *)copyPath {
	if (self = [super init]) {
		if ([copyPath characterAtIndex:[copyPath length] - 1] != '/') {
			_copyPath   = [[NSString alloc] initWithFormat:@"%@/%@", copyPath, FSTAB_NAME];
			_backupPath = [[NSString alloc] initWithFormat:@"%@/%@", copyPath, BACKUP_NAME];
		}
		else {
			_copyPath   = [[NSString alloc] initWithFormat:@"%@%@", copyPath, FSTAB_NAME];
			_backupPath = [[NSString alloc] initWithFormat:@"%@%@", copyPath, BACKUP_NAME];
		}
		_fileManager = [NSFileManager defaultManager];
		_lines       = [[NSMutableArray alloc] init];
		[self copyForReading];
	}
	return self;
}

- (void)dealloc {
	[self removeCopy];
	[_copyPath release];
	[_backupPath release];
	[_lines release];
	[super dealloc];
}

#pragma mark -
#pragma mark General methods

- (void)fstabRead {
	[_lines removeAllObjects];
	NSArray * lines =
    [[NSString stringWithContentsOfFile:_copyPath encoding:NSASCIIStringEncoding error:NULL]
      componentsSeparatedByString:@"\n"];
	for (NSString * line in lines)
		if ([line length] > 0)
			[_lines addObject:line];
}

- (void)restoreBackup {
	[_fileManager removeItemAtPath:_copyPath error:NULL];
	[_fileManager copyItemAtPath:_backupPath toPath:_copyPath error:NULL];
	[self fstabRead];
}

- (BOOL)save {
	NSMutableString * lines = [NSMutableString string];
	for (NSString * line in _lines)
		[lines appendFormat:@"%@\n", line];
	NSError * err = nil;
	if (![lines writeToFile:_copyPath atomically:YES encoding:NSASCIIStringEncoding error:&err]) {
		NSLog(@"%@", err);
		return NO;
	}
	[_fileManager removeItemAtPath:FSTAB_PATH error:NULL];
	BOOL ret = [_fileManager copyItemAtPath:_copyPath toPath:FSTAB_PATH error:&err];
	return ret;
}

- (BOOL)isWrittingEnabledOn:(NSString *)nameOrUUID {
	if (!nameOrUUID)
		return NO;
	for (NSString * line in _lines)
		if ([line characterAtIndex:0] != '#' && [line rangeOfString:@"rw"].location != NSNotFound)
			if ([line rangeOfString:nameOrUUID].location != NSNotFound)
				return YES;
	return NO;
}

- (void)addUUIDline:(NSString *)uuid {
	[self addLine:[NSString stringWithFormat:@"UUID=%@ none ntfs rw", uuid]];
}

- (void)addLABELline:(NSString *)label {
	[self addLine:[NSString stringWithFormat:@"LABEL=%@ none ntfs rw", label]];
}

@end

#pragma mark -
#pragma mark Private methods

@implementation FileSystemTableParser (PrivateMethods)

- (void)copyForReading {
	[_fileManager removeItemAtPath:_copyPath error:NULL]; // Remove olders copies
	if (![_fileManager copyItemAtPath:FSTAB_PATH toPath:_copyPath error:NULL]) // Copy file if exists
		[_fileManager createFileAtPath:_copyPath contents:nil attributes:nil]; // File doesn't exists, so create it
}

- (void)removeCopy {
	[_fileManager removeItemAtPath:_copyPath error:NULL];
}

- (void)addLine:(NSString *)line {
	[_lines addObject:line];
}

@end

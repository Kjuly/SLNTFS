
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
}

#pragma mark -
#pragma mark General methods

- (void)restoreBackup {
	[_fileManager removeItemAtPath:_copyPath error:nil];
	[_fileManager copyItemAtPath:_backupPath toPath:_copyPath error:nil];
	[self fstabRead];
}

- (void)fstabRead {
	[_lines removeAllObjects];
	NSArray * lines =
    [[NSString stringWithContentsOfFile:_copyPath encoding:NSASCIIStringEncoding error:NULL]
     componentsSeparatedByString:@"\n"];
	for (NSString * line in lines)
		if ([line length] > 0) [_lines addObject:line];
}

- (BOOL)saveWithAuthorization:(SFAuthorization *)auth {
	NSString * lines = [Tools arrayToString:_lines withDelimiter:@"\n"];
	if (![lines writeToFile:_copyPath atomically:YES
                 encoding:NSASCIIStringEncoding
                    error:NULL])
  {
		NSLog(@"Failed to write to %@\n", _copyPath);
		return NO;
	}
	char * args[3] = {
    (char *)[_copyPath cStringUsingEncoding:NSASCIIStringEncoding],
    (char*)[FSTAB_PATH cStringUsingEncoding:NSASCIIStringEncoding],
    NULL
  };
	if (AuthorizationExecuteWithPrivileges([auth authorizationRef],
                                         [BIN_CP_PATH cStringUsingEncoding:NSASCIIStringEncoding],
                                         kAuthorizationFlagDefaults, args, NULL) != errAuthorizationSuccess)
	{
		ALog(@"Failed to execute '%@ %@ %@'\n", BIN_CP_PATH, _copyPath, FSTAB_PATH);
		return NO;
	}
	return YES;
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

- (BOOL)removeLine:(NSString *)nameOrUUID {
	if (!nameOrUUID)
		return NO;
	NSUInteger size = [_lines count];
	for (NSUInteger ui = 0 ; ui < size ; ++ui) {
		NSString * line = [_lines objectAtIndex:ui];
		if ([line rangeOfString:nameOrUUID].location != NSNotFound) {
			[_lines removeObjectAtIndex:ui];
			return YES;
		}
	}
	return NO;
}

- (void)addUUIDline:(NSString *)uuid {
	[self addLine:[NSString stringWithFormat:@"UUID=%@ none ntfs rw", uuid]];
}

- (void)addLABELline:(NSString *)label {
	[self addLine:[NSString stringWithFormat:@"LABEL=%@ none ntfs rw", label]];
}

- (void)resetWithAuthorization:(SFAuthorization *)auth {
	char * args[5] = {
    "-f",
    (char *)[FSTAB_PATH  cStringUsingEncoding:NSASCIIStringEncoding],
    (char *)[_copyPath   cStringUsingEncoding:NSASCIIStringEncoding],
    (char *)[_backupPath cStringUsingEncoding:NSASCIIStringEncoding],
    NULL
  };
  
	AuthorizationExecuteWithPrivileges([auth authorizationRef],
                                     [BIN_RM_PATH cStringUsingEncoding:NSASCIIStringEncoding],
                                     kAuthorizationFlagDefaults,
                                     args,
                                     NULL);
	[self copyForReading];
}

@end

#pragma mark -
#pragma mark Private methods

@implementation FileSystemTableParser (PrivateMethods)

- (void)copyForReading {
	[_fileManager removeItemAtPath:_copyPath error:NULL]; // Remove olders copies
	[_fileManager removeItemAtPath:_backupPath error:NULL];
	if (![_fileManager copyItemAtPath:FSTAB_PATH toPath:_copyPath error:NULL]) // Copy file if exists
		[_fileManager createFileAtPath:_copyPath contents:nil attributes:nil]; // File doesn't exists, so create it
	[_fileManager copyItemAtPath:_copyPath toPath:_backupPath error:NULL]; // Create backup file
}

- (void)removeCopy {
	[_fileManager removeItemAtPath:_copyPath error:NULL];
	[_fileManager removeItemAtPath:_backupPath error:NULL];
}

- (void)addLine:(NSString *)line {
	[_lines addObject:line];
}

@end

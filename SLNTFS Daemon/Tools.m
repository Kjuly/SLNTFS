
#import "Tools.h"
#import "Constants.h"

@implementation Tools

+ (NSString *)getBundleIdentifierForClass:(Class)c {
	return [[NSBundle bundleForClass:c] bundleIdentifier];
}

+ (NSData *)executeCommand:(NSString *)command
             withArguments:(NSArray *)args {
	NSTask * task = [[NSTask alloc] init];
	[task setLaunchPath:command];
	[task setArguments:args];
	
	NSPipe * pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	
	NSFileHandle * file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData * data = [file readDataToEndOfFile];
	
	[task release];
	return data;
}

+ (BOOL)prefPaneExists {
	NSFileManager * fileManager = [NSFileManager defaultManager];
	return ([fileManager fileExistsAtPath:SLNTFS_PATH]);
}

+ (NSDictionary *)preferencesForBundleId:(NSString *)bundleId {
	return [NSDictionary dictionaryWithContentsOfFile:
           [NSString stringWithFormat:@"%@/Library/Preferences/%@", NSHomeDirectory(), bundleId]];
}

@end


#import "Tools.h"
#import <Foundation/Foundation.h>

@implementation Tools

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

+ (NSString *)getBundleIdentifierForClass:(Class)c {
	return [[NSBundle bundleForClass:c] bundleIdentifier];
}

+ (NSString *)arrayToString:(NSArray *)array
              withDelimiter:(NSString *)delim {
	NSMutableString * lines = [NSMutableString string];
	for (NSString * str in array)
		[lines appendFormat:@"%@%@", str, delim];
	return lines;
}

@end

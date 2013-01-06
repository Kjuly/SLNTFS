
#import <Foundation/Foundation.h>

@interface Tools : NSObject

+ (NSString *)getBundleIdentifierForClass:(Class)c;
+ (NSData *)executeCommand:(NSString *)command withArguments:(NSArray *)args;
+ (BOOL)prefPaneExists;
+ (NSDictionary *)preferencesForBundleId:(NSString *)bundleId;

@end

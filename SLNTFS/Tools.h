
@interface Tools : NSObject

+ (NSData *)executeCommand:(NSString *)command withArguments:(NSArray *)args;
+ (NSString *)getBundleIdentifierForClass:(Class)c;
+ (NSString *)arrayToString:(NSArray *)array withDelimiter:(NSString *)delim;

@end

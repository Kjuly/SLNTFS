
#import <Cocoa/Cocoa.h>

@interface ProcessHelper : NSObject {
@private
  NSInteger        _processCount;
  NSMutableArray * _processList;
}

@property (nonatomic, readwrite) NSInteger processCount;

- (id)init;
- (void)obtainFreshProcessList;
- (BOOL)findProcessWithName:(NSString *)procNameToSearch;

@end

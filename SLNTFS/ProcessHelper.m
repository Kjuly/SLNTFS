
#import "ProcessHelper.h"

#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <sys/sysctl.h>

typedef struct kinfo_proc kinfo_proc;

@implementation ProcessHelper

@synthesize ProcessCount = _processCount;

- (id)init {
	if (self = [super init]) {
		_processCount = -1;
		_processList  = nil;
	}
	return self;
}

- (void)dealloc {
	[_processList release];
	[super dealloc];
}

- (NSInteger)getBSDProcessList:(kinfo_proc **)procList
         withNumberOfProcesses:(size_t *)procCount {
	NSInteger err;
	kinfo_proc * result = NULL;
	bool done = false;
	static const int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
	size_t length;
	// a valid pointer procList holder should be passed
	assert(procList != NULL);
	// But it should not be pre-allocated
	assert(*procList == NULL);
	// a valid pointer to procCount should be passed
	assert(procCount != NULL);
	* procCount = 0;
  
	do {
		assert(result == NULL);
		// Call sysctl with a NULL buffer to get proper length
		length = 0;
		err = sysctl((int *)name, (sizeof(name) / sizeof(* name)) - 1, NULL, &length, NULL, 0);
		if (err == -1)
			err = errno;
		// Now, proper length is optained
		if (err == 0) {
			if (NULL == (result = malloc(length)))
				err = ENOMEM; // not allocated
		}
		if (err == 0) {
			err = sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, result, &length, NULL, 0);
			if (err == -1)
				err = errno;
			if (err == 0)
				done = true;
			else if (err == ENOMEM) {
				assert(result != NULL);
				free(result);
				result = NULL;
				err = 0;
			}
		}
	} while (err == 0 && !done);
  // Clean up and establish post condition
	if (err != 0 && result != NULL) {
		free(result);
		result = NULL;
	}
	* procList = result; // will return the result as procList
	if (err == 0)
		* procCount = length / sizeof(kinfo_proc);
	assert((err == 0) == (* procList != NULL));
	return err;
}

- (void)obtainFreshProcessList {
	kinfo_proc * allProcs = 0;
	size_t numProcs;
	NSString * procName = nil;
	NSInteger err = [self getBSDProcessList:&allProcs withNumberOfProcesses:&numProcs];
	if (err) {
		_processCount = -1;
		_processList = nil;
		return;
	}
	// Construct an array for ( process name )
	_processList = [NSMutableArray arrayWithCapacity:numProcs];
	for (NSInteger i = 0 ; i < (NSInteger)numProcs; ++i) {
		procName = [NSString stringWithCString:allProcs[i].kp_proc.p_comm
                                  encoding:NSASCIIStringEncoding];
		[_processList addObject:procName];
	}
	_processCount = (NSInteger)numProcs;
	free(allProcs);
}

- (BOOL)findProcessWithName:(NSString *)procNameToSearch {
	return ([_processList indexOfObject:procNameToSearch] != NSNotFound);
}

@end

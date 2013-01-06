
#import "NTFSDisk.h"
#import "Tools.h"
#import "Constants.h"
#import <ctype.h>

@implementation NTFSDisk

@synthesize Name = _name;
@synthesize UUID = _uuid;
@synthesize DeviceIdentifier = _deviceIdentifier;
@synthesize DeviceNode = _deviceNode;
@synthesize Device = _device;
@synthesize MountPoint = _mountPoint;
@synthesize Protocol = _protocol;
@synthesize Internal = _internal;
@synthesize Ejectable = _ejectable;
@synthesize Mounted = _mounted;
@synthesize WrittingEnabled = _writtingEnabled;

#pragma mark -
#pragma mark Constructors / Destructors

- (id)init {
	@throw([NSException exceptionWithName:EX_WRONG_INIT
                                 reason:@"Use -(id)initWithDiskutilInfo:(NSString*)info instead"
                               userInfo:nil]);
}

- (id)initWithDiskutilInfo:(NSString *)info {
	if (self = [super init]) {
		[self parseInfo:info];
		_session = DASessionCreate(kCFAllocatorDefault);
		_disk = DADiskCreateFromBSDName(kCFAllocatorDefault,
                                    _session,
                                    [_deviceNode cStringUsingEncoding:NSASCIIStringEncoding]);
	}
	return self;
}

- (void)dealloc {
	[_uuid release];
	[_name release];
	[_device release];
	[_deviceIdentifier release];
	[_deviceNode release];
	[_mountPoint release];
	CFRelease(_session);
	CFRelease(_disk);
	[super dealloc];
}

- (void)clearVars {
	NICE_RELEASE(_name);
	NICE_RELEASE(_uuid);
	NICE_RELEASE(_device);
	NICE_RELEASE(_deviceIdentifier);
	NICE_RELEASE(_deviceNode);
	NICE_RELEASE(_mountPoint);
	_protocol = P_SATA;
	_internal = YES;
	_ejectable = NO;
	_writtingEnabled = NO;
}

#pragma mark -
#pragma mark General Methods

- (void)parseInfo:(NSString *)info {
	[self clearVars];
	NSRange r = [info rangeOfString:@"Device Identifier:"];
	if (NSNotFound != r.location) {
		_deviceIdentifier = [[NSString alloc] initWithString:[self extractInfoFrom:info AtRange:r]];
	}
	r = [info rangeOfString:@"Device Node:"];
	if (NSNotFound != r.location) {
		_deviceNode = [[NSString alloc] initWithString:[self extractInfoFrom:info AtRange:r]];
	}
	r = [info rangeOfString:@"Part Of Whole:"];
	if (NSNotFound != r.location) {
		_device = [[NSString alloc] initWithString:[self extractInfoFrom:info AtRange:r]];
	}
	r = [info rangeOfString:@"Volume Name:"];
	if (NSNotFound != r.location) {
		_name = [[NSString alloc] initWithString:[self extractInfoFrom:info AtRange:r]];
	}
	r = [info rangeOfString:@"Mount Point:"];
	if (NSNotFound != r.location) {
		_mountPoint = [[NSString alloc] initWithString:[self extractInfoFrom:info AtRange:r]];
	}
	r = [info rangeOfString:@"Mounted:"];
	if (NSNotFound != r.location) {
		_mounted = [self extractBooleanFrom:info AtRange:r];
	}
	r = [info rangeOfString:@"Read-Only Volume:"];
	if (NSNotFound != r.location) {
		if ([info rangeOfString:@"Not applicable (not mounted)"].location != NSNotFound)
			_writtingEnabled = NSMixedState;
		else
			_writtingEnabled = [self extractBooleanFrom:info AtRange:r] ? NSOffState : NSOnState;
	}
	r = [info rangeOfString:@"Volume UUID:"];
	if (NSNotFound != r.location) {
		_uuid = [[NSString alloc] initWithString:[self extractInfoFrom:info AtRange:r]];
	}
	r = [info rangeOfString:@"Protocol:"];
	if (NSNotFound != r.location) {
		_protocol = [self extractIntegerFrom:info AtRange:r];
	}
	r = [info rangeOfString:@"Ejectable:"];
	if (NSNotFound != r.location) {
		_ejectable = [self extractBooleanFrom:info AtRange:r];
	}
	r = [info rangeOfString:@"Internal:"];
	if (NSNotFound != r.location) {
		_internal = [self extractBooleanFrom:info AtRange:r];
	}
}

- (NSString *)extractInfoFrom:(NSString *)info AtRange:(NSRange)range {
	NSUInteger index = range.location + range.length + 1;
	char buffer[128] = {0x00};
	NSUInteger ui = 0;
	char c = 0x00;
	while ((c = [info characterAtIndex:index]) != '\n') {
		if (ispunct(c) || isalnum(c) || isspace(c))
			buffer[ui++] = c;
		index++;
	}
	return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
}

- (BOOL)extractBooleanFrom:(NSString *)info AtRange:(NSRange)range {
	NSUInteger index = range.location + range.length + 1;
	char buffer[128] = {0x00};
	NSUInteger ui = 0;
	char c = 0x00;
	while ((c = [info characterAtIndex:index]) != '\n') {
		if (ispunct(c) || isalnum(c))
			buffer[ui++] = c;
		index++;
	}
	return (!strcmp(buffer, "Yes"));
}

- (NSInteger)extractIntegerFrom:(NSString *)str AtRange:(NSRange)range {
	NSUInteger index = range.location + range.length + 1;
	char buffer[128] = {0x00};
	NSUInteger ui = 0;
	char c = 0x00;
	while ((c = [str characterAtIndex:index]) != '\n') {
		if (ispunct(c) || isalnum(c))
			buffer[ui++] = c;
		index++;
	}
  
	if      (!strcmp(buffer, "SATA"))     return P_SATA;
	else if (!strcmp(buffer, "ATA"))      return P_ATA;
	else if (!strcmp(buffer, "USB"))      return P_USB;
	else if (!strcmp(buffer, "FIREWIRE")) return P_FIREWIRE;
	else                                  return -1;
}

- (void)mount {
	DADiskMount(_disk, NULL, kDADiskMountOptionDefault, NULL, NULL);
}

- (void)unmount {
	DADiskUnmount(_disk, kDADiskUnmountOptionDefault, NULL, NULL);
}

- (void)updateStatus {
	NSData * data = [Tools executeCommand:BIN_DISKUTIL_PATH
                          withArguments:[NSArray arrayWithObjects:@"info", _deviceNode, nil]];
	NSString * info = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	[self parseInfo:info];
	[info release];
}

@end

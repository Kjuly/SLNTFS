
#import <Foundation/Foundation.h>
#import <DiskArbitration/DiskArbitration.h>

typedef enum {P_ATA, P_SATA, P_USB, P_FIREWIRE, P_ESATA, P_UNKNOW} VolProtocol;

@interface NTFSDisk : NSObject {
	/// Volume name
	NSString * _name;
	/// Disk UUID
	NSString * _uuid;
	/// Device Identifier (diskXsX)
	NSString * _deviceIdentifier;
	/// Device Node (/dev/diskXsX)
	NSString * _deviceNode;
	/// Device (diskX)
	NSString * _device;
	/// Mount point (/Volumes/VOLUME)
	NSString * _mountPoint;
	/// SATA, ATA, USB...
	VolProtocol _protocol;
	/// Flag to indicate if the disk is internal or external
	BOOL _isInternal;
	/// Flag to indicate if the disk is ejectable
	BOOL _isEjectable;
	/// Flag to indicate if the volume is currently mounted
	BOOL _isMounted;
	/// Flag to indicate if the volume is writtable
	NSUInteger _isWrittingEnabled;
	/// Session
	DASessionRef _session;
	/// BSD Disk reference
	DADiskRef _disk;
}

@property (nonatomic, readonly) NSString * name;
@property (nonatomic, readonly) NSString * uuid;
@property (nonatomic, readonly) NSString * deviceIdentifier;
@property (nonatomic, readonly) NSString * deviceNode;
@property (nonatomic, readonly) NSString * device;
@property (nonatomic, readonly) NSString * mountPoint;
@property (nonatomic, readonly) VolProtocol protocol;
@property (nonatomic, readonly) BOOL isInternal;
@property (nonatomic, readonly) BOOL isEjectable;
@property (nonatomic, readonly) BOOL isMounted;
@property (nonatomic, readwrite) NSUInteger isWrittingEnabled;

#pragma mark -
#pragma mark Constructors / Destructors

- (id)init;
- (id)initWithDiskutilInfo:(NSString *)info;
- (void)dealloc;
- (void)clearVars;

#pragma mark -
#pragma mark General Methods

- (void)parseInfo:(NSString *)info;
- (NSString *)extractInfoFrom:(NSString *)info atRange:(NSRange)range;
- (BOOL)extractBooleanFrom:(NSString *)info atRange:(NSRange)range;
- (NSInteger)extractIntegerFrom:(NSString *)str atRange:(NSRange)range;
- (void)mount;
- (void)unmount;
- (void)updateStatus;

@end

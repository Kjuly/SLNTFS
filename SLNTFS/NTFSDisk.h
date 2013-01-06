
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
	BOOL _internal;
	/// Flag to indicate if the disk is ejectable
	BOOL _ejectable;
	/// Flag to indicate if the volume is currently mounted
	BOOL _mounted;
	/// Flag to indicate if the volume is writtable
	NSUInteger _writtingEnabled;
	/// Session
	DASessionRef _session;
	/// BSD Disk reference
	DADiskRef _disk;
}
@property (nonatomic, readonly) NSString * Name;
@property (nonatomic, readonly) NSString * UUID;
@property (nonatomic, readonly) NSString * DeviceIdentifier;
@property (nonatomic, readonly) NSString * DeviceNode;
@property (nonatomic, readonly) NSString * Device;
@property (nonatomic, readonly) NSString * MountPoint;
@property (nonatomic, readonly) VolProtocol Protocol;
@property (nonatomic, readonly) BOOL Internal;
@property (nonatomic, readonly) BOOL Ejectable;
@property (nonatomic, readonly) BOOL Mounted;
@property (nonatomic, readwrite) NSUInteger WrittingEnabled;

#pragma mark -
#pragma mark Constructors / Destructors

- (id)init;
- (id)initWithDiskutilInfo:(NSString *)info;
- (void)dealloc;
- (void)clearVars;

#pragma mark -
#pragma mark General Methods

- (void)parseInfo:(NSString *)info;
- (NSString *)extractInfoFrom:(NSString *)info AtRange:(NSRange)range;
- (BOOL)extractBooleanFrom:(NSString *)info AtRange:(NSRange)range;
- (NSInteger)extractIntegerFrom:(NSString *)str AtRange:(NSRange)range;
- (void)mount;
- (void)unmount;
- (void)updateStatus;

@end

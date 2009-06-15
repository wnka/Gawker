//
//  FireWireNotifier.m
//  Gawker
//
//  Created by Phil Piwonka on 8/28/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "FireWireNotifier.h"

//
// Callback function declarations.
static void fwDeviceAdded(void *refCon, io_iterator_t iter);
static void fwDeviceRemoved(void *refCon, io_iterator_t iter);

@interface FireWireNotifier (Private)

//
// This function does the legwork of setting up
// receiving notifications on FireWire events
- (void)registerForFireWireNotifications;

//
// This function should actually be implemented by the delegate
- (void)fwDeviceAdded:(io_iterator_t)iterator;

//
// This function should actually be implemented by the delegate
- (void)fwDeviceRemoved:(io_iterator_t)iterator;

//
// Returns a string for the FireWire object in question.
- (NSString *)nameForFireWireObject:(io_object_t)thisObject;
@end

@implementation FireWireNotifier

//
// Init function, defaults to nil delegate
- (id)init
{
    NSLog(@"FireWireNotifier -init should never be called");
    return [self initWithDelegate:nil];
}

//
// Designated initializer.  Assigns delegate and
// what device to watch for notifications on.
- (id)initWithDelegate:(id)newDelegate
{
    if (self = [super init]) {
        isInit = YES;
        delegate = newDelegate;
        watchForDisconnect = [[NSMutableArray array] retain];
        [self registerForFireWireNotifications];
    }

    return self;
}

- (void)dealloc
{
    delegate = nil;
    [watchForDisconnect release];
    [super dealloc];
}

- (void)watchDeviceForDisconnect:(NSString *)device
{
    NSLog(@"\"%@\" registered for disconnect notification", device);
    [watchForDisconnect addObject:device];
}

@end

@implementation FireWireNotifier (Private)
- (void)registerForFireWireNotifications
{
    IONotificationPortRef ioKitNotificationPort = 
        IONotificationPortCreate(kIOMasterPortDefault);

    CFRunLoopSourceRef notificationRunLoopSource =
        IONotificationPortGetRunLoopSource(ioKitNotificationPort);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       notificationRunLoopSource,
                       kCFRunLoopDefaultMode);

    CFDictionaryRef myMatchDictionary =
        IOServiceMatching("IOFireWireDevice");
    kern_return_t matchingResult;
    io_iterator_t addedIter;
    matchingResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
                                                      kIOMatchedNotification,
                                                      myMatchDictionary,
                                                      fwDeviceAdded,
                                                      (void *)self,
                                                      &addedIter);
    if (matchingResult != kIOReturnSuccess) {
        NSLog(@"Matching notification registration failed: %d",
              matchingResult);
    }
    else {
        [self fwDeviceAdded:addedIter];
    }
    
    // Removal notification
    myMatchDictionary = IOServiceMatching("IOFireWireDevice");
    kern_return_t removedResult;
    io_iterator_t removedIter;
    
    removedResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
                                                     kIOTerminatedNotification,
                                                     myMatchDictionary,
                                                     fwDeviceRemoved,
                                                     self,
                                                     &removedIter);

    if (removedResult != kIOReturnSuccess) {
        NSLog(@"Couldn't add FW Device Removal Notification");
    }
    else {
        [self fwDeviceRemoved:removedIter];
    }
    
    // This is done since we don't want to send add notifications
    // the first time around.
    isInit = NO;
}

- (void)fwDeviceAdded:(io_iterator_t)iterator
{
    io_object_t thisObject = nil;
    while ((thisObject = IOIteratorNext(iterator))) {
        NSString *deviceName;        
        deviceName = [self nameForFireWireObject:thisObject];
        NSLog(@"FireWire Device Attached: %@", deviceName);         

        IOObjectRelease(thisObject);
    }

    if (!isInit && 
        [delegate respondsToSelector:@selector(fireWireDeviceAdded:)]) {
        sleep(1);
        [delegate fireWireDeviceAdded:self];
    }
}

- (void)fwDeviceRemoved:(io_iterator_t)iterator
{
    io_object_t thisObject = nil;
    while ((thisObject = IOIteratorNext( iterator ))) {
        NSString *deviceName;
        
        deviceName = [self nameForFireWireObject: thisObject];
        NSLog(@"FireWire Device Removed: %@" , deviceName);          
        unsigned index = [watchForDisconnect indexOfObject:deviceName];
        if (index != NSNotFound && 
            [delegate respondsToSelector:@selector(fireWireDeviceRemoved:name:)]) {
            [delegate fireWireDeviceRemoved:self name:deviceName];
        }
        
        IOObjectRelease(thisObject);
    }
}

- (NSString *)nameForFireWireObject:(io_object_t)thisObject
{
    kern_return_t nameResult;
    io_name_t deviceNameChars;
    
    nameResult = IORegistryEntryGetName(thisObject, 
                                        deviceNameChars);             
    NSString *tempDeviceName = [NSString stringWithCString: deviceNameChars];
    if (tempDeviceName && 
        ![tempDeviceName isEqualToString:@"IOFireWireDevice"])  {
        return tempDeviceName;  
    }

    tempDeviceName = 
        (NSString *)IORegistryEntrySearchCFProperty(thisObject,
                                                    kIOFireWirePlane,
                                                    (CFStringRef) @"FireWire Product Name",
                                                    nil,
                                                    kIORegistryIterateRecursively);
    
    if (tempDeviceName) {
        return tempDeviceName;
    }
    
    tempDeviceName = 
        (NSString *)IORegistryEntrySearchCFProperty(thisObject,
                                                    kIOFireWirePlane,
                                                    (CFStringRef) @"FireWire Vendor Name",
                                                    nil,
                                                    kIORegistryIterateRecursively);
    
    
    if (tempDeviceName)  {
        return tempDeviceName;
    }
    
    return @"Unnamed FireWire Device";
}
@end

static void fwDeviceAdded(void *refCon, io_iterator_t iter)
{
    [(FireWireNotifier*)refCon fwDeviceAdded:iter];
}

static void fwDeviceRemoved(void *refCon, io_iterator_t iter)
{
    [(FireWireNotifier*)refCon fwDeviceRemoved:iter];
}



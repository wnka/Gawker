//
//  USBNotifier.m
//  Gawker
//
//  Created by phil piwonka on 2/6/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "USBNotifier.h"


//
// Callback function declarations.
static void usbDeviceAdded(void *refCon, io_iterator_t iter);
static void usbDeviceRemoved(void *refCon, io_iterator_t iter);

@interface USBNotifier (Private)

//
// This function does the legwork of setting up
// receiving notifications on USB events
- (void)registerForUSBNotifications;

//
// This function should actually be implemented by the delegate
- (void)usbDeviceAdded:(io_iterator_t)iterator;

//
// This function should actually be implemented by the delegate
- (void)usbDeviceRemoved:(io_iterator_t)iterator;

//
// Returns a string for the USB object in question.
- (NSString *)nameForUSBObject:(io_object_t)thisObject;
@end

@implementation USBNotifier

//
// Init function, defaults to nil delegate
- (id)init
{
    NSLog(@"USBNotifier -init should never be called");
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
        [self registerForUSBNotifications];
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

@implementation USBNotifier (Private)
- (void)registerForUSBNotifications
{
    IONotificationPortRef ioKitNotificationPort = 
        IONotificationPortCreate(kIOMasterPortDefault);

    CFRunLoopSourceRef notificationRunLoopSource =
        IONotificationPortGetRunLoopSource(ioKitNotificationPort);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       notificationRunLoopSource,
                       kCFRunLoopDefaultMode);

    CFDictionaryRef myMatchDictionary =
        IOServiceMatching("IOUSBDevice");
    kern_return_t matchingResult;
    io_iterator_t addedIter;
    matchingResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
                                                      kIOMatchedNotification,
                                                      myMatchDictionary,
                                                      usbDeviceAdded,
                                                      (void *)self,
                                                      &addedIter);
    if (matchingResult != kIOReturnSuccess) {
        NSLog(@"Matching notification registration failed: %d",
              matchingResult);
    }
    else {
        [self usbDeviceAdded:addedIter];
    }
    
    // Removal notification
    myMatchDictionary = IOServiceMatching("IOUSBDevice");
    kern_return_t removedResult;
    io_iterator_t removedIter;
    
    removedResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
                                                     kIOTerminatedNotification,
                                                     myMatchDictionary,
                                                     usbDeviceRemoved,
                                                     self,
                                                     &removedIter);

    if (removedResult != kIOReturnSuccess) {
        NSLog(@"Couldn't add FW Device Removal Notification");
    }
    else {
        [self usbDeviceRemoved:removedIter];
    }

    // This is done since we don't want to send add notifications
    // the first time around.
    isInit = NO;
}

- (void)usbDeviceAdded:(io_iterator_t)iterator
{
    io_object_t thisObject = nil;
    while ((thisObject = IOIteratorNext(iterator))) {
        NSString *deviceName;        
        deviceName = [self nameForUSBObject:thisObject];
        NSLog(@"USB Device Attached: %@", deviceName);         

        IOObjectRelease(thisObject);
    }

    if (!isInit && 
        [delegate respondsToSelector:@selector(usbDeviceAdded:)]) {
        [delegate usbDeviceAdded:self];
    }
}

- (void)usbDeviceRemoved:(io_iterator_t)iterator
{
    io_object_t thisObject = nil;
    while ((thisObject = IOIteratorNext( iterator ))) {
        NSString *deviceName;
        
        deviceName = [self nameForUSBObject: thisObject];
        NSLog(@"USB Device Removed: %@" , deviceName);          
        unsigned index = [watchForDisconnect indexOfObject:deviceName];
        if (index != NSNotFound && 
            [delegate respondsToSelector:@selector(usbDeviceRemoved:name:)]) {
            [delegate usbDeviceRemoved:self name:deviceName];
        }
        IOObjectRelease(thisObject);
    }
}

- (NSString *)nameForUSBObject:(io_object_t)thisObject
{
    kern_return_t nameResult;
    io_name_t deviceNameChars;
    
    nameResult = IORegistryEntryGetName(thisObject, 
                                        deviceNameChars);             
    NSString *tempDeviceName = [NSString stringWithCString: deviceNameChars];
    if (tempDeviceName && 
        ![tempDeviceName isEqualToString:@"IOUSBDevice"])  {
        return tempDeviceName;  
    }

    tempDeviceName = 
        (NSString *)IORegistryEntrySearchCFProperty(thisObject,
                                                    kIOUSBPlane,
                                                    (CFStringRef) @"USB Product Name",
                                                    nil,
                                                    kIORegistryIterateRecursively);
    
    if (tempDeviceName) {
        return tempDeviceName;
    }
    
    tempDeviceName = 
        (NSString *)IORegistryEntrySearchCFProperty(thisObject,
                                                    kIOUSBPlane,
                                                    (CFStringRef) @"USB Vendor Name",
                                                    nil,
                                                    kIORegistryIterateRecursively);
    
    
    if (tempDeviceName)  {
        return tempDeviceName;
    }
    
    return @"Unnamed USB Device";
}
@end

static void usbDeviceAdded(void *refCon, io_iterator_t iter)
{
    [(USBNotifier*)refCon usbDeviceAdded:iter];
}

static void usbDeviceRemoved(void *refCon, io_iterator_t iter)
{
    [(USBNotifier*)refCon usbDeviceRemoved:iter];
}



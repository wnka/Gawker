//
//  USBNotifier.h
//  Gawker
//
//  Created by phil piwonka on 2/6/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface USBNotifier : NSObject {
    id delegate;
    NSMutableArray *watchForDisconnect;
    BOOL isInit;
}

- (id)init;
- (id)initWithDelegate:(id)newDelegate;
- (void)dealloc;

- (void)watchDeviceForDisconnect:(NSString *)device;

@end

//
// These methods are what gets called on the delegate
@interface USBNotifier (DelegateMethods)

- (void)usbDeviceAdded:(USBNotifier *)fwNote;
- (void)usbDeviceRemoved:(USBNotifier *)fwNote
                 name:(NSString *)device;

@end

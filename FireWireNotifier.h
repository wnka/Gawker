//
//  FireWireNotifier.h
//  Gawker
//
//  Created by Phil Piwonka on 8/28/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FireWireNotifier : NSObject {
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
@interface FireWireNotifier (DelegateMethods)

- (void)fireWireDeviceAdded:(FireWireNotifier *)fwNote;
- (void)fireWireDeviceRemoved:(FireWireNotifier *)fwNote 
                         name:(NSString *)device;

@end

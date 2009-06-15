//
//  BonjourCameraController.h
//  Gawker
//
//  Created by Phil Piwonka on 11/19/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NetworkCameraController.h"

@interface BonjourCameraController : NetworkCameraController {
    
}

- (id)initWithService:(NSNetService *)aNetService delegate:(id)theDelegate;
- (id)init;

@end

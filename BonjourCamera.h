//
//  BonjourCamera.h
//  Gawker
//
//  Created by Phil Piwonka on 11/20/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NetworkCamera.h"

@interface BonjourCamera : NetworkCamera {
    NSNetService *netService;
    BOOL releaseOnWindowClose;
}

- (id)initWithService:(NSNetService *)aNetService;
- (NSNetService *)netService;

- (void)serviceDidShutdown;

@end

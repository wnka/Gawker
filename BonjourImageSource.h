//
//  BonjourImageSource.h
//  Gawker
//
//  Created by Phil Piwonka on 11/13/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NetworkImageSource.h"

@interface BonjourImageSource : NetworkImageSource
{
    NSNetService *netService;
}

- (id)initWithService:(NSNetService *)aNetService;

- (BOOL)setEnabled:(BOOL)enable;

@end

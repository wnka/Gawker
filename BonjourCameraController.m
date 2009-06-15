//
//  BonjourCameraController.m
//  Gawker
//
//  Created by Phil Piwonka on 11/19/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "BonjourCameraController.h"
#import "BonjourImageSource.h"

@implementation BonjourCameraController
- (id)initWithService:(NSNetService *)aNetService delegate:(id)theDelegate
{
    if (self = [super initWithDelegate:theDelegate]) {
        imageSource = [[BonjourImageSource alloc] initWithService:aNetService];

        [self registerForNotifications];
    }
    
    return self;
}

- (id)init
{
    NSLog(@"Should not call -[BonjourCameraController init]!");
    return [self initWithService:nil delegate:nil];
}

@end

//
//  NetworkCameraController.m
//  Gawker
//
//  Created by Phil Piwonka on 10/10/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "NetworkCameraController.h"
#import "NetworkImageSource.h"

@interface NetworkCameraController (PrivateMethods)
- (void)registerForNotifications;
- (void)receivedImageNotification:(NSNotification *)note;
- (void)sourceNewDescription:(NSNotification *)note;
- (void)sourceNeedsPassword:(NSNotification *)note;
@end

@implementation NetworkCameraController

- (id)initWithIp:(NSString *)ip port:(int)port
    delegate:(id)theDelegate
{
    if (self = [super initWithDelegate:theDelegate]) {
        imageSource = [[NetworkImageSource alloc] initWithIp:ip port:port];
        [self registerForNotifications];
    }

    return self;
}

- (id)init
{
    NSLog(@"NetworkCameraController -init shouldn't be used!");
    return [self initWithIp:nil port:0 delegate:nil];
}

@end

@implementation NetworkCameraController (PrivateMethods)
- (void)registerForNotifications
{
    //
    // Register for notifications
    [super registerForNotifications];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self
        selector:@selector(sourceNewDescription:)
        name:@"DescriptionUpdate"
        object:imageSource];
    
    [nc addObserver:self
        selector:@selector(sourceNeedsPassword:)
        name:@"SourceNeedsPassword"
        object:imageSource];
}

- (void)receivedImageNotification:(NSNotification *)note
{
    [super receivedImageNotification:note];
    [self recordCurrentImage];
}

- (void)sourceNewDescription:(NSNotification *)note
{
    if ([delegate respondsToSelector:@selector(cameraControllerNewDescription:)]) {
        [delegate cameraControllerNewDescription:self];
    }
}

- (void)sourceNeedsPassword:(NSNotification *)note
{
    if ([delegate respondsToSelector:@selector(cameraControllerNeedsPassword:)]) {
        [delegate cameraControllerNeedsPassword:self];
    }
}

@end


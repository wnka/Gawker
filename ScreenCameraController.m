//
//  ScreenCameraController.m
//  Gawker
//
//  Created by phil piwonka on 3/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ScreenCameraController.h"


@implementation ScreenCameraController
- (id)initWithDelegate:(id)newDelegate
{
    if (self = [super initWithDelegate:newDelegate]) {
        imageSource = [[ScreenImageSource alloc] init];
        [self registerForNotifications];
    }
    
    return self;
}

- (void)captureFrameAtInterval:(double)interval
{
    if (recordTimer) {
        [recordTimer invalidate];
        [recordTimer release];
        recordTimer = nil;
    }

    recordTimer = [[NSTimer scheduledTimerWithTimeInterval:interval
                            target:self
                            selector:@selector(recordTimerFired:)
                            userInfo:nil
                            repeats:YES] retain];
}

- (NSDate *)nextFrameTime
{
    NSDate *fireDate = nil;
    if (isRecording) {
        fireDate = [recordTimer fireDate];
    }
    return fireDate;
}

- (BOOL)stopRecording
{
    if (isRecording) {
        //
        // Release and invalidate timer.
        //
        [recordTimer invalidate];
        [recordTimer release];
        recordTimer = nil;        
    }
    
    return [super stopRecording];
}

- (void)recordTimerFired:(NSTimer *)timer
{
    [self recordCurrentImage];
}

- (void)setScreenToGrab:(int)screen
{
    [imageSource setScreenToGrab:screen];
}

@end

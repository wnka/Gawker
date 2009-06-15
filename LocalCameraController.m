//
//  LocalCameraController.m
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "LocalCameraController.h"
#import "CameraImageSource.h"
#import "ImageServer.h"
#import "LapseMovie.h"

@interface LocalCameraController (PrivateMethods)
- (void)recordTimerFired:(NSTimer *)timer;
@end

@implementation LocalCameraController
- (id)initWithDelegate:(id)newDelegate cameraName:(NSString *)name
{
    if (self = [super initWithDelegate:newDelegate]) {
        //
        // Create Image Source
        imageSource = [[CameraImageSource alloc] initWithCameraName:name];
        [self registerForNotifications];
    }

    return self;
}

- (id)initWithDelegate:(id)newDelegate
{
    return [self initWithDelegate:newDelegate 
                 cameraName:[NSString stringWithString:@"Camera"]];
}

- (id)init
{
    return [self initWithDelegate:nil
                 cameraName:[NSString stringWithString:@"Camera"]];
}

- (void)dealloc
{
    NSLog(@"LocalCameraController -dealloc");
    [super dealloc];
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

@end

@implementation LocalCameraController (PrivateMethods)
- (void)recordTimerFired:(NSTimer *)timer
{
    [self recordCurrentImage];
}

@end

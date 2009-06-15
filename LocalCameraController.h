//
//  LocalCameraController.h
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CameraController.h"

@class ImageServer;

@interface LocalCameraController : CameraController {
    NSTimer *recordTimer;
}

- (id)initWithDelegate:(id)newDelegate cameraName:(NSString *)name;
- (id)init;
- (void)dealloc;

- (void)captureFrameAtInterval:(double)interval;
- (NSDate *)nextFrameTime;

@end

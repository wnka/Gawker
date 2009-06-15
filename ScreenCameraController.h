//
//  ScreenCameraController.h
//  Gawker
//
//  Created by phil piwonka on 3/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScreenImageSource.h"
#import "CameraController.h"

@interface ScreenCameraController : CameraController {
    NSTimer *recordTimer;
}

- (void)captureFrameAtInterval:(double)interval;
- (void)recordTimerFired:(NSTimer *)timer;
- (void)setScreenToGrab:(int)screen;
@end

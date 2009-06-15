//
//  CombinedCameraController.h
//  Gawker
//
//  Created by Phil Piwonka on 1/4/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CameraController.h"
#import "ImageSource.h"

@interface CombinedCameraController : CameraController {
    NSMutableArray *components;
    NSMutableArray *thumbnails;

    int thumbnailIndex;

    NSTimer *toggleTimer;
    NSTimer *recordTimer;

    BOOL isEnabled;
    BOOL camerasAreLocal;
}

- (id)initWithSources:(NSArray *)sources delegate:(id)theDelegate;
- (id)init;

- (NSImage *)screenImage;
- (NSImage *)recentImage;

- (BOOL)isSourceEnabled;
- (BOOL)setSourceEnabled:(BOOL)state;
- (BOOL)allSourcesEnabled;

- (NSString *)sourceDescription;
- (void)setSourceDescription:(NSString *)newDesc;
- (NSString *)sourceSubDescription;
- (void)setSourceSubDescription:(NSString *)newDesc;

- (void)captureFrameAtInterval:(double)interval;
- (BOOL)stopRecording;
@end

@interface CombinedCameraController (DelegateMethods)
//
// These methods will be implemented by the delegate.
- (void)cameraControllerUpdatedImageForCell:(CameraController *)aCamController;
@end

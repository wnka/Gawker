//
//  CombinedCamera.h
//  Gawker
//
//  Created by Phil Piwonka on 1/4/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Camera.h"

@class CameraController;
@class CombinedCameraController;
@class QTMovieView;

@interface CombinedCamera : Camera {
    //
    // Local Save Accessory View and Elements
    // This is a lot of duplication which I don't like,
    // but for now I'll do it the obvious/silly way.
    //
    IBOutlet NSView *localSaveAccessoryView;
    IBOutlet NSPopUpButton *localSaveQuality;
    IBOutlet NSButton *localSaveTime;
    IBOutlet NSTextField *localSaveFPS;
    IBOutlet NSTextField *localSaveFrameInterval;

    BOOL camerasAreLocal;
    NSTimer *localDisplayUpdate;
    int numberOfCameras;
}

- (id)initWithCameras:(NSArray *)cameras;
- (id)init;

- (void)awakeFromNib;

@end

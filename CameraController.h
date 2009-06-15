//
//  CameraController.h
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageSource.h"

@class LapseMovie;
@class QTMovie;

@interface CameraController : NSObject {
    // Movie Recording
    LapseMovie *outputMovie;
    BOOL isRecording;
    BOOL putTimeOnImage;
    double scaleFactor;

    // This is what produces the images we are interested in.
    id<ImageSource> imageSource;

    // This is for putting the time on the movie images
    NSMutableDictionary *timeTextAttributes;
    
    // Typically this will be some sort of view object.
    id delegate;
}

- (id)initWithDelegate:(id)theDelegate;

- (BOOL)isRecording;

- (BOOL)startRecordingToFilename:(NSString *)file
                         quality:(NSString *)quality
                     scaleFactor:(double)scale
                             FPS:(double)fps
                  putTimeOnImage:(BOOL)applyTime
                   timestampFont:(NSFont *)timestampFont;

- (BOOL)stopRecording;
- (void)recordCurrentImage;

- (BOOL)isSourceEnabled;
- (BOOL)setSourceEnabled:(BOOL)state;

- (id<ImageSource>)imageSource;
- (QTMovie *)movie;
- (NSImage *)recentImage;

- (NSString *)sourceDescription;
- (void)setSourceDescription:(NSString *)newDesc;
- (NSString *)sourceSubDescription;
- (void)setSourceSubDescription:(NSString *)newDesc;

- (NSDate *)nextFrameTime;

@end

@interface CameraController (DelegateMethods)
//
// These methods will be implemented by the delegate.
- (void)cameraController:(CameraController *)aCamController
             hasNewImage:(NSImage *)newImage;
- (void)cameraControllerConnected:(CameraController *)controller;
- (void)cameraControllerDisconnected:(CameraController *)controller;
@end



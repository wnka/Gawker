//
//  Camera.h
//  Gawker
//
//  Created by Phil Piwonka on 1/7/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CameraController;
@class QTMovieView;
@class CameraFeaturesWindowController;
@class ImageTransitionView;
@class CameraStatusView;

@interface Camera : NSWindowController {
    IBOutlet ImageTransitionView *imageTransitionView;
    IBOutlet QTMovieView *movieView;
    IBOutlet CameraStatusView *camStatusView;

    IBOutlet NSButton *recordButton;
    IBOutlet NSButton *previewButton;

    IBOutlet NSButton *moreButton;

    IBOutlet NSTextField *timeToNextFrameField;
    NSTimer *timeToNextFrameTimer;

    //
    // Save Accessory View and Elements
    //
    IBOutlet NSView *saveAccessoryView;
    IBOutlet NSPopUpButton *saveQuality;
    IBOutlet NSPopUpButton *saveSize;
    IBOutlet NSButton *saveTime;
    IBOutlet NSTextField *saveFPS;

    NSSavePanel *savePanel;
    NSView *saveAccessoryViewToUse;

    CameraController *camController;
    NSImage *icon;

    NSRect nonPreviewSize;
    Rect movieSize;

    BOOL isPreviewing;

    BOOL isScheduled;

    NSDate *startTime;
    NSDate *stopTime;

    NSTimer *startTimer;
    NSTimer *stopTimer;

    BOOL openOnConnect;

    BOOL isAnimating;

    CameraFeaturesWindowController *camFeaturesWindow;
}

- (id)init;
- (void)dealloc;

- (void)awakeFromNib;

- (BOOL)isSourceEnabled;
- (void)setSourceEnabled;
- (void)setSourceEnabled:(BOOL)enable;
- (void)setSourceEnabled:(BOOL)enable openWindow:(BOOL)open;

- (void)showEnableError;

- (CameraController *)camController;

- (BOOL)isScheduled;

- (NSImage *)recentImage;

- (NSString *)sourceDescription;
- (NSString *)sourceSubDescription;

- (IBAction)toggleRecord:(id)sender;
- (IBAction)togglePreview:(id)sender;

- (BOOL)isRecording;
- (NSFont *)timestampFont;

- (void)setScheduledStart:(NSDate *)recStart
            recordOptions:(NSDictionary *)options;
- (void)setScheduledStop:(NSDate *)recStop;

- (void)clearScheduledEvents;

- (void)scheduledStart:(NSTimer *)timer;
- (void)scheduledStop:(NSTimer *)timer;

- (NSDate *)startTime;
- (NSDate *)stopTime;

- (IBAction)showCameraFeaturesWindow:(id)sender;
- (void)closeCameraFeaturesWindow;

@end

@interface Camera (DelegateMethods)
- (void)cameraController:(CameraController *)aCamController
             hasNewImage:(NSImage *)anImage;
- (void)cameraControllerConnected:(CameraController *)controller;
- (void)cameraControllerDisconnected:(CameraController *)controller;
@end

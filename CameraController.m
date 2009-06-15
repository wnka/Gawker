//
//  CameraController.m
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "CameraController.h"
#import "LapseMovie.h"
#import "ImageText.h"

@interface CameraController (PrivateMethods)
- (void)registerForNotifications;
- (void)receivedImageNotification:(NSNotification *)note;
- (void)sourceConnected:(NSNotification *)note;
- (void)sourceDisconnected:(NSNotification *)note;
@end

@implementation CameraController

- (id)initWithDelegate:(id)newDelegate
{
    if (self = [super init]) {
        isRecording = NO;
        delegate = newDelegate;
        timeTextAttributes = [[NSMutableDictionary alloc] init];
		NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:NSMakeSize(1.1, -1.1)];
        [shadow setShadowBlurRadius:0.3];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0
                                        alpha:0.8]];
        
		[timeTextAttributes setObject:[NSColor whiteColor]
                            forKey:NSForegroundColorAttributeName];        
        [timeTextAttributes setObject:shadow
                            forKey:NSShadowAttributeName];        
		[shadow release];
		
        putTimeOnImage = NO;
        scaleFactor = 1.0;
    }
    return self;
}

- (id)init
{
    return [self initWithDelegate:nil];
}

- (void)dealloc
{
    NSLog(@"in CameraController -dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopRecording];
    [imageSource release];
    [timeTextAttributes release];
    [super dealloc];
}

- (BOOL)isRecording
{
    return isRecording;
}

- (BOOL)startRecordingToFilename:(NSString *)file
                         quality:(NSString *)quality
                     scaleFactor:(double)scale
                             FPS:(double)fps
                  putTimeOnImage:(BOOL)applyTime
                   timestampFont:(NSFont *)timestampFont
{
    [timeTextAttributes setObject:timestampFont
                        forKey:NSFontAttributeName];

    if (isRecording) {
        NSLog(@"Already recording, stopping current movie");
        [self stopRecording];
    }

    putTimeOnImage = applyTime;
    scaleFactor = scale;
    
    outputMovie = [[LapseMovie alloc] initWithFilename:file
                                      quality:quality
                                      FPS:fps];
    if (!outputMovie) {
        NSLog(@"Error creating LapseMovie!");
    }
    else {
        isRecording = YES;
        [self recordCurrentImage];
    }
    
    return isRecording;
}

- (BOOL)stopRecording
{
    BOOL success = YES;
    if (isRecording) {
        success = [outputMovie writeToDisk];
        [outputMovie release];
        outputMovie = nil;
        isRecording = NO;
    }
    return success;
}

- (void)recordCurrentImage
{
    if (isRecording) {
        NSLog(@"Recording Current Image");
        NSImage *image = [imageSource recentImage];

        if (!image) {
            NSLog(@"Image in nil, won't record");
			return;
        }

        if (putTimeOnImage) {
            NSImage *timeImage =
                [ImageText imageWithImage:image
                           stringAtBottom:[imageSource recentTime]
                           attributes:timeTextAttributes
                           scaleFactor:scaleFactor];
            image = timeImage;
        }
        else if (scaleFactor != 1.0) {
            NSArray *images = [NSArray arrayWithObjects:image, nil];
            NSSize imgSize = 
                NSMakeSize(640 * scaleFactor, 480 * scaleFactor);
            image = [ImageText compositeImages:images
                               sizeOfEach:imgSize];
        }
        [outputMovie addImage:image];
    }
}

- (BOOL)isSourceEnabled
{
    return [imageSource isEnabled];
}

- (BOOL)setSourceEnabled:(BOOL)state
{
    if (!state) {
        [self stopRecording];
    }
    
    return [imageSource setEnabled:state];
}

- (id <ImageSource>)imageSource
{
    return imageSource;
}

- (QTMovie *)movie
{
    return [outputMovie movie];
}

- (NSImage *)recentImage
{
    return [imageSource recentImage];
}

- (NSString *)sourceDescription
{
    return [imageSource sourceDescription];
}

- (void)setSourceDescription:(NSString *)newDesc
{
    [imageSource setSourceDescription:newDesc];
}

- (NSString *)sourceSubDescription
{
    return [imageSource sourceSubDescription];
}

- (void)setSourceSubDescription:(NSString *)newDesc
{
    [imageSource setSourceSubDescription:newDesc];
}

- (NSDate *)nextFrameTime
{
    return nil;
}

@end

@implementation CameraController (PrivateMethods)

- (void)registerForNotifications
{
    //
    // Register for notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
        selector:@selector(receivedImageNotification:)
        name:@"ImageFromSource"
        object:imageSource];

    [nc addObserver:self
        selector:@selector(sourceDisconnected:)
        name:@"SourceDisconnect"
        object:imageSource];

    [nc addObserver:self
        selector:@selector(sourceConnected:)
        name:@"SourceConnect"
        object:imageSource];
}
    
- (void)receivedImageNotification:(NSNotification *)note
{
    if ([delegate respondsToSelector:@selector(cameraController:hasNewImage:)]) {
        [delegate cameraController:self hasNewImage:[[note object] recentImage]];
    }
}

- (void)sourceConnected:(NSNotification *)note
{
    if ([delegate respondsToSelector:@selector(cameraControllerConnected:)]) {
        [delegate cameraControllerConnected:self];
    }
    
    if ([self isRecording]) {
        NSLog(@"First image, needs to record");
        [self recordCurrentImage];
    }
}

- (void)sourceDisconnected:(NSNotification *)note
{
    [self setSourceEnabled:NO];

    if ([delegate respondsToSelector:@selector(cameraControllerDisconnected:)]) {
        [delegate cameraControllerDisconnected:self];
    }
}

@end

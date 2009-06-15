//  CameraImageSource.h
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//
//  Based heavily on CSGCamera
//  Created by Tim Omernick.
//

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import "ImageSource.h"

@interface CameraImageSource : NSObject <ImageSource>
{
    SeqGrabComponent component;
    SGChannel channel;
    GWorldPtr gWorld;
    Rect bounds;
    ImageSequence decompressionSequence;
    NSTimer *idleTimer;
    BOOL isEnabled;
    
    NSTimeZone *timeZone;

    NSImage *recentImage;
    NSString *recentTime;

    NSString *sourceDescription;
    NSString *sourceSubDescription;

    NSString *cameraName;
}

- (id)initWithCameraName:(NSString *)name;
- (id)init;

- (BOOL)startWithSize:(NSSize)frameSize;
- (BOOL)stop;

- (BOOL)isEnabled;
- (BOOL)setEnabled:(BOOL)state;

- (NSImage *)recentImage;
- (void)setRecentImage:(NSImage *)newImage;

- (NSString *)recentTime;

- (NSString *)sourceDescription;
- (void)setSourceDescription:(NSString *)newDesc;
- (NSString *)sourceSubDescription;
- (void)setSourceSubDescription:(NSString *)newDesc;
@end


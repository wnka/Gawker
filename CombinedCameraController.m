//
//  CombinedCameraController.m
//  Gawker
//
//  Created by Phil Piwonka on 1/4/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "CombinedCameraController.h"
#import "ImageSource.h"
#import "NetworkImageSource.h"
#import "CameraImageSource.h"
#import "ScreenImageSource.h"
#import "ImageText.h"
#import "LapseMovie.h"

#import "CombinedCameraComponent.h"
#import "CombinedCameraLocalComponent.h"
#import "CombinedCameraNetworkComponent.h"
#import "CombinedCameraScreenComponent.h"

@interface CombinedCameraController (PrivateMethods)
- (void)recordTimerFired:(NSTimer *)timer;

- (NSImage *)recordImageWithTime:(BOOL)applyTime;

- (void)registerForNotifications;
- (void)receivedImageNotification:(NSNotification *)note;

//
// These methods are used so that the NSImageCell in the main window
// will toggle back and forth between the two images from the two
// sources.
//
- (void)toggleImages:(NSNotification *)note;
- (void)updateThumbnails;
- (BOOL)allNewImages;
@end

@implementation CombinedCameraController

- (id)initWithSources:(NSArray *)sources delegate:(id)theDelegate
{
    if (self = [super initWithDelegate:theDelegate]) {
        components = 
            [[NSMutableArray arrayWithCapacity:[sources count]] retain];

        thumbnails =
            [[NSMutableArray arrayWithCapacity:[sources count]] retain];
        
        NSEnumerator *sourceEnum = [sources objectEnumerator];
        id<ImageSource> source = nil;
        camerasAreLocal = YES;
        while (source = [sourceEnum nextObject]) {
            if ([source isKindOfClass:[CameraImageSource class]]) {
                CombinedCameraLocalComponent *comp = 
                    [[CombinedCameraLocalComponent alloc] 
                        initWithSource:(id)source];
                [components addObject:comp];
                [comp release];
            }
            else if ([source isKindOfClass:[ScreenImageSource class]]) {
                CombinedCameraLocalComponent *comp = 
                    [[CombinedCameraScreenComponent alloc] 
                        initWithSource:(id)source];
                [components addObject:comp];
                [comp release];                
            }
            else {
                camerasAreLocal = NO;
                CombinedCameraNetworkComponent *comp = 
                    [[CombinedCameraNetworkComponent alloc] 
                        initWithSource:(id)source];
                [components addObject:comp];
                [comp release];
            }
        }
        
        thumbnailIndex = 0;
        [self updateThumbnails];
        [self registerForNotifications];
        [self receivedImageNotification:nil];
    }
    return self;
}

- (id)init
{
    NSLog(@"CombinedCameraController -init shouldn't be used!");
    return [self initWithSources:nil delegate:nil];
}

- (void)dealloc
{
    [components release];
    [thumbnails release];

    [toggleTimer invalidate];
    [toggleTimer release];
    toggleTimer = nil;

    if (recordTimer) {
        [recordTimer invalidate];
        [recordTimer release];
        recordTimer = nil;
    }

    [super dealloc];
}

- (NSImage *)screenImage
{
    NSSize imgSize = NSMakeSize(320, 240);

    NSMutableArray *imageArray = 
        [NSMutableArray arrayWithCapacity:[components count]];
    
    id<CombinedCameraComponent> comp = nil;
    NSEnumerator *compEnum = [components objectEnumerator];

    while (comp = [compEnum nextObject]) {
        NSImage *screenImage = [[comp screenImage] retain];
        if (!screenImage) {
            screenImage = [[NSImage imageNamed:@"black.png"] retain];
        }
        [imageArray addObject:screenImage];
        [screenImage release];
    }

    return [ImageText compositeImages:imageArray
                      sizeOfEach:imgSize];
}

- (NSImage *)recentImage
{
    return [thumbnails objectAtIndex:thumbnailIndex];
}

- (void)recordCurrentImage
{
    if (isRecording) {
        NSLog(@"Recording Current Image");
        [outputMovie addImage:[self recordImageWithTime:putTimeOnImage]];
        // Flip all switches to not updated
        [components makeObjectsPerformSelector:@selector(clearNew)];
    }
}

- (BOOL)isSourceEnabled
{
    return isEnabled;
}

- (BOOL)setSourceEnabled:(BOOL)state
{
    isEnabled = NO;
    BOOL wasSuccessful = YES;
    if (!state) {
        [self stopRecording];
        [toggleTimer invalidate];
        [toggleTimer release];
        toggleTimer = nil;
    }
    else {
        if ([self allSourcesEnabled]) {
            isEnabled = YES;
            toggleTimer = [[NSTimer scheduledTimerWithTimeInterval:2.0
                                    target:self
                                    selector:@selector(toggleImages:)
                                    userInfo:nil
                                    repeats:YES] retain];
        }
        else {
            NSLog(@"One of combined elements not enabled!");
            wasSuccessful = NO;
        }
    }

    return wasSuccessful;
    // Since we don't own the imageSources, don't stop them.
}

- (BOOL)allSourcesEnabled
{
    BOOL allEnabled = YES;
    NSEnumerator *compEnum = [components objectEnumerator];
    id<CombinedCameraComponent> comp = nil;
    while (comp = [compEnum nextObject]) {
        if (![[comp imageSource] isEnabled]) {
            allEnabled = NO;
            break;
        }
    }

    if (allEnabled) {
        if ([delegate respondsToSelector:@selector(cameraControllerConnected:)]) {
            [delegate cameraControllerConnected:self];
        }
    }
    else {
        if ([delegate respondsToSelector:@selector(cameraControllerDisconnected:)]) {
            [delegate cameraControllerDisconnected:self];
        }
    }
    
    return allEnabled;
}

- (NSString *)sourceDescription
{
    NSMutableString *desc = [NSMutableString stringWithCapacity:64];
    NSEnumerator *compEnum = [components objectEnumerator];
    id<ImageSource> src = nil;
    BOOL firstCam = YES;
    while (src = [[compEnum nextObject] imageSource]) {
        if (firstCam) {
            firstCam = NO;
            [desc appendString:[src sourceDescription]];
        }
        else {
            [desc appendFormat:@" + %@", [src sourceDescription]];
        }
    }
    
    return desc;
}

- (void)setSourceDescription:(NSString *)newDesc
{
    NSLog(@"Shouldn't set source description on Combined Camera");
}

- (NSString *)sourceSubDescription
{
    return [NSString stringWithString:@"Combined Camera"];
}

- (void)setSourceSubDescription:(NSString *)newDesc
{
    NSLog(@"Shouldn't set source sub description on Combined Camera");
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

@implementation CombinedCameraController (PrivateMethods)
- (void)recordTimerFired:(NSTimer *)timer
{
    [self recordCurrentImage];
}

- (NSImage *)recordImageWithTime:(BOOL)applyTime
{
    NSSize imgSize = NSMakeSize(320,240);

    NSMutableArray *imageArray = 
        [NSMutableArray arrayWithCapacity:[components count]];
    
    id<CombinedCameraComponent> comp = nil;
    NSEnumerator *compEnum = [components objectEnumerator];

    while (comp = [compEnum nextObject]) {
        NSImage *compImage = [[comp image] retain];
        if (applyTime) {

            // This is done for an interesting reason.  ScreenCameras 
            // update their image when you call [comp image].  This also
            // updates the timeStamp.  Passing the image and timeStamp in
            // the ImageTest message
            // to the ImageText function calls execute in different order
            // on Intel and PPC.  On intel, the functions to evaluate the
            // args execute in reverse order, so [comp timeStamp] would
            // execute before [comp image].  Since [comp image] updates
            // the timeStamp, the timeStamp gets updated, making the value
            // passed invalid.  This caused a crash on Intel.
            // So now we'll get the args and retain them, pass them in,
            // then release them.

            NSString *compTime = nil;
            if (!compImage) {
                compImage = [[NSImage imageNamed:@"black.png"] retain];
                compTime = [[NSString stringWithString:@"Camera Disconnected"] retain];
            }
            else {
                compTime = [[comp timeStamp] retain];
            }
            [imageArray addObject:[ImageText imageWithImage:compImage
                                             stringAtBottom:compTime
                                             attributes:timeTextAttributes
                                             scaleFactor:0.5]];
            [compTime release];
        }
        else {
            if (!compImage) {
                compImage = [[NSImage imageNamed:@"black.png"] retain];
            }
            [imageArray addObject:compImage];
        }
        [compImage release];
    }

    if (applyTime) {
        imgSize = [[imageArray objectAtIndex:0] size];
    }
    return [ImageText compositeImages:imageArray
                      sizeOfEach:imgSize];
}

- (void)registerForNotifications
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSEnumerator *compEnum = [components objectEnumerator];
    id<CombinedCameraComponent> comp = nil;
    
    while (comp = [compEnum nextObject]) {
        if ([[comp imageSource] isKindOfClass:[NetworkImageSource class]]) {
            [nc addObserver:self
                selector:@selector(receivedImageNotification:)
                name:@"ImageFromSource"
                object:[comp imageSource]];
        }
    }
}

- (void)receivedImageNotification:(NSNotification *)note
{
    if (!isEnabled) {
        return;
    }

    if (isRecording) {
        // First, we need to check if the image from this source hasn't been
        // recorded yet.  If it hasn't, we need to record it before we can
        // update.

        BOOL found = NO;
        NSEnumerator *compEnum = [components objectEnumerator];
        id<CombinedCameraComponent> comp = nil;
        while (comp = [compEnum nextObject]) {
            if ([comp isEqual:[note object]]) {
                found = YES;
                break;
            }
        }

        if (!found) {
            NSLog(@"Error in Combined Camera!");
            return;
        }

        BOOL needToCheckAll = YES;
        if ([comp isNew]) {
            // We have an image that needs to be recorded.
            // Can leave flag as YES.
            [self recordCurrentImage];
            needToCheckAll = NO;
        }

        // Update all the components
        [components makeObjectsPerformSelector:@selector(update)];

        if (needToCheckAll && [self allNewImages]) {
            [self recordCurrentImage];
        }
    }
    else {
        // Update all the components
        [components makeObjectsPerformSelector:@selector(update)];
    }

    //
    // Update display
    //
    [self updateThumbnails];
    if ([delegate respondsToSelector:@selector(cameraController:hasNewImage:)]) {
        [delegate cameraController:self hasNewImage:[self screenImage]];
    }
    
}

- (void)toggleImages:(NSNotification *)note
{
    if (camerasAreLocal) {
        [self updateThumbnails];
        if ([delegate respondsToSelector:@selector(cameraController:hasNewImage:)]) {
            [delegate cameraController:self hasNewImage:[self screenImage]];
        }
    }
    thumbnailIndex = (thumbnailIndex + 1) % [thumbnails count];

    if ([delegate respondsToSelector:@selector(cameraControllerUpdatedImageForCell:)]) {
        [delegate cameraControllerUpdatedImageForCell:self];
    }
}

- (void)updateThumbnails
{
    int i;
    if ([thumbnails count] == 0) {
        for (i = 0; i < [components count]; ++i) {
            NSImage *compThumb = 
                [[[components objectAtIndex:i] thumbnail] retain];
            if (!compThumb) {
                compThumb = [[NSImage imageNamed:@"black.png"] retain];
            }
            [thumbnails addObject:compThumb];
            [compThumb release];
        }
    }
    else {
        for (i = 0; i < [components count]; ++i) {
            NSImage *compThumb = 
                [[[components objectAtIndex:i] thumbnail] retain];
            if (!compThumb) {
                compThumb = [[NSImage imageNamed:@"black.png"] retain];
            }
            [thumbnails replaceObjectAtIndex:i
                        withObject:compThumb];
            [compThumb release];
        }
    }
}

- (BOOL)allNewImages
{
    BOOL allUpdated = YES;
    NSEnumerator *compEnum = [components objectEnumerator];
    id<CombinedCameraComponent> comp = nil;
    while (comp = [compEnum nextObject]) {
        if (![comp isNew]) {
            allUpdated = NO;
            break;
        }
    }

    return allUpdated;
}

@end

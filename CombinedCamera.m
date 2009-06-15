//
//  CombinedCamera.m
//  Gawker
//
//  Created by Phil Piwonka on 1/4/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "CombinedCamera.h"
#import "CombinedCameraController.h"
#import "PreferenceController.h"
#import "ImageSource.h"
#import "ImageTransitionView.h"
#import "LocalCamera.h"
#import "ScreenCamera.h"
#import "CameraFeaturesWindowController.h"

@interface CombinedCamera (PrivateMethods)
- (NSString *)connectMessage;
- (NSString *)connectErrorMessage;
- (NSString *)connectSuccessMessage;
- (void)cameraControllerUpdatedImageForCell:(CameraController *)aCamController;
- (void)updateWindowTitle:(NSNotification *)note;
@end

@implementation CombinedCamera

- (id)initWithCameras:(NSArray *)cameras
{
    if (self = [super initWithWindowNibName:@"CombinedCamera"]) {
        numberOfCameras = [cameras count];
        NSMutableArray *sources = 
            [NSMutableArray arrayWithCapacity:numberOfCameras];
        Camera *cam = nil;
        NSEnumerator *camEnum = [cameras objectEnumerator];
        camerasAreLocal = YES;
        while (cam = [camEnum nextObject]) {
            if (![cam isKindOfClass:[LocalCamera class]] &&
                ![cam isKindOfClass:[ScreenCamera class]]) {
                camerasAreLocal = NO;
            }
            [sources addObject:[[cam camController] imageSource]];
        }

        if (camerasAreLocal) {
            NSLog(@"All local cameras");
        }
        else {
            NSLog(@"Not all local cameras");
        }

        camController = 
            [[CombinedCameraController alloc] initWithSources:sources
                                              delegate:self];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        // For local camera description updates
        [nc addObserver:self
            selector:@selector(updateWindowTitle:)
            name:@"UpdateShareDescription"
            object:nil];
        // For remote camera description updates
        [nc addObserver:self
            selector:@selector(updateWindowTitle:)
            name:@"DescriptionUpdate"
            object:nil];
        [nc addObserver:self
            selector:@selector(updateWindowTitle:)
            name:@"SourceDisconnect"
            object:nil];
        
        [[self window] setTitle:[camController sourceDescription]];
        icon = [[NSImage imageNamed:@"NSApplicationIcon"] retain];
    }

    return self;
}

- (id)init
{
    NSLog(@"Should not use CombinedCamera -init!");
    return [self initWithCameras:nil];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    CombinedCameraController *combCamController =
        (CombinedCameraController *)camController;
    [imageTransitionView setImage:[combCamController screenImage]];
    if (camerasAreLocal) {
        saveAccessoryViewToUse = localSaveAccessoryView;
        [imageTransitionView setAnimate:NO];
    }
    else {
        saveAccessoryViewToUse = saveAccessoryView;
        [imageTransitionView setAnimate:YES];
    }
    NSRect windowSize = [[self window] frame];
    if (numberOfCameras == 4) {
        windowSize.size.width = 320 * 2;
        windowSize.size.height += 240;
    }
    else {
        windowSize.size.width = 320 * numberOfCameras;
    }

    [self setSourceEnabled:YES];
    [[self window] setFrame:windowSize display:YES];
}

- (void)setSourceEnabled:(BOOL)enable openWindow:(BOOL)open
{
    [super setSourceEnabled:enable openWindow:open];
    if (enable) {
        CombinedCameraController *combCamController =
            (CombinedCameraController *)camController;
        [imageTransitionView setImage:[combCamController screenImage]];
    }
}

- (void)scheduledStart:(NSTimer *)timer
{
    NSDictionary *scheduling = [[[startTimer userInfo] retain] autorelease];
    [super scheduledStart:timer];

    if ([self isRecording] && camerasAreLocal) {
        double interval = [[scheduling objectForKey:SCHIntervalTag] floatValue];
        [(CombinedCameraController *)camController captureFrameAtInterval:interval];        
    }
}

@end

@implementation CombinedCamera (PrivateMethods)

- (NSString *)connectMessage
{
    return [NSString stringWithString:@"Combining cameras..."];
}

- (NSString *)connectErrorMessage
{
    return [NSString stringWithString:@"Error combining cameras"];
}

- (NSString *)connectSuccessMessage
{
    return [NSString stringWithString:@"Cameras successfully combined"];
}


- (void)updateShowTimeToNextFrame:(NSNotification *)note
{
    if (timeToNextFrameField && 
        [camController isRecording] && 
        camerasAreLocal) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [timeToNextFrameField setHidden:![defaults boolForKey:WNKShowTimeToNextFrameKey]];
    }
}

//
// Record panel handlers
//
- (void)recordDidEnd:(NSSavePanel *)sheet
          returnCode:(int)code
         contextInfo:(void *)contextInfo
{
    if (code == NSOKButton) {
		NSLog(@"Will save movie to: %@", [sheet filename]);
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"UpdateCameraTable" object:self];
	}
    else {
        [recordButton setState:NO];
        [previewButton setEnabled:NO];
        return;
    }
    
    if ([camController isRecording]) {
        [camController stopRecording];
    }

    BOOL wasSuccessful = NO;
    if (camerasAreLocal) {
        wasSuccessful =
            [camController startRecordingToFilename:[sheet filename]
                           quality:[localSaveQuality titleOfSelectedItem]
                           scaleFactor:1.0
                           FPS:[localSaveFPS floatValue]
                           putTimeOnImage:[localSaveTime state]
                           timestampFont:[self timestampFont]];
        if (wasSuccessful) {
            double interval = [localSaveFrameInterval floatValue];
            [(CombinedCameraController *)camController captureFrameAtInterval:interval];
            if (timeToNextFrameField) {
                [timeToNextFrameField setStringValue:@""];
                timeToNextFrameTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                                                 target:self
                                                 selector:@selector(updateTimeToNextFrame:)
                                                 userInfo:nil
                                                 repeats:YES] retain];
                [self updateShowTimeToNextFrame:nil];
            }
        }
    }
    else {
        wasSuccessful =
            [camController startRecordingToFilename:[sheet filename]
                           quality:[saveQuality titleOfSelectedItem]
                           scaleFactor:1.0
                           FPS:[saveFPS floatValue]
                           putTimeOnImage:[saveTime state]
                           timestampFont:[self timestampFont]];
    }

    if (wasSuccessful) {
        NSLog(@"Recording has begun");
        [recordButton setTitle:@"Stop"];
        [previewButton setEnabled:YES];
    }
    else {
        NSLog(@"An error occurred while trying to record");
    }
    
    [savePanel release];
    savePanel = nil;
}

- (void)cameraControllerUpdatedImageForCell:(CameraController *)aCamController
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
}
        

- (void)updateWindowTitle:(NSNotification *)note
{
    [[self window] setTitle:[self sourceDescription]];
}

- (void)windowDidLoad
{
    [[self window] setFrameAutosaveName:@"CombinedCamera"];
}

- (void)windowDidMove:(NSNotification *)note
{
    [[self window] saveFrameUsingName:@"CombinedCamera"];
    [super windowDidMove:note];
}

@end

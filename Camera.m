//
//  Camera.m
//  Gawker
//
//  Created by Phil Piwonka on 1/7/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "Camera.h"
#import "CameraController.h"
#import "PreferenceController.h"
#import "LapseMovie.h"

#import "ImageTransitionView.h"
#import "CameraStatusView.h"

#import "CameraFeaturesWindowController.h"

@interface Camera (PrivateMethods)
- (void)registerForNotifications;
- (NSString *)connectMessage;
- (NSString *)connectErrorMessage;
- (NSString *)connectSuccessMessage;
- (BOOL)showErrorButtonOnError;
- (void)updateTimeToNextFrame:(NSTimer *)timer;
- (NSAttributedString *)attribString:(NSString *)string;
- (void)recordDidEnd:(NSSavePanel *)sheet returnCode:(int)code
         contextInfo:(void *)contextInfo;
- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename;
@end

@interface Camera (WindowNotifications)
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidResignKey:(NSNotification *)aNotification;
- (void)windowDidMove:(NSNotification *)aNotification;
@end

@implementation Camera

- (id)init
{
    NSLog(@"Camera -init should not be called");
    return nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (camFeaturesWindow) {
        [camFeaturesWindow close];
        [camFeaturesWindow release];
    }
    [camController setSourceEnabled:NO];
    [camController release];
    [icon release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [camStatusView setStatusImage:[NSImage imageNamed:@"NSApplicationIcon"]];
    [camStatusView setErrorImage:[NSImage imageNamed:@"error.tiff"]];
    [camStatusView setErrorButtonName:@"Retry" target:self action:@selector(setSourceEnabled)];
    [imageTransitionView setAnimate:NO];
    saveAccessoryViewToUse = saveAccessoryView;
    [previewButton setEnabled:NO];
    [movieView setHidden:YES];
    isScheduled = NO;
    isPreviewing = NO;
    nonPreviewSize = [[self window] frame];
    [timeToNextFrameField setHidden:YES];
    [self registerForNotifications];
}

- (BOOL)isSourceEnabled
{
    return [camController isSourceEnabled];
}

- (void)setSourceEnabled
{
    [self setSourceEnabled:YES openWindow:NO];
}

- (void)setSourceEnabled:(BOOL)enable
{
    [self setSourceEnabled:enable openWindow:NO];
}

- (void)setSourceEnabled:(BOOL)enable openWindow:(BOOL)open
{
    if (!enable && ![self isSourceEnabled]) {
        return;
    }

    if (enable && [self isSourceEnabled]) {
        return;
    }

    if (!enable) {
        if (isPreviewing) {
            [self togglePreview:nil];
        }

        if ([camController isRecording]) {
            [self toggleRecord:nil];
        }

        [imageTransitionView setImage:nil];        
    }
    else {
        [recordButton setEnabled:NO];
        [camStatusView showStatusMessage:[self connectMessage] spin:YES];
    }

    if (open) {
        [self showWindow:nil];
    }

    [camController setSourceEnabled:enable];

    if (!enable) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"EnabledStatusChanged" object:self];
    }
}

- (void)showEnableError
{
    [camStatusView showErrorMessage:[self connectErrorMessage]
                   showButton:[self showErrorButtonOnError]];
    NSBeep();
}

- (CameraController *)camController
{
    return camController;
}

- (BOOL)isScheduled
{
    return isScheduled;
}

- (NSImage *)recentImage
{
    NSImage *image = [camController recentImage];
    if (![camController isSourceEnabled] || image == nil) {
        image = icon;
    }
    return image;
}

- (NSString *)sourceDescription
{
    return [camController sourceDescription];
}

- (NSString *)sourceSubDescription
{
    return [camController sourceSubDescription];
}

- (IBAction)toggleRecord:(id)sender
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    if ([sender state]) {
        NSString *defaultDir = [[NSUserDefaults standardUserDefaults]
                                   objectForKey:WNKDefaultRecordDirectoryKey];
        NSLog(@"Beginning Recording.  Default Dir: %@", defaultDir);
        savePanel = [[NSSavePanel savePanel] retain];
        [savePanel setDelegate:self];
        [savePanel setRequiredFileType:@"mov"];
        [savePanel setPrompt:@"Record"];
        [savePanel setAccessoryView:saveAccessoryViewToUse];
        [savePanel beginSheetForDirectory:defaultDir
               file:nil
               modalForWindow:[self window]
               modalDelegate:self
               didEndSelector:@selector(recordDidEnd:returnCode:contextInfo:)
               contextInfo:NULL];        
    }
    else {
        [camController stopRecording];
        [recordButton setState:NSOffState];
        [recordButton setTitle:@"Record"];
        [previewButton setEnabled:NO];
        [previewButton setState:NSOffState];
        [timeToNextFrameField setHidden:YES];
        if (timeToNextFrameTimer) {
            [timeToNextFrameTimer invalidate];
            [timeToNextFrameTimer release];
            timeToNextFrameTimer = nil;
        }
        [nc postNotificationName:@"RecordStatusChanged" object:self];    
    }
    
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
}

- (IBAction)togglePreview:(id)sender
{
    if (![camController isRecording]) {
        NSLog(@"Shouldn't be able to preview while not recording!");
        return;
    }
    
    QTMovie *movie = [camController movie];

    if ([sender state]) {
        // Display preview
        Rect movieRect;
        GetMovieNaturalBoundsRect([movie quickTimeMovie], &movieRect);

        // Save this off since doing preview messes up the 
        // movie's bounding box if the window has to resize.
        GetMovieBox([movie quickTimeMovie], &movieSize);

        NSRect newRect = [movieView bounds];
        newRect.size.height = (movieRect.bottom - movieRect.top) + 
            [movieView movieControllerBounds].size.height;

        NSRect windowSize = [[self window] frame];
        nonPreviewSize = windowSize;

        windowSize.size.height = windowSize.size.height + 
            (newRect.size.height - [imageTransitionView bounds].size.height);

        windowSize.size.width = movieRect.right - movieRect.left;

        isPreviewing = YES;
        [recordButton setEnabled:NO];

        [movieView setMovie:[camController movie]];
        [movieView setHidden:NO];
        [imageTransitionView setHidden:YES];
        [movieView setBounds:newRect];
        [[self window] setFrame:windowSize display:YES animate:YES];
    }
    else {
        isPreviewing = NO;

        // Want to keep current location.
        NSRect currentWindowSize = [[self window] frame];
        nonPreviewSize.origin.x = currentWindowSize.origin.x;
        nonPreviewSize.origin.y = currentWindowSize.origin.y;

        [[self window] setFrame:nonPreviewSize display:YES animate:YES];
        [imageTransitionView setHidden:NO];
        [movieView setHidden:YES];

        [recordButton setEnabled:YES];

        SetMovieBox([movie quickTimeMovie], &movieSize);
    }
}

- (BOOL)isRecording
{
    return [camController isRecording];
}

- (NSFont *)timestampFont
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontString = [defaults objectForKey:WNKDefaultRecordFontKey];
    NSFont *timestampFont = [NSFont fontWithName:fontString 
                                    size:WNK_FONT_SIZE];
    
    if (!timestampFont) {
        timestampFont = [NSFont userFontOfSize:WNK_FONT_SIZE];
    }
    
    return timestampFont;
}

- (void)setScheduledStart:(NSDate *)recStart
            recordOptions:(NSDictionary *)options
{
    startTime = [recStart retain];
    startTimer = [[NSTimer alloc]
                     initWithFireDate:startTime
                     interval:0
                     target:self
                     selector:@selector(scheduledStart:)
                     userInfo:options
                     repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:startTimer
                                forMode:NSDefaultRunLoopMode];
    NSLog(@"scheduled start timer!");
    isScheduled = YES;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"RecordStatusChanged" object:self];    
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
}

- (void)setScheduledStop:(NSDate *)recStop
{
    stopTime = [recStop retain];
    stopTimer = [[NSTimer alloc]
                    initWithFireDate:stopTime
                    interval:0
                    target:self
                    selector:@selector(scheduledStop:)
                    userInfo:nil
                    repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:stopTimer
                                forMode:NSDefaultRunLoopMode];
    NSLog(@"scheduled stop timer!");
    isScheduled = YES;
}

- (void)clearScheduledEvents
{
    [startTime release];
    startTime = nil;
    [startTimer invalidate];
    [startTimer release];
    startTimer = nil;

    [stopTime release];
    stopTime = nil;
    [stopTimer invalidate];
    [stopTimer release];
    stopTimer = nil;

    isScheduled = NO;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"RecordStatusChanged" object:self];    
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
}

- (void)scheduledStart:(NSTimer *)timer
{
    if (timer != startTimer) {
        NSLog(@"Something weird is going on");
    }

    NSLog(@"Record start fired!");
    NSDictionary *scheduling = [[[startTimer userInfo] retain] autorelease];
    NSLog(@"Scheduling info: %@", scheduling);
    
    // Make sure source is enabled.
    [self setSourceEnabled:YES];

    // Make sure it initialized properly.
    // Notifications out will tell us if it didn't.
    if (![self isSourceEnabled]) {
        return;
    }

    if ([camController startRecordingToFilename:[scheduling objectForKey:SCHFilenameTag]
                       quality:[scheduling objectForKey:SCHQualityTag]
                       scaleFactor:[[scheduling objectForKey:SCHFrameScaleTag] floatValue]
                       FPS:[[scheduling objectForKey:SCHFPSTag] floatValue]
                       putTimeOnImage:[[scheduling objectForKey:SCHTimeStampTag] boolValue]
                       timestampFont:[self timestampFont]]) {
        NSLog(@"Recording has begun");
        [recordButton setTitle:@"Stop"];
        [previewButton setEnabled:YES];

        if (!stopTimer) {
            // Done with events.
            isScheduled = NO;
        }
        
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
    [startTimer invalidate];
    [startTimer release];
    startTimer = nil;
    
    [startTime release];
    startTime = nil;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"RecordStatusChanged" object:self];    
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
}

- (void)scheduledStop:(NSTimer *)timer
{
    NSLog(@"Scheduled stop!");
    if (isPreviewing) {
        [self togglePreview:nil];
    }
    if ([camController isRecording]) {
        [self toggleRecord:nil];
    }
    

    isScheduled = NO;

    [stopTimer invalidate];
    [stopTimer release];
	stopTimer = nil;

    [stopTime release];
    stopTime = nil;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"RecordStatusChanged" object:self];    
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
}

- (NSDate *)startTime
{
    return startTime;
}

- (NSDate *)stopTime
{
    return stopTime;
}

- (IBAction)showCameraFeaturesWindow:(id)sender
{
    NSLog(@"show it!");
    if (!camFeaturesWindow) {
        camFeaturesWindow = 
            [[CameraFeaturesWindowController alloc] initWithDelegate:self
                                                    saveView:saveAccessoryViewToUse];
    }

    [camFeaturesWindow showWindow:self];
}

- (void)closeCameraFeaturesWindow
{
    if (camFeaturesWindow) {
        [camFeaturesWindow close];
    }
}

@end

@implementation Camera (DelegateMethods)

- (void)cameraController:(CameraController *)aCamController
             hasNewImage:(NSImage *)anImage
{
    [imageTransitionView setImage:anImage];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
}

- (void)cameraControllerDisconnected:(CameraController *)controller
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [self showEnableError];
    [recordButton setEnabled:NO];
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
    [nc postNotificationName:@"EnabledStatusChanged" object:self];
}

- (void)cameraControllerConnected:(CameraController *)controller
{
    [camStatusView showStatusMessage:[self connectSuccessMessage]];
    [camStatusView fadeOutAfterWaiting:0.5];
    [recordButton setEnabled:YES];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
    [nc postNotificationName:@"EnabledStatusChanged" object:self];
}

@end

@implementation Camera (PrivateMethods)

- (void)registerForNotifications
{
    if (timeToNextFrameField) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
            selector:@selector(updateShowTimeToNextFrame:)
            name:@"UpdateShowTimeToNextFrame"
            object:nil];
    }
}

- (NSString *)connectMessage
{
    return [NSString stringWithString:@"Connecting to Camera..."];
}

- (NSString *)connectErrorMessage
{
    return [NSString stringWithString:@"Could not connect to Camera!  Ensure it's not already in use."];
}

- (NSString *)connectSuccessMessage
{
    return [NSString stringWithString:@"Connected to camera"];
}

- (BOOL)showErrorButtonOnError
{
    return YES;
}

- (void)updateShowTimeToNextFrame:(NSNotification *)note
{
    if (timeToNextFrameField && [camController isRecording]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [timeToNextFrameField setHidden:![defaults boolForKey:WNKShowTimeToNextFrameKey]];
    }
}

- (void)updateTimeToNextFrame:(NSTimer *)timer
{
    NSDate *fireDate = [camController nextFrameTime];
    if (fireDate && timeToNextFrameField) {
        NSString *timeLeftString = 
            [NSString stringWithFormat:@"Next frame in %d seconds",
                      ((int)[fireDate timeIntervalSinceNow])+1];
        
        [timeToNextFrameField setAttributedStringValue:[self attribString:timeLeftString]];
    }
}

- (NSAttributedString *)attribString:(NSString *)string
{
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc]
                                               initWithString:string];
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize(1.1, -1.1)];
    [shadow setShadowBlurRadius:0.3];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0
                                    alpha:0.8]];
    NSRange range = NSMakeRange(0, [attString length]);
    [attString addAttribute:NSShadowAttributeName value:shadow
                  range:range];
    [attString setAlignment:NSRightTextAlignment range:range];
    [shadow release];
    
    return [attString autorelease];
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
    
    double frameScale = 1.0 / ([saveSize indexOfSelectedItem] + 1.0);

    if ([camController isRecording]) {
        [camController stopRecording];
    }

    if ([camController startRecordingToFilename:[sheet filename]
                       quality:[saveQuality titleOfSelectedItem]
                       scaleFactor:frameScale
                       FPS:[saveFPS floatValue]
                       putTimeOnImage:[saveTime state]
                       timestampFont:[self timestampFont]]) {
        NSLog(@"Recording has begun");
        [recordButton setTitle:@"Stop"];
        [previewButton setEnabled:YES];
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
    else {
        NSLog(@"An error occurred while trying to record");
    }
    
    [savePanel release];
    savePanel = nil;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"RecordStatusChanged" object:self];    
}

- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename
{
    NSLog(@"Validating: %s", [filename fileSystemRepresentation]);
    return [filename isAbsolutePath];
}

@end

@implementation Camera (WindowNotifications)

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    [camStatusView setNeedsDisplay:YES];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
    [camStatusView setNeedsDisplay:YES];
}

- (void)windowDidMove:(NSNotification *)aNotification
{
    [camStatusView setNeedsDisplay:YES];
}

@end

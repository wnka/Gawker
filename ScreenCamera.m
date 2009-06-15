//
//  ScreenCamera.m
//  Gawker
//
//  Created by phil piwonka on 3/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ScreenCamera.h"
#import "ScreenCameraController.h"
#import "ImageTransitionView.h"

@implementation ScreenCamera

- (id)init
{
    self = [super initWithWindowNibName:@"ScreenCamera"];

    if (self) {
        camController = [[ScreenCameraController alloc] initWithDelegate:self];
        if (camController) {
            [[self window] setTitle:[camController sourceDescription]];
            icon = [[NSImage imageNamed:@"NSApplicationIcon"] retain];
            recentImage = [[NSImage imageNamed:@"window_nib.tiff"] retain];
        }
    }

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [imageTransitionView setAnimate:NO];
    [imageTransitionView setImage:[NSImage imageNamed:@"desktop.png"]];
}

- (void)setSourceEnabled:(BOOL)enable openWindow:(BOOL)open
{
    [super setSourceEnabled:enable openWindow:open];
    [imageTransitionView setImage:[NSImage imageNamed:@"desktop.png"]];
}
- (void)showEnableError
{
    NSBeep();
    NSRunAlertPanel(@"Error Enabling Screen Capture",
                    @"Something must be really wrong!",
                    @"OK", nil, nil);
}

- (NSImage *)recentImage
{
    NSImage *image = icon;

    if ([self isSourceEnabled]) {
        image = recentImage;
    }

    return image;
}

//
// Record panel handlers
//
- (void)recordDidEnd:(NSSavePanel *)sheet
          returnCode:(int)code
         contextInfo:(void *)contextInfo
{
    [super recordDidEnd:sheet
           returnCode:code
           contextInfo:contextInfo];

    if ([camController isRecording]) {
        double interval = [saveFrameInterval floatValue];
        [(ScreenCameraController *)camController captureFrameAtInterval:interval];
    }
}

- (void)windowDidLoad
{
    [[self window] setFrameAutosaveName:@"ScreenCamera"];
}

- (void)windowDidMove:(NSNotification *)note
{
    [[self window] saveFrameUsingName:@"ScreenCamera"];
    int screenNum = [[NSScreen screens] indexOfObject:[[self window] screen]];
    [(ScreenCameraController *)camController setScreenToGrab:screenNum];
    [super windowDidMove:note];
}

- (IBAction)showWindow:(id)sender
{
    [super showWindow:sender];
    int screenNum = [[NSScreen screens] indexOfObject:[[self window] screen]];
    [(ScreenCameraController *)camController setScreenToGrab:screenNum];
}

@end

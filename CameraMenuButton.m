//
//  CameraMenuButton.m
//  Gawker
//
//  Created by Phil Piwonka on 10/2/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "CameraMenuButton.h"


@implementation CameraMenuButton

- (id)init
{
    if (self = [super init]) {
        cameraMenu = nil;
    }
    return self;
}

- (NSMenu *)cameraMenu
{
    return cameraMenu;
}

- (void)setCameraMenu:(NSMenu *)menu
{
    [menu retain];
    [cameraMenu release];
    cameraMenu = menu;
}

- (void)mouseDown:(NSEvent *)anEvent
{
    if ([self isEnabled] && cameraMenu) {
        [self highlight:YES];
        NSPoint menuOrigin = NSMakePoint([self frame].origin.x,
                                         [self frame].origin.y);
        NSEvent *event = [NSEvent mouseEventWithType:[anEvent type]
                                  location:menuOrigin
                                  modifierFlags:[anEvent modifierFlags]
                                  timestamp:[anEvent timestamp]
                                  windowNumber:[anEvent windowNumber]
                                  context:[anEvent context]
                                  eventNumber:[anEvent eventNumber]
                                  clickCount:[anEvent clickCount]
                                  pressure:[anEvent pressure]];
        [NSMenu popUpContextMenu:cameraMenu withEvent:event forView:self];
        [self highlight:NO];
    }
}

- (void)mouseUp:(NSEvent *)anEvent
{
    if([self isEnabled]) {
        [self highlight:NO];
    }
}

- (void)dealloc
{
    [cameraMenu release];
    [super dealloc];
}

@end

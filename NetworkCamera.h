//
//  NetworkCamera.h
//  Gawker
//
//  Created by Phil Piwonka on 7/30/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Camera.h"

@class CameraController;
@class QTMovieView;

@interface NetworkCamera : Camera {
    NSString *ipAddress;
    int remotePort;

    IBOutlet NSWindow *passwordWindow;
    IBOutlet NSTextField *passwordFromUser;
    IBOutlet NSTextField *passwordHeader;
    IBOutlet NSImageView *passwordIcon;

    // This flag is used to display error messages,
    // if you have connected then you've been disconnected
    // otherwise you've failed to connect.
    BOOL hasConnected;
}

- (id)initWithIp:(NSString *)address port:(UInt16)port;
- (id)init;
- (void)dealloc;

- (IBAction)passwordOk:(id)sender;
- (IBAction)passwordCancel:(id)sender;

@end

@interface NetworkCamera (DelegateMethods)

- (void)cameraControllerNewDescription:(CameraController *)controller;
- (void)cameraControllerNeedsPassword:(CameraController *)controller;

@end


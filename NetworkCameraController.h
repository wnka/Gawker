//
//  NetworkCameraController.h
//  Gawker
//
//  Created by Phil Piwonka on 10/10/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CameraController.h"

@interface NetworkCameraController : CameraController {
}

- (id)initWithIp:(NSString *)ip port:(int)port delegate:(id)theDelegate;
- (id)init;

@end

@interface NetworkCameraController (DelegateMethods)
- (void)cameraControllerNewDescription:(CameraController *)controller;
- (void)cameraControllerNeedsPassword:(CameraController *)controller;
@end

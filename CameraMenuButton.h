//
//  CameraMenuButton.h
//  Gawker
//
//  Created by Phil Piwonka on 10/2/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CameraMenuButton : NSButton {
    NSMenu *cameraMenu;
}

- (NSMenu *)cameraMenu;
- (void)setCameraMenu:(NSMenu *)menu;

@end

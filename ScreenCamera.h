//
//  ScreenCamera.h
//  Gawker
//
//  Created by phil piwonka on 3/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Camera.h"

@interface ScreenCamera : Camera {
    NSImage *recentImage;
    IBOutlet NSTextField *saveFrameInterval;
}

@end

//
//  CombinedCameraLocalComponent.h
//  Gawker
//
//  Created by phil piwonka on 2/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CombinedCameraComponent.h"
#import "CameraImageSource.h"

@interface CombinedCameraLocalComponent : NSObject <CombinedCameraComponent> {
    CameraImageSource *imageSource;
}

- (id)initWithSource:(CameraImageSource *)source;

- (id<ImageSource>)imageSource;
- (NSImage *)screenImage;
- (NSImage *)thumbnail;
- (NSImage *)image;
- (NSString *)timeStamp;
- (BOOL)isNew;
- (void)clearNew;
- (void)update;

@end

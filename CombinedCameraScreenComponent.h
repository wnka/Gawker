//
//  CombinedCameraScreenComponent.h
//  Gawker
//
//  Created by phil piwonka on 5/12/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CombinedCameraComponent.h"
#import "ScreenImageSource.h"

@interface CombinedCameraScreenComponent : NSObject <CombinedCameraComponent> {
    ScreenImageSource *imageSource;
    NSImage *thumbnail;
    NSImage *screenImage;
}

- (id)initWithSource:(ScreenImageSource *)source;

- (id<ImageSource>)imageSource;
- (NSImage *)screenImage;
- (NSImage *)thumbnail;
- (NSImage *)image;
- (NSString *)timeStamp;
- (BOOL)isNew;
- (void)clearNew;
- (void)update;

@end

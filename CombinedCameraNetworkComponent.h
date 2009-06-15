//
//  CombinedCameraNetworkComponent.h
//  Gawker
//
//  Created by phil piwonka on 2/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CombinedCameraComponent.h"
#import "NetworkImageSource.h"

@interface CombinedCameraNetworkComponent : NSObject <CombinedCameraComponent> {
    NetworkImageSource *imageSource;
    NSImage *image;
    NSString *timeStamp;
    BOOL isNewFlag;
}

- (id)initWithSource:(NetworkImageSource *)source;

- (id<ImageSource>)imageSource;
- (NSImage *)screenImage;
- (NSImage *)thumbnail;
- (NSImage *)image;
- (NSString *)timeStamp;
- (BOOL)isNew;
- (void)clearNew;
- (void)update;

@end

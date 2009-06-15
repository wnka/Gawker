//
//  CombinedCameraComponent.h
//  Gawker
//
//  Created by phil piwonka on 2/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageSource.h"

@protocol CombinedCameraComponent <NSObject> 
- (id<ImageSource>)imageSource;
- (NSImage *)screenImage;
- (NSImage *)thumbnail;
- (NSImage *)image;
- (NSString *)timeStamp;
- (BOOL)isNew;
- (void)clearNew;
- (void)update;
@end

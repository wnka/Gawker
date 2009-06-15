//
//  CombinedCameraNetworkComponent.m
//  Gawker
//
//  Created by phil piwonka on 2/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "CombinedCameraNetworkComponent.h"


@implementation CombinedCameraNetworkComponent
- (id)initWithSource:(NetworkImageSource *)source
{
    if (self = [super init]) {
        imageSource = [source retain];
        image = [[source recentImage] retain];
        timeStamp = [[source recentTime] retain];
        isNewFlag = YES;
    }

    return self;
}

- (void)dealloc
{
    [imageSource release];
    [image release];
    [timeStamp release];
    [super dealloc];
}

- (id<ImageSource>)imageSource
{
    return imageSource;
}

- (NSImage *)screenImage
{
    return [self image];
}

- (NSImage *)thumbnail
{
    return [self image];
}

- (NSImage *)image
{
    return image;
}

- (NSString *)timeStamp
{
    return timeStamp;
}

- (BOOL)isNew
{
    return isNewFlag;
}

- (void)clearNew
{
    isNewFlag = NO;
}

- (void)update
{
    if ([imageSource recentImage] != image) {
        NSImage *newImage = [[imageSource recentImage] retain];
        [image release];
        image = newImage;
        NSString *newTime = [[imageSource recentTime] retain];
        [timeStamp release];
        timeStamp = newTime;
        isNewFlag = YES;
    }
}

- (BOOL)isEqual:(id)anObject
{
    return (anObject == imageSource);
}

@end

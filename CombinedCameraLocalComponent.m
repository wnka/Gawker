//
//  CombinedCameraLocalComponent.m
//  Gawker
//
//  Created by phil piwonka on 2/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "CombinedCameraLocalComponent.h"


@implementation CombinedCameraLocalComponent

- (id)initWithSource:(CameraImageSource *)source
{
    if (self = [super init]) {
        imageSource = [source retain];
    }

    return self;
}

- (void)dealloc
{
    [imageSource release];
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
    return [imageSource recentImage];
}

- (NSString *)timeStamp
{
    return [imageSource recentTime];
}

- (BOOL)isNew
{
    return YES;
}

- (void)clearNew
{}


- (void)update
{}

- (BOOL)isEqual:(id)anObject
{
    return (anObject == imageSource);
}

@end

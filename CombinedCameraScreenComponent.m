//
//  CombinedCameraScreenComponent.m
//  Gawker
//
//  Created by phil piwonka on 5/12/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "CombinedCameraScreenComponent.h"


@implementation CombinedCameraScreenComponent

- (id)initWithSource:(ScreenImageSource *)source
{
    if (self = [super init]) {
        imageSource = [source retain];
        thumbnail = [[NSImage imageNamed:@"window_nib.tiff"] retain];
        screenImage = [[NSImage imageNamed:@"desktop.png"] retain];
    }

    return self;
}

- (void)dealloc
{
    [imageSource release];
    [thumbnail release];
    [screenImage release];
    [super dealloc];
}

- (id<ImageSource>)imageSource
{
    return imageSource;
}

- (NSImage *)screenImage
{
    return screenImage;
}

- (NSImage *)thumbnail
{
    return thumbnail;
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

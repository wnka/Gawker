//
//  ImageTransitionView.h
//  Gawker
//
//  Created by phil piwonka on 6/11/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImageTransitionView : NSView {
	int imageViewIndex;
    BOOL animate;

    NSArray *imageViews;
    BOOL acceptUpdates;
}

- (void)setImage:(NSImage *)image;

- (BOOL)animate;
- (void)setAnimate:(BOOL)anim;

- (NSImage *)currentImage;

- (void)setAcceptUpdates:(BOOL)update;

@end

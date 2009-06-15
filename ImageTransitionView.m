//
//  ImageTransitionView.m
//  Gawker
//
//  Created by phil piwonka on 5/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ImageTransitionView.h"

@implementation ImageTransitionView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        acceptUpdates = YES;
        [self setAnimate:NO];
		[self setBounds:frame];

        NSImageView *blackBackground = [[NSImageView alloc] initWithFrame:frame];
        [blackBackground setImageScaling:NSScaleToFit];

        // Create a black image
        NSSize blackSize;
        blackSize.width = 16;
        blackSize.height = 16;
        NSImage *black = [[NSImage alloc] initWithSize:blackSize];
        [black lockFocus];
        
        NSRect blackRect = NSMakeRect(0,0,blackSize.width,blackSize.height);
        [[NSColor blackColor] set];
        [NSBezierPath fillRect:blackRect];
        [black unlockFocus];

        [blackBackground setImage:black];
        [black release];

        [self addSubview:blackBackground];

        NSImageView *imageViewOne = [[NSImageView alloc] initWithFrame:frame];
        [imageViewOne setImageScaling:NSScaleProportionally];
        NSImageView *imageViewTwo = [[NSImageView alloc] initWithFrame:frame];
        [imageViewTwo setImageScaling:NSScaleProportionally];
		[self addSubview:imageViewOne];
		[self addSubview:imageViewTwo];

        imageViews = [[NSArray arrayWithObjects:imageViewOne, imageViewTwo, nil] retain];

		imageViewIndex = [imageViews indexOfObject:imageViewTwo];
		[imageViewOne release];
		[imageViewTwo release];
		
    }
    return self;
}

- (void)dealloc
{
    [imageViews release];
    [super dealloc];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	[super resizeSubviewsWithOldSize:oldBoundsSize];
}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];
	[[imageViews objectAtIndex:imageViewIndex] setFrame:rect];
}

- (void)setImage:(NSImage *)image
{
    if (!acceptUpdates) {
        return;
    }

    if (!animate || [self isHidden]) {
        NSImageView *currentView = [imageViews objectAtIndex:imageViewIndex];
        [currentView setImage:image];
        return;
    }

    int numImageViews = [imageViews count];

    int oldImageView = imageViewIndex;

	imageViewIndex = (imageViewIndex+1) % numImageViews;
	NSImageView *inView = [imageViews objectAtIndex:imageViewIndex];
	[inView setImage:image];
	[inView setFrame:[self frame]];
    NSImageView *outView = [imageViews objectAtIndex:oldImageView];

	[outView setFrame:[self frame]];
		
	[inView setHidden:NO];
	[outView setHidden:NO];

    NSViewAnimation *theAnim;
    NSRect outFrame = [outView frame];
    NSRect inFrame = [inView frame];
    NSMutableDictionary *theDict = [NSMutableDictionary
                                       dictionaryWithCapacity:3];
    [theDict setObject:outView forKey:NSViewAnimationTargetKey];
    [theDict setObject:NSViewAnimationFadeOutEffect
             forKey:NSViewAnimationEffectKey];
    [theDict setObject:[NSValue valueWithRect:outFrame]
             forKey:NSViewAnimationEndFrameKey];
    
    NSMutableDictionary *theOtherDict = [NSMutableDictionary
                                            dictionaryWithCapacity:1];
    [theOtherDict setObject:inView
                  forKey:NSViewAnimationTargetKey];
    [theOtherDict setObject:NSViewAnimationFadeInEffect
                  forKey:NSViewAnimationEffectKey];
    [theOtherDict setObject:[NSValue valueWithRect:inFrame]
                  forKey:NSViewAnimationEndFrameKey];
    theAnim = [[NSViewAnimation alloc]
                  initWithViewAnimations:[NSArray arrayWithObjects:theDict, theOtherDict, nil]];
    [theAnim setDelegate:self];
    [theAnim setDuration:0.2];
    [theAnim startAnimation];
}

- (BOOL)animate
{
    return animate;
}

- (void)setAnimate:(BOOL)anim
{
    animate = anim;
}

- (void)animationDidEnd:(NSAnimation*)animation
{
    [animation release];
}

- (NSImage *)currentImage
{
	return [[imageViews objectAtIndex:imageViewIndex] image];
}

- (void)setAcceptUpdates:(BOOL)update
{
    acceptUpdates = update;
}

@end

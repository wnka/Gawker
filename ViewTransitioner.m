//
//  ViewTransitioner.m
//  Gawker
//
//  Created by Phil Piwonka on 1/25/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "ViewTransitioner.h"


@implementation ViewTransitioner

+ (void)transitionFromView:(NSView *)outView toView:(NSView *)inView
                  duration:(float)duration blocking:(BOOL)shouldBlock
{
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
    if (shouldBlock) {
        [theAnim setAnimationBlockingMode:NSAnimationBlocking];
    }
    [theAnim setDuration:duration];
    [theAnim startAnimation];
    [theAnim release];
}

@end

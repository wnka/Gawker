//
//  ViewTransitioner.h
//  Gawker
//
//  Created by Phil Piwonka on 1/25/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ViewTransitioner : NSObject {
    
}

+ (void)transitionFromView:(NSView *)outView toView:(NSView *)inView
                  duration:(float)duration blocking:(BOOL)shouldBlock;

@end

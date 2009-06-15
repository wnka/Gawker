//
//  CameraView.m
//  Gawker
//
//  Created by Phil Piwonka on 8/21/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "CameraView.h"


@implementation CameraView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSLog(@"CameraView mousedown!");
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"LocalMouseDown" object:self];
}

@end

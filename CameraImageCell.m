//
//  CameraImageCell.m
//  Gawker
//
//  Created by Phil Piwonka on 9/4/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "CameraImageCell.h"


@implementation CameraImageCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    const float cellBoundary = 1.0;

    cellFrame.origin.x += cellBoundary;
    cellFrame.origin.y += cellBoundary;
    cellFrame.size.width -= 2 * cellBoundary;
    cellFrame.size.height -= 3 * cellBoundary;

    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end

//
//  CameraStatusView.m
//  Gawker
//
//  Created by phil piwonka on 6/11/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "CameraStatusView.h"
#import "CameraStatusButton.h"

@interface CameraStatusView (PrivateMethods)

- (void)positionElements:(NSRect)frame;
- (NSAttributedString *)statusText:(NSString *)newString;
- (void)animationDidEnd:(NSAnimation*)animation;

@end

@implementation CameraStatusView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        statusImageView = [[NSImageView alloc] initWithFrame:frame];

        // error button is optional, let the user set it
        errorButton = nil;

        spinner = [[NSProgressIndicator alloc] init];
        [spinner setBezeled:NO];
        [spinner setStyle:NSProgressIndicatorSpinningStyle];

        statusTextField = [[NSTextField alloc] initWithFrame:frame];
        [statusTextField setEditable:NO];
        [statusTextField setDrawsBackground:NO];
        [statusTextField setBordered:NO];

        [self addSubview:statusImageView];
        [self addSubview:spinner];
        [self addSubview:statusTextField];

        [statusImageView release];
        [spinner release];
        [statusTextField release];        
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self positionElements:[self frame]];
}

- (void)dealloc
{
    [statusImage release];
    [errorImage release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect {
    NSColor *bgColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.8];

    [self positionElements:rect];

    int minX = NSMinX(contentRect);
    int midX = NSMidX(contentRect);
    int maxX = NSMaxX(contentRect);
    int minY = NSMinY(contentRect);
    int midY = NSMidY(contentRect);
    int maxY = NSMaxY(contentRect);

    static const float radius = 10.0;

    NSShadow *frameShadow = [[NSShadow alloc] init];
    [frameShadow setShadowOffset:NSMakeSize(1.1, -1.1)];
    [frameShadow setShadowBlurRadius:10.0];
    [frameShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0
                                         alpha:0.5]];
    [frameShadow set];
    NSBezierPath *bgPath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    
    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:radius];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:contentRect.origin 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];
    
    [bgColor set];
    [bgPath fill];

    [frameShadow release];

    [super drawRect:rect];
}

- (void)showStatusMessage:(NSString *)newString spin:(BOOL)spin
{
    [statusImageView setImage:statusImage];

    if (errorButton) {
        [errorButton setHidden:YES];
    }

    [spinner setHidden:!spin];

    if (spin) {
        [spinner startAnimation:nil];
    }
    else {
        [spinner stopAnimation:nil];
    }

    [self setHidden:NO];

    [statusTextField setAttributedStringValue:[self statusText:newString]];
    [self setNeedsDisplay:YES];
}

- (void)showStatusMessage:(NSString *)newString
{
    [self showStatusMessage:newString spin:NO];
}

- (void)showErrorMessage:(NSString *)errString
{
    [self showErrorMessage:errString showButton:YES];
}

- (void)showErrorMessage:(NSString *)errString showButton:(BOOL)showButton
{
    [statusImageView setImage:errorImage];

    [spinner setHidden:YES];
    [spinner stopAnimation:nil];

    [self setHidden:NO];

    if (errorButton) {
        [errorButton setHidden:!showButton];
    }

    [statusTextField setAttributedStringValue:[self statusText:errString]];
    [self setNeedsDisplay:YES];
}

- (void)setErrorButtonName:(NSString *)buttonTitle target:(id)target action:(SEL)selector
{
    // We can only do this once.  For now at least.
    if (errorButton) {
        return;
    }

    if (![target respondsToSelector:selector]) {
        NSLog(@"Target does not respond to specified action!");
        return;
    }
    
    errorButton = [[CameraStatusButton alloc] initWithFrame:[self frame]];
    [self addSubview:errorButton];
    [errorButton setTarget:target];
    [errorButton setAction:selector];

    [errorButton setBezelStyle:NSRoundedBezelStyle];
    [errorButton setButtonType:NSMomentaryLightButton];
    [[errorButton cell] setControlSize:NSSmallControlSize];

    [errorButton setTitle:buttonTitle];
    [errorButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:[[errorButton cell] controlSize]]]];

    [self positionElements:[self frame]];
}

- (void)fadeOutAfterWaiting:(NSTimeInterval)secs
{
    [spinner stopAnimation:nil];
    [spinner setHidden:YES];
    [NSTimer scheduledTimerWithTimeInterval:secs
             target:self
             selector:@selector(fadeOut:)
             userInfo:nil
             repeats:NO];
}

- (void)fadeOut:(NSTimer *)timer
{
    NSViewAnimation *outAnim;
    NSMutableDictionary *animDict = 
        [NSMutableDictionary dictionaryWithCapacity:2];
    [animDict setObject:self forKey:NSViewAnimationTargetKey];
    [animDict setObject:NSViewAnimationFadeOutEffect
              forKey:NSViewAnimationEffectKey];
    outAnim = [[NSViewAnimation alloc]
                  initWithViewAnimations:[NSArray arrayWithObjects:animDict,nil]];
    [outAnim setDelegate:self];
    [outAnim setDuration:1.0];
    [outAnim startAnimation];
}

- (void)setStatusImage:(NSImage *)image
{
    [image retain];
    [statusImage release];
    statusImage = image;
}

- (void)setErrorImage:(NSImage *)image
{
    [image retain];
    [errorImage release];
    errorImage = image;
}

@end

@implementation CameraStatusView (PrivateMethods)

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self positionElements:frame];
}

- (void)positionElements:(NSRect)frame
{
    static const float contentHeight = 76.0;
    static const float widthFrame = 10.0; // 10 pixels on each side
    static const float heightFrame = 10.0; // 10 pixels on top and bottom
    static const float iconSize = 32.0; // use 32 x 32 icon

    contentRect = frame;
    contentRect.origin.y = frame.size.height - contentHeight;
    contentRect.size.height = contentHeight;
    
    // Have some space around the box
    contentRect.size.width -= 2 * widthFrame;
    contentRect.origin.x += widthFrame;
    contentRect.size.height -= 2 * heightFrame;
    contentRect.origin.y += heightFrame;
    
    NSRect imageRect;
    imageRect.size.height = iconSize;
    imageRect.size.width = iconSize;
    imageRect.origin.x = contentRect.origin.x + widthFrame + 16;
    imageRect.origin.y = floor(contentRect.origin.y + heightFrame + (contentRect.size.height - (2 * heightFrame) - iconSize) / 2);
    [statusImageView setFrame:imageRect];

    NSRect spinnerRect;
    spinnerRect.size.height = 16;
    spinnerRect.size.width = 16;
    spinnerRect.origin.x = contentRect.origin.x + contentRect.size.width - widthFrame - 16 - 16.0;
    spinnerRect.origin.y = floor(contentRect.origin.y + heightFrame + (contentRect.size.height - (2 * heightFrame) - 16.0) / 2);
    [spinner setFrame:spinnerRect];

    NSRect textRect;
    textRect.size.height = 14;
    textRect.size.width = spinnerRect.origin.x - (imageRect.origin.x + 20 + iconSize);
    textRect.origin.x = imageRect.origin.x + iconSize + 20;
    textRect.origin.y = floor(contentRect.origin.y + contentRect.size.height/2 + heightFrame - textRect.size.height - 2.0);
    [statusTextField setFrame:textRect];

    if (errorButton) {
        NSRect buttonRect = spinnerRect;
        buttonRect.origin.x -= 36;
        buttonRect.origin.y = buttonRect.origin.y - 7.0;
        buttonRect.size.height = 27;
        buttonRect.size.width = 63;
        [errorButton setFrame:buttonRect];
    }
    
}

- (NSAttributedString *)statusText:(NSString *)newString
{
    NSMutableAttributedString *string = 
        [[NSMutableAttributedString alloc] initWithString:newString];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize(1.1, -1.1)];
    [shadow setShadowBlurRadius:2.0];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0
                                    alpha:1.0]];
    
    NSRange range = NSMakeRange(0, [string length]);
    [string addAttribute:NSFontAttributeName 
            value:[NSFont systemFontOfSize:11.0]
            range:range];
    [string addAttribute:NSShadowAttributeName value:shadow range:range];

    [shadow release];

    return [string autorelease];
}

- (void)animationDidEnd:(NSAnimation*)animation
{
    [animation release];
}

@end

//
//  CameraStatusView.h
//  Gawker
//
//  Created by phil piwonka on 6/11/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CameraStatusView : NSView {
    NSTextField *statusTextField;
    NSImageView *statusImageView;
    NSProgressIndicator *spinner;    

    NSButton *errorButton;

    NSImage *statusImage;
    NSImage *errorImage;

    NSRect contentRect;

    BOOL isAnimating;
}

- (void)showStatusMessage:(NSString *)newString spin:(BOOL)spin;
- (void)showStatusMessage:(NSString *)newString;
- (void)showErrorMessage:(NSString *)errString;
- (void)showErrorMessage:(NSString *)errString showButton:(BOOL)showButton;
- (void)fadeOutAfterWaiting:(NSTimeInterval)secs;
- (void)fadeOut:(NSTimer *)timer;

- (void)setStatusImage:(NSImage *)image;
- (void)setErrorImage:(NSImage *)image;
- (void)setErrorButtonName:(NSString *)buttonTitle target:(id)target action:(SEL)selector;
@end

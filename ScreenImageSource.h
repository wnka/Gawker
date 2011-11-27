//
//  ScreenImageSource.h
//  Gawker
//
//  Created by phil piwonka on 3/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import "ImageSource.h"

@interface ScreenImageSource : NSObject <ImageSource> {
    BOOL isEnabled;

    NSTimeZone *timeZone;
    
    NSImage *recentImage;
    NSString *recentTime;
    
    NSString *sourceDescription;
    NSString *sourceSubDescription;

    NSScreen *screen;
}

- (BOOL)start;
- (BOOL)stop;

- (BOOL)isEnabled;
- (BOOL)setEnabled:(BOOL)state;

- (NSString *)sourceDescription;
- (void)setSourceDescription:(NSString *)newDesc;

- (NSString *)sourceSubDescription;
- (void)setSourceSubDescription:(NSString *)newDesc;

- (NSImage *)recentImage;
- (NSString *)recentTime;

- (void)setScreenToGrab:(int)screenNum;

@end

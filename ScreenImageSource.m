//
//  ScreenImageSource.m
//  Gawker
//
//  Created by phil piwonka on 3/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ScreenImageSource.h"
#import "ImageText.h"

static inline void swapcopy32(void * src, void * dst, int bytecount);
static void swizzleBitmap(NSBitmapImageRep * bitmap);

@interface ScreenImageSource (PrivateMethods)
- (BOOL)setupGLForScreenNumber:(int)screenNum;
- (NSImage *)captureFrame;
- (void)setRecentImage:(NSImage *)newImage;
@end

@implementation ScreenImageSource
- (id)init
{
    if (self = [super init]) {
        int initialScreen = 0;
        isEnabled = NO;
        timeZone = [[NSTimeZone localTimeZone] retain];
        recentImage = nil;
        
        [self setSourceDescription:NSFullUserName()];
        [self setSourceSubDescription:@"My Desktop"];
        
        if (![self setupGLForScreenNumber:initialScreen]) {
            NSLog(@"Error setting up screen grabbing");
            [self autorelease];
            return nil;
        }
    }

    return self;
}

- (void)dealloc
{
    [self stop];

    [timeZone release];

    [recentImage release];
    [recentTime release];

    [sourceDescription release];
    [sourceSubDescription release];

    [super dealloc];
}

- (BOOL)start
{
    if (isEnabled) {
        // already enabled
        return YES;
    }

    isEnabled = YES;
    [self setRecentImage:[self captureFrame]];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"SourceConnect"
        object:self
        userInfo:nil];            
    return YES;
}

- (BOOL)stop;
{
    isEnabled = NO;
    // stop a timer here
    return YES;
}

- (BOOL)isEnabled
{
    return isEnabled;
}

- (BOOL)setEnabled:(BOOL)state
{
    BOOL success;
    if (state) {
        success = [self start];
    }
    else {
        success = [self stop];
    }
    return success;
}

- (NSString *)sourceDescription
{
    return sourceDescription;
}

- (void)setSourceDescription:(NSString *)newDesc
{
    [newDesc retain];
    [sourceDescription release];
    sourceDescription = newDesc;
}

- (NSString *)sourceSubDescription
{
    return sourceSubDescription;
}

- (void)setSourceSubDescription:(NSString *)newDesc
{
    [newDesc retain];
    [sourceSubDescription release];
    sourceSubDescription = newDesc;
}

- (NSImage *)recentImage
{
    NSImage *image = nil;
    if (isEnabled) {
        [self setRecentImage:[self captureFrame]];
        image = recentImage;
    }
    return image;
}

- (NSString *)recentTime
{
    return recentTime;
}

- (void)setScreenToGrab:(int)screenNum
{
    if (screenNum != [[NSScreen screens] indexOfObject:screen]) {
        NSLog(@"Need to update which screen to grab from.");
        [self setupGLForScreenNumber:screenNum];
    }
}

@end

@implementation ScreenImageSource (PrivateMethods)

- (BOOL)setupGLForScreenNumber:(int)screenNum
{
    if (screen) {
        [screen release];
    }
    screen = [[[NSScreen screens] objectAtIndex:screenNum] retain];
    
    return YES;
}

- (NSImage *)captureFrame
{        
    NSRect scaledRect = NSMakeRect(0, 0, 640, 480);

    NSDictionary* screenDictionary = [screen deviceDescription];
    NSNumber* screenID = [screenDictionary objectForKey:@"NSScreenNumber"];
    CGDirectDisplayID aID = [screenID unsignedIntValue];   
    // make a snapshot of the current display
    
    CGImageRef image = CGDisplayCreateImage(aID);    
    NSImage* newImage = [[[NSImage alloc] initWithCGImage:image size:scaledRect.size] autorelease];	
    CGImageRelease(image);
    
    return newImage;
}

- (void)setRecentImage:(NSImage *)newImage
{
    [newImage retain];
    [recentImage release];
    recentImage = newImage;
    [recentTime release];
    recentTime = [[ImageText timeString:timeZone] retain];
}

@end

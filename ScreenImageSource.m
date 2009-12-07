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
        
        screenUpdateLock = [[NSLock alloc] init];

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

    if (bitmap) {
        [bitmap release];
    }
    CGLSetCurrentContext( NULL ) ;
    CGLClearDrawable( glContextObj ) ;
    CGLDestroyContext( glContextObj ) ;

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
        [screenUpdateLock lock];
        [self setupGLForScreenNumber:screenNum];
        [screenUpdateLock unlock];
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
    
    CGLPixelFormatObj pixelFormatObj;
    long numPixelFormats;
    NSNumber *screenID = 
        [[screen deviceDescription] objectForKey:@"NSScreenNumber"];
    
    CGDirectDisplayID displayToUse;
    
    if (!screenID) {
        displayToUse = CGMainDisplayID();
    }
    else {
        displayToUse = (CGDirectDisplayID)[screenID pointerValue];
    }
    
    CGOpenGLDisplayMask displayMask =
        CGDisplayIDToOpenGLDisplayMask(displayToUse);
    CGLPixelFormatAttribute attribs[] = {
        kCGLPFAFullScreen,
        kCGLPFADisplayMask,
        displayMask,
        (CGLPixelFormatAttribute)NULL
	};
        
    float screenWidth = [screen frame].size.width;
    float screenHeight = [screen frame].size.height;
    
    CGLChoosePixelFormat(attribs, &pixelFormatObj, &numPixelFormats);
    
    CGLSetCurrentContext(NULL);
    CGLClearDrawable(glContextObj);
    CGLDestroyContext(glContextObj);
    CGLCreateContext(pixelFormatObj, NULL, &glContextObj);
        
    CGLDestroyPixelFormat(pixelFormatObj);
    
    CGLSetCurrentContext(glContextObj);
    CGLSetFullScreen(glContextObj);

    width = screenWidth;
    height = screenHeight;

    bytewidth = width * 4;	// Assume 4 bytes/pixel for now
    bytewidth = (bytewidth + 3) & ~3;	// Align to 4 bytes
        
    bytes = bytewidth * height;	// width * height
        
    if (bitmap) {
        [bitmap release];
    }
    bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                       pixelsWide:width
                                       pixelsHigh:height
                                       bitsPerSample:8
                                       samplesPerPixel:3
                                       hasAlpha:NO
                                       isPlanar:NO
                                       colorSpaceName:NSDeviceRGBColorSpace
                                       bytesPerRow:bytewidth
                                       bitsPerPixel:8 * 4];
    return YES;
}

- (NSImage *)captureFrame
{        
    [screenUpdateLock lock];
    glFinish();
    glPixelStorei(GL_PACK_ALIGNMENT, 4);	/* Force 4-byte alignment */
    glPixelStorei(GL_PACK_ROW_LENGTH, 0);
    glPixelStorei(GL_PACK_SKIP_ROWS, 0);
    glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
    
    glReadPixels(0, 0, width, height,
                 GL_BGRA,
                 GL_UNSIGNED_INT_8_8_8_8_REV,
                 [bitmap bitmapData]);
    swizzleBitmap(bitmap);
    NSData *png = [bitmap representationUsingType:NSPNGFileType properties:nil];
    NSRect fromRect = [screen frame];
    [screenUpdateLock unlock];
    
    NSRect scaledRect = NSMakeRect(0, 0, 640, 480);
    fromRect.origin.x = 0;
    fromRect.origin.y = 0;

	// Scale the image, doesn't work pre-Snow Leopard
	//CGImageRef cgImage = [screenImage CGImageForProposedRect:&scaledRect context:nil hints:nil];
	//NSImage *scaledImage = [[NSImage alloc] initWithCGImage:cgImage size:scaledRect.size];
	
	CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)png, NULL);
	CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	
    CGContextRef imageContext = nil;
    NSImage* newImage = nil;
	
    // Create a new image to receive the Quartz image data.
    newImage = [[[NSImage alloc] initWithSize:scaledRect.size] autorelease];
    [newImage lockFocus];
	
    // Get the Quartz context and draw.
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext]
								  graphicsPort];
    CGContextDrawImage(imageContext, *(CGRect*)&scaledRect, image);
    [newImage unlockFocus];
	
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


static inline void swapcopy32(void * src, void * dst, int bytecount )
{
    uint32_t *srcP;
    uint32_t *dstP;
    uint32_t p0, p1, p2, p3;
    uint32_t u0, u1, u2, u3;
    
    srcP = src;
    dstP = dst;
#define SWAB_PIXEL(p) (((p) << 8) | ((p) >> 24)) /* ppc rlwinm opcode results */
//#define SWAB_PIXEL(p) (((p) >> 8) | ((p) << 24)) /* ppc rlwinm opcode results */
    while ( bytecount >= 16 )
    {
        /*
         * Blatent hint to compiler that we want
         * strength reduction, pipelined fetches, and
         * some instruction scheduling, please.
         */
        p3 = srcP[3];
        p2 = srcP[2];
        p1 = srcP[1];
        p0 = srcP[0];
        
        u3 = SWAB_PIXEL(p3);
        u2 = SWAB_PIXEL(p2);
        u1 = SWAB_PIXEL(p1);
        u0 = SWAB_PIXEL(p0);
        srcP += 4;

#ifdef __LITTLE_ENDIAN__
        dstP[3] = ntohl(u3);
        dstP[2] = ntohl(u2);
        dstP[1] = ntohl(u1);
        dstP[0] = ntohl(u0);
#else
        dstP[3] = u3;
        dstP[2] = u2;
        dstP[1] = u1;
        dstP[0] = u0;
#endif
        bytecount -= 16;
        dstP += 4;
    }
    while ( bytecount >= 4 )
    {
        p0 = *srcP++;
        bytecount -= 4;
        *dstP++ = SWAB_PIXEL(p0);
    }
}

static void swizzleBitmap(NSBitmapImageRep * bitmap)
{
    int top, bottom;
    void * buffer;
    void * topP;
    void * bottomP;
    void * base;
    int rowBytes;

    rowBytes = [bitmap bytesPerRow];
    top = 0;
    bottom = [bitmap pixelsHigh] - 1;
    base = [bitmap bitmapData];
    buffer = malloc(rowBytes);
    
    while ( top < bottom )
    {
        topP = (top * rowBytes) + base;
        bottomP = (bottom * rowBytes) + base;
        
        /* Save and swap scanlines */
        swapcopy32( topP, buffer, rowBytes );
        swapcopy32( bottomP, topP, rowBytes );
        bcopy( buffer, bottomP, rowBytes );
        
        ++top;
        --bottom;
    }
    free( buffer );
}


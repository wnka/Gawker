//
//  CameraImageSource.m
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//
//  Based heavily on CSGCamera
//  Created by Tim Omernick.
//

#import "CameraImageSource.h"
#import "CameraManager.h"
#import "ImageText.h"

@interface CameraImageSource (PrivateMethods)
- (void)sequenceGrabberIdle;
- (BOOL)setupDecompression;
- (void)didUpdate;
- (NSImage *)imageFromGWorld:(GWorldPtr)gworld;
@end

@interface CameraImageSource (SequenceGrabber)
pascal OSErr CameraImageSourceSGDataProc(SGChannel channel, Ptr data, long dataLength, long *offset, long channelRefCon, TimeValue time, short writeType, long refCon);
@end

@implementation CameraImageSource

// Init and dealloc
- (id)initWithCameraName:(NSString *)name
{
    if (self = [super init]) {
        isEnabled = NO;
        timeZone = [[NSTimeZone localTimeZone] retain];
        recentImage = nil;
        cameraName = [name retain];
        [self setSourceDescription:@"Local Camera"];
        NSString *newSubDesc = [NSString stringWithFormat:@"My %@",cameraName];
        [self setSourceSubDescription:newSubDesc];
    }

    return self;
}

- (id)init
{
    return [self initWithCameraName:[NSString stringWithString:@"My Camera"]];
}

- (void)dealloc;
{
	[self stop];

    [timeZone release];

    [recentImage release];
    [recentTime release];

    [cameraName release];

    [sourceDescription release];
    [sourceSubDescription release];
    
	[super dealloc];
}

- (BOOL)startWithSize:(NSSize)frameSize;
{
    if (isEnabled) {
        NSLog(@"Camera already on!");
        return isEnabled;
    }
    OSErr theErr;
    
    // Initialize movie toolbox
    theErr = EnterMovies();
    if (theErr != noErr) {
        NSLog(@"EnterMovies() returned %ld", theErr);
        return NO;
    }

    component = 0;
    ComponentDescription grabbers;
    grabbers.componentType = SeqGrabComponentType;
    grabbers.componentSubType = 0;
    grabbers.componentManufacturer = 'appl';
    grabbers.componentFlags = 0;
    grabbers.componentFlagsMask = 0;

    NSLog(@"Number of SeqGrab Components: %d", CountComponents(&grabbers));

    // Open default sequence grabber component
    NSLog(@"Opening Default SeqGrabComponent");
    component = OpenDefaultComponent(SeqGrabComponentType, 0);

    if (!component) {
        NSLog(@"Could not open sequence grabber component.");
        return NO;
    }
    
    // Initialize sequence grabber component
    theErr = SGInitialize(component);
    if (theErr != noErr) {
        NSLog(@"SGInitialize() returned %ld", theErr);
        return NO;
    }

    if (![CameraManager findCamera:cameraName
                        inComponent:component
                        channel:&channel]) {
        NSLog(@"Couldn't find \"%@\" in channel list", cameraName);
        return NO;
    }
    
    // Don't make movie
    theErr = SGSetDataRef(component, 0, 0, seqGrabDontMakeMovie);
    if (theErr != noErr) {
        NSLog(@"SGSetDataRef() returned %ld", theErr);
        return NO;
    }
    
    // Set the grabber's bounds
    bounds.top = 0;
    bounds.left = 0;
    bounds.bottom = frameSize.height;
    bounds.right = frameSize.width;
	
    // Create the GWorld
    theErr = QTNewGWorld(&gWorld, k32ARGBPixelFormat, &bounds, 0, NULL, 0);
    if (theErr != noErr) {
        NSLog(@"QTNewGWorld() returned %ld", theErr);
        return NO;
    }
    
    // Lock the pixmap
    if (!LockPixels(GetPortPixMap(gWorld))) {
        NSLog(@"Could not lock pixels.");
        return NO;
    }
    
    // Set GWorld
    theErr = SGSetGWorld(component, gWorld, GetMainDevice());
    if (theErr != noErr) {
        NSLog(@"SGSetGWorld() returned %ld", theErr);
        return NO;
    }
    
    // Set the channel's bounds
    theErr = SGSetChannelBounds(channel, &bounds);
    if (theErr != noErr) {
        NSLog(@"SGSetChannelBounds(2) returned %ld", theErr);
        return NO;
    }
    
    // Set the channel usage to record
    theErr = SGSetChannelUsage(channel, seqGrabRecord);
    if (theErr != noErr) {
        NSLog(@"SGSetChannelUsage() returned %ld", theErr);
        return NO;
    }
    
    // Set data proc
    theErr = SGSetDataProc(component, NewSGDataUPP(&CameraImageSourceSGDataProc), (long)self);
    if (theErr != noErr) {
        NSLog(@"SGSetDataProc() returned %ld", theErr);
        return NO;
    }
    
    // Prepare
    theErr = SGPrepare(component, false, true);
    if (theErr != noErr) {
        NSLog(@"SGPrepare() returned %ld", theErr);
        return NO;
    }
    
    // Start recording
    theErr = SGStartRecord(component);
    if (theErr != noErr) {
        NSLog(@"SGStartRecord() returned %ld", theErr);
        return NO;
    }

    // Set up decompression sequence (camera -> GWorld)
    [self setupDecompression];
    
    // Start frame timer
    idleTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0/2.0 target:self selector:@selector(sequenceGrabberIdle) userInfo:nil repeats:YES] retain];
        
    isEnabled = YES;
    return isEnabled;
}

- (BOOL)stop;
{    
    // Stop frame timer
	if (idleTimer) {
		[idleTimer invalidate];
		[idleTimer release];
		idleTimer = nil;
	}
    
    // Stop recording
	if (component)
		SGStop(component);
    
    ComponentResult theErr;

    // End decompression sequence
	if (decompressionSequence) {
		theErr = CDSequenceEnd(decompressionSequence);
		if (theErr != noErr) {
			NSLog(@"CDSequenceEnd() returned %ld", theErr);
		}
		decompressionSequence = 0;
	}
    
    // Dispose of channel
    if (channel) {
        SGDisposeChannel(component, channel);
    }
    
    // Close sequence grabber component
	if (component) {
		theErr = CloseComponent(component);
		if (theErr != noErr) {
			NSLog(@"CloseComponent() returned %ld", theErr);
		}
		component = NULL;
	}

    // Dispose of GWorld
	if (gWorld) {
		DisposeGWorld(gWorld);
		gWorld = NULL;
	}
    
    [recentImage release];
    recentImage = nil;

    isEnabled = NO;

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
        success = [self startWithSize:NSMakeSize(640,480)];
    }
    else {
        success = [self stop];
    }
    if (!success) {
        // Something failed
        NSLog(@"Notifying of SourceDisconnect");
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"SourceDisconnect"
            object:self
            userInfo:nil];
    }
    return success;
}

- (NSImage *)recentImage
{
    return recentImage;
}

- (void)setRecentImage:(NSImage *)newImage
{
    [newImage retain];
    [recentImage release];
    recentImage = newImage;
    [recentTime release];
    recentTime = [[ImageText timeString:timeZone] retain];
}

- (NSString *)recentTime
{
    return recentTime;
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

@end

@implementation CameraImageSource (PrivateMethods)

- (void)sequenceGrabberIdle;
{
    OSErr theErr;
    
    theErr = SGIdle(component);
    if (theErr != noErr) {
        NSLog(@"SGIdle returned %ld", theErr);
        return;
    }
}

- (BOOL)setupDecompression;
{
    ComponentResult theErr;
    
    ImageDescriptionHandle imageDesc = (ImageDescriptionHandle)NewHandle(0);
    theErr = SGGetChannelSampleDescription(channel, (Handle)imageDesc);
    if (theErr != noErr) {
        NSLog(@"SGGetChannelSampleDescription() returned %ld", theErr);
        return NO;
    }
    
    Rect sourceRect;
    sourceRect.top = 0;
    sourceRect.left = 0;
    sourceRect.right = (**imageDesc).width;
    sourceRect.bottom = (**imageDesc).height;
    
    MatrixRecord scaleMatrix;
    RectMatrix(&scaleMatrix, &sourceRect, &bounds);
    
    theErr = DecompressSequenceBegin(&decompressionSequence, imageDesc, gWorld, NULL, NULL, &scaleMatrix, srcCopy, NULL, 0, codecNormalQuality, bestSpeedCodec);
    if (theErr != noErr) {
        NSLog(@"DecompressionSequenceBegin() returned %ld", theErr);
        return NO;
    }
    
    DisposeHandle((Handle)imageDesc);
	
	return YES;
}

- (void)didUpdate;
{
    BOOL notifyReadyToShare = NO;
    if (!recentImage) {
        notifyReadyToShare = YES;
    }
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [self setRecentImage:[self imageFromGWorld:gWorld]];

    [nc postNotificationName:@"ImageFromSource"
        object:self
        userInfo:nil];

    if (notifyReadyToShare) {
        [nc postNotificationName:@"SourceConnect"
            object:self
            userInfo:nil];            
    }
}

//
// Thanks to Chris Meyer from http://www.cocoadev.com/
// for imageFromGWorld
//
- (NSImage *)imageFromGWorld:(GWorldPtr)gworld;
{
    NSParameterAssert( gworld != NULL );

    PixMapHandle pixMapHandle = GetGWorldPixMap( gworld );
    if ( LockPixels( pixMapHandle ) )
    {
        Rect portRect;
        GetPortBounds( gworld, &portRect );
        int pixels_wide = (portRect.right - portRect.left);
        int pixels_high = (portRect.bottom - portRect.top);

        int bps = 8;
        int spp = 4;
        BOOL has_alpha = YES;

        NSBitmapImageRep *frameBitmap = [[[NSBitmapImageRep alloc]
            initWithBitmapDataPlanes:NULL
                          pixelsWide:pixels_wide
                          pixelsHigh:pixels_high
                       bitsPerSample:bps
                     samplesPerPixel:spp
                            hasAlpha:has_alpha
                            isPlanar:NO
                      colorSpaceName:NSDeviceRGBColorSpace
                         bytesPerRow:0
                        bitsPerPixel:0] autorelease];
        
        CGColorSpaceRef dst_colorspaceref = CGColorSpaceCreateDeviceRGB();

        CGImageAlphaInfo dst_alphainfo = has_alpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone;

        CGContextRef dst_contextref = CGBitmapContextCreate( [frameBitmap bitmapData],
                                                             pixels_wide,
                                                             pixels_high,
                                                             bps,
                                                             [frameBitmap bytesPerRow],
                                                             dst_colorspaceref,
                                                             dst_alphainfo );

        void *pixBaseAddr = GetPixBaseAddr(pixMapHandle);

        long pixmapRowBytes = GetPixRowBytes(pixMapHandle);

        CGDataProviderRef dataproviderref = CGDataProviderCreateWithData( NULL, pixBaseAddr, pixmapRowBytes * pixels_high, NULL );

        int src_bps = 8;
        int src_spp = 4;
        BOOL src_has_alpha = YES;

        CGColorSpaceRef src_colorspaceref = CGColorSpaceCreateDeviceRGB();

        CGImageAlphaInfo src_alphainfo = src_has_alpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNone;

        CGImageRef src_imageref = CGImageCreate( pixels_wide,
                                                 pixels_high,
                                                 src_bps,
                                                 src_bps * src_spp,
                                                 pixmapRowBytes,
                                                 src_colorspaceref,
                                                 src_alphainfo,
                                                 dataproviderref,
                                                 NULL,
                                                 NO, // shouldInterpolate
                                                 kCGRenderingIntentDefault );

        CGRect rect = CGRectMake( 0, 0, pixels_wide, pixels_high );

        CGContextDrawImage( dst_contextref, rect, src_imageref );

        CGImageRelease( src_imageref );
        CGColorSpaceRelease( src_colorspaceref );
        CGDataProviderRelease( dataproviderref );
        CGContextRelease( dst_contextref );
        CGColorSpaceRelease( dst_colorspaceref );

        UnlockPixels( pixMapHandle );

		NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(pixels_wide, pixels_high)];
        [image addRepresentation:frameBitmap];
        
        return [image autorelease];
    }
    
    return NULL;
}

@end

@implementation CameraImageSource (SequenceGrabber)

pascal OSErr CameraImageSourceSGDataProc(SGChannel channel, Ptr data, long dataLength, long *offset, long channelRefCon, TimeValue time, short writeType, long refCon)
{
    CameraImageSource *camera = (CameraImageSource *)refCon;
    ComponentResult theErr;
    
    if (camera->gWorld) {
        CodecFlags ignore;
        theErr = DecompressSequenceFrameS(camera->decompressionSequence, data, dataLength, 0, &ignore, NULL);
        if (theErr != noErr) {
            NSLog(@"DecompressSequenceFrameS() returned %ld", theErr);
            return theErr;
        }
    }
    
	[camera didUpdate];
    return noErr;
}

@end

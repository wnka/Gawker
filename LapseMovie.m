//
//  LapseMovie.m
//  Gawker
//
//  Created by Phil Piwonka on 8/2/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "LapseMovie.h"
#import <QTKit/QTMovie.h>
#import <unistd.h>

@implementation LapseMovie

- (id)initWithFilename:(NSString *)file
               quality:(NSString *)quality
                   FPS:(double)fps
{
    if (self = [super init]) {
        outFilename = [file retain];
        NSLog(@"In LapseMovie, writing to: %@", outFilename);
        // timeValue / timeScale = how long each frame
        // lasts in the movie.  timeScale is always 600 (i think).
        // So, 1/30 needs to be scaled to 20/600.
        // 600/30 = 20.  1 * 20 = 20

        long timeScale = 600;
        long long timeValue = 600 / fps;
        
        frameDuration = QTMakeTime(timeValue, timeScale);

        //
        // Set quality
        //
        NSNumber *qualityNum;
        if ([quality isEqual:@"High"]) {
            qualityNum = [NSNumber numberWithLong:codecHighQuality];
            NSLog(@"Using High Quality");
        }
        else if ([quality isEqual:@"Medium"]) {
            qualityNum = [NSNumber numberWithLong:codecNormalQuality];
            NSLog(@"Using Normal Quality");
        }
        else if ([quality isEqual:@"Low"]) {
            qualityNum = [NSNumber numberWithLong:codecLowQuality];
            NSLog(@"Using Low Quality");
        }
        else {
            NSLog(@"UNKNOWN quality! Defaulting to Normal");
            qualityNum = [NSNumber numberWithLong:codecLowQuality];
        }
        // when adding images we must provide a dictionary
        // specifying the codec attributes
        movieDict = [[NSDictionary dictionaryWithObjectsAndKeys:@"avc1",
                                   QTAddImageCodecType,
                                   qualityNum,
                                   QTAddImageCodecQuality,
                                   nil] retain];
        
        movieView = [[QTMovieView alloc] init];
        [movieView setControllerVisible:NO];
        if (![self createBlankMovie]) {
            NSLog(@"LapseMovie -init: Error creating movie!");
        }
    }
    return self;
}

- (BOOL)createBlankMovie
{
	// generate a name for our movie file
	tempFilename = [[NSString stringWithCString:tmpnam(nil) 
                         encoding:[NSString defaultCStringEncoding]] retain];

	
	OSErr   err         = noErr;
	Handle  dataRefH    = nil;
	OSType  dataRefType;
	
	// create a file data reference for our movie
	err = QTNewDataReferenceFromFullPathCFString((CFStringRef)tempFilename,
												 kQTNativeDefaultPathStyle,
												 0,
												 &dataRefH,
												 &dataRefType);
	if (err != noErr) {
		if (dataRefH) {
			DisposeHandle(dataRefH);
		}
		return NO;
	}
	
	// create a QuickTime movie from our file data reference
	Movie  qtMovie  = nil;
	CreateMovieStorage (dataRefH,
						dataRefType,
						'TVOD',
						smSystemScript,
						newMovieActive, 
						&mDataHandlerRef,
						&qtMovie);
	err = GetMoviesError();
	if (noErr != err) {
		if (dataRefH) {
			DisposeHandle(dataRefH);
		}
		return NO;
	}
	
	// instantiate a QTMovie from our QuickTime movie
	movie = [QTMovie movieWithQuickTimeMovie:qtMovie disposeWhenDone:YES error:nil];
	// mark the movie as editable
	[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	if (!movie) {
		if (dataRefH) {
			DisposeHandle(dataRefH);
		}
	}
	
	[movie retain];	
	[movieView setMovie:movie];
	return YES;
}

- (void)dealloc
{
	NSLog(@"In LapseMovie -dealloc");
    [movieDict release];
    [outFilename release];
    [tempFilename release];
	[movie release];
	[movieView release];
	[super dealloc];
}

- (void)addImage:(NSImage *)anImage
{
    [movie addImage:anImage
           forDuration:frameDuration
           withAttributes:movieDict];
}

- (BOOL)writeToDisk
{
	NSDictionary	*dict = nil;
	BOOL			success = NO;
	
	if (!outFilename) {
		return success;
	}
	
	// create a dict. with the movie flatten attribute (QTMovieFlatten)
	// which we'll use to flatten the movie to a file below
	
	// specify a 'YES' in the dictionary to flatten to a new movie file
	
	// specify a 'NO' in the dictionary to only create a reference movie
	dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
                         forKey:QTMovieFlatten];
    char template[] = "/tmp/Gawker.mov.XXXXX";
    char *tempFile = mktemp(template);

	NSString *tempOut = [NSString stringWithCString:tempFile];

	if (dict) {
        // create a new movie file and flatten the movie to the file
        // passing the QTMovieFlatten attribute here means the movie
        // will be flattened

        // We have to write out to a temporary file due to the fact
        // that APPARENTLY writeToFile: can't handle ":" as slashes
        // in the path name.  So, write to a tmp file, then move it
        // using NSFileManager which can handle it.
        success = [movie writeToFile:tempOut withAttributes:dict];
    }
	
    if (success) {
        NSFileManager *fileMan = [NSFileManager defaultManager];
        [fileMan removeFileAtPath:outFilename handler:self];
        [fileMan movePath:tempOut toPath:outFilename handler:self];
        // Remove temporary file created in createBlankMovie
        [fileMan removeFileAtPath:tempFilename handler:self];
    }

	return success;	
}

- (QTMovie *)movie
{
    return movie;
}

@end

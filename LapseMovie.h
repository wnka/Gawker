//
//  LapseMovie.h
//  Gawker
//
//  Created by Phil Piwonka on 8/2/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <QuickTime/QuickTime.h>

@class QTMovie;

@interface LapseMovie : NSObject {
	// This QTMovieView is not shown to the screen,
	// however it seems that if the QTMovie is not
	// bound to a view, it dumps the first frame to
	// the upper left hand corner of the screen.
	QTMovieView *movieView;
	QTMovie *movie;
    NSString *tempFilename;
    NSString *outFilename;
    NSDictionary *movieDict;
    QTTime frameDuration;
	DataHandler mDataHandlerRef;
}

- (id)initWithFilename:(NSString *)file
               quality:(NSString *)quality
                   FPS:(double)fps;
    
- (BOOL)createBlankMovie;
- (void)addImage:(NSImage *)anImage;
- (BOOL)writeToDisk;
- (QTMovie *)movie;
@end

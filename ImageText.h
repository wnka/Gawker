//
//  ImageText.h
//  Gawker
//
//  Created by Phil Piwonka on 8/14/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageText : NSObject

+ (NSImage *)imageWithImage:(NSImage *)orig 
             stringAtBottom:(NSString *)s
                 attributes:(NSDictionary *)attributes
                scaleFactor:(double)scale;

+ (NSImage *)roundedTextWithString:(NSString *)string
						attributes:(NSDictionary *)attribs;

+ (NSImage *)compositeImages:(NSArray *)images
                 sizeOfEach:(NSSize)size;

+ (NSImage *)imageFromCIImage:(CIImage *)ciImage;

+ (NSString *)timeString:(NSTimeZone *)tz;

@end

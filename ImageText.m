//
//  ImageText.m
//  Gawker
//
//  Created by Phil Piwonka on 8/14/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "ImageText.h"

@implementation ImageText

+ (NSImage *)imageWithImage:(NSImage *)orig stringAtBottom:(NSString *)s
attributes:(NSDictionary *)attributes scaleFactor:(double)scale
{
    NSSize origSize = [orig size];
    NSSize newSize = origSize;
    newSize.width *= scale;
    newSize.height *= scale;

    NSImage *newImage = [[NSImage alloc] initWithSize:newSize];
    NSImage *roundedText = [ImageText roundedTextWithString:s
                                      attributes:attributes];
    if (newImage) {
        [newImage lockFocus];
        NSRect imageRect = NSMakeRect(0, 0, 
                                      origSize.width * scale, 
                                      origSize.height * scale);
        [orig drawInRect:imageRect
              fromRect:NSMakeRect(0, 0, origSize.width, origSize.height)
              operation:NSCompositeSourceOver
              fraction:1.0];

        // Draw string at bottom of frame.
        NSSize textSize = [roundedText size];
        NSRect textRect;
        textRect.size = textSize;
        textRect.origin.y = 6;
        textRect.origin.x = (newSize.width - textSize.width)/2;
        
        [roundedText drawInRect:textRect
                 fromRect:NSMakeRect(0, 0, textSize.width, textSize.height)
                 operation:NSCompositeSourceOver
                 fraction:1.0];

        [newImage unlockFocus];
    }
    
    return [newImage autorelease];
}

+ (NSImage *)roundedTextWithString:(NSString *)string
						attributes:(NSDictionary *)attribs
{
    NSMutableDictionary *attribCopy = [[NSMutableDictionary alloc] init];
    [attribCopy addEntriesFromDictionary:attribs];
    NSSize stringSize = [string sizeWithAttributes:attribCopy];

    NSSize maxSize;
    maxSize.width = 260;  // Will work for both 640x480 and 320x240
    maxSize.height = 20;

    // Want 5 pixels pad on each side and 3 pixels pad top and bottom
    while (stringSize.width > maxSize.width - 20 ||
           stringSize.height > maxSize.height - 3) {
        NSFont *font = [attribCopy objectForKey:NSFontAttributeName];
        float fontSize = [font pointSize];
        fontSize -= 1;
        NSFont *newFont = [NSFont fontWithDescriptor:[font fontDescriptor]
                                  size:fontSize];
        [attribCopy setObject:newFont
                    forKey:NSFontAttributeName];
        stringSize = [string sizeWithAttributes:attribCopy];
    }

    maxSize.width = stringSize.width + 40;

    NSMutableAttributedString *attribString = 
        [[NSMutableAttributedString alloc] initWithString:string];

    NSRange range = NSMakeRange(0, [attribString length]);
    [attribString setAttributes:attribCopy range:range];
    [attribString setAlignment:NSCenterTextAlignment range:range];


    NSImage *rnd = [[NSImage alloc] initWithSize:maxSize];
    
    [rnd lockFocus];
    
    NSColor *bgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.35];
    NSRect bgRect = NSMakeRect(0, 0, maxSize.width, maxSize.height);
    int minX = NSMinX(bgRect);
    int midX = NSMidX(bgRect);
    int maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect);
    int midY = NSMidY(bgRect);
    int maxY = NSMaxY(bgRect);
    float radius = 10.0; // correct value to duplicate Panther's App Switcher
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
    [bgPath appendBezierPathWithArcFromPoint:bgRect.origin 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];
    
    [bgColor set];
    [bgPath fill];    

    // Add one to y due to shadow making string look lower than it is.
    NSPoint stringOrigin;
    stringOrigin.x = (maxSize.width - stringSize.width)/2;
    stringOrigin.y = (maxSize.height - stringSize.height)/2 + 1;

    [attribString drawAtPoint:stringOrigin];
    [attribString release];

    [rnd unlockFocus];
    
    return [rnd autorelease];
}

+ (NSImage *)compositeImages:(NSArray *)images
                 sizeOfEach:(NSSize)size
{
    int numImages = [images count];
    
    NSSize outSize;
    
    if (numImages == 4) {
        outSize.width = 2 * size.width;
        outSize.height = 2 * size.height;
    }
    else {
        outSize.width = numImages * size.width;
        outSize.height = size.height;
    }
    
    NSImage *compImage = [[NSImage alloc] initWithSize:outSize];
    [compImage lockFocus];

    int i;
    NSRect destRect = NSMakeRect(0, 0, size.width, size.height);
    for (i = 0; i < numImages; i++) {
        NSImage *origImage = [images objectAtIndex:i];
        NSSize origSize = [origImage size];
        
        if (numImages == 4) {
            int gridX = i % 2;
            int gridY = i / 2;
            destRect.origin.x = size.width * gridX;
            destRect.origin.y = size.height * gridY;
        }
        else {
            destRect.origin.x = size.width * i;
        }

        [origImage drawInRect:destRect
                   fromRect:NSMakeRect(0, 0, origSize.width, origSize.height)
                   operation:NSCompositeSourceOver
                   fraction:1.0];
    }
    [compImage unlockFocus];

    return [compImage autorelease];
}

+ (NSImage *)imageFromCIImage:(CIImage *)ciImage
{
    NSSize imgSize = NSMakeSize([ciImage extent].size.width,
                                [ciImage extent].size.height);
    NSImage *nsImage = [[NSImage alloc] initWithSize:imgSize];
    [nsImage addRepresentation:[NSCIImageRep imageRepWithCIImage:ciImage]];
    [nsImage autorelease];
    return nsImage;
}

+ (NSString *)timeString:(NSTimeZone *)tz
{
    NSString *timeFormat = [NSString stringWithString:@"%m/%d/%Y %I:%M:%S %p"];

    int hoursFromGMT = [tz secondsFromGMT] / 3600;
    NSString *GMTString = nil;
    if (hoursFromGMT >= 0) {
        GMTString = [NSString stringWithString:@"GMT+"];
    }
    else {
        GMTString = [NSString stringWithString:@"GMT"];
    }
    
    return [NSString stringWithFormat:@"%@ %@%d",
                     [[NSDate date] descriptionWithCalendarFormat:timeFormat 
                                    timeZone:tz
                                    locale:nil], 
                     GMTString,
                     hoursFromGMT];
}

@end

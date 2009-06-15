//
//  ImageSource.h
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol ImageSource <NSObject>
- (BOOL)isEnabled;
- (BOOL)setEnabled:(BOOL)state;
- (NSString *)sourceDescription;
- (void)setSourceDescription:(NSString *)newDesc;
- (NSString *)sourceSubDescription;
- (void)setSourceSubDescription:(NSString *)newDesc;
- (NSImage *)recentImage;
- (NSString *)recentTime;
@end

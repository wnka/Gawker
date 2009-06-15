//
//  NetworkImageSource.h
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageSource.h"

@class AsyncSocket;

@interface NetworkImageSource : NSObject <ImageSource>
{
    AsyncSocket *remoteSocket;
    NSString *ipAddress;
    int remotePort;

    NSImage *recentImage;
    NSString *recentTime;

    NSString *sourceDescription;
    NSString *sourceSubDescription;
    
    NSTimeZone *timeZone;

    BOOL isEnabled;
}

- (id)initWithIp:(NSString *)address port:(int)port;
- (id)init;

- (NSImage *)recentImage;
- (NSString *)recentTime;

- (NSString *)sourceDescription;
- (void)setSourceDescription:(NSString *)newDesc;
- (NSString *)sourceSubDescription;
- (void)setSourceSubDescription:(NSString *)newDesc;

- (BOOL)isEnabled;
- (BOOL)setEnabled:(BOOL)enable;

- (void)usePassword:(NSString *)pass;
@end


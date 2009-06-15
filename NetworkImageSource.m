//
//  NetworkImageSource.m
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "NetworkImageSource.h"
#import "ImageText.h"
#import "AsyncSocket.h"

@interface NetworkImageSource (PrivateMethods)
- (void)setRecentImage:(NSImage *)newImage;
@end

@interface NetworkImageSource (AsyncSocketDelegation)
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;
- (void)onSocketDidDisconnect:(AsyncSocket *)sock;
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)t;
@end

@implementation NetworkImageSource

- (id)initWithIp:(NSString *)address port:(int)port
{
    if (self = [super init]) {
        recentImage = nil;
        [self setSourceDescription:@"Remote Camera"];
        ipAddress = [address retain];
        [self setSourceSubDescription:ipAddress];
        remotePort = port;
        isEnabled = NO;
    }

    return self;
}

- (id)init
{
    return [self initWithIp:nil port:0];
}

- (void)dealloc
{
    [remoteSocket setDelegate:nil];
    [remoteSocket disconnect];
    [remoteSocket release];

    [ipAddress release];
    
    [super dealloc];
}

- (NSImage *)recentImage
{
    return recentImage;
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

- (BOOL)isEnabled
{
    return isEnabled;
}

- (BOOL)setEnabled:(BOOL)enable
{
    // This is set to NO because we don't know if we are successful
    // until the connection is actually attempted.
    // Success is relayed through notifications.
    BOOL wasSuccessful = NO;
    if (enable && ![self isEnabled]) {
        isEnabled = NO;
        [self setSourceDescription:@"Connecting..."];
        if (!remoteSocket) {
            NSLog(@"Creating remote socket");
            remoteSocket = [[AsyncSocket alloc] initWithDelegate:self];
        }
        [remoteSocket setDelegate:self];

        if ([remoteSocket connectToHost:ipAddress
                          onPort:remotePort
                          error:nil]) {
            NSLog(@"Connecting to %@:%d", ipAddress, remotePort);
            isEnabled = YES;
        }
        else {
            NSLog(@"ERROR Connecting to %@:%d", ipAddress, remotePort);
            wasSuccessful = NO;
            isEnabled = NO;
        }
    }
    else if (!enable) {
        if ([[self sourceDescription] isEqual:@"Connecting..."]) {
            [self setSourceDescription:@"Connect Cancelled"];
        }

        [remoteSocket setDelegate:nil];
        [remoteSocket disconnect];
        
        [recentImage release];
        recentImage = nil;

        isEnabled = NO;
    }

    return wasSuccessful;
}

- (void)usePassword:(NSString *)pass
{
    if (pass) {
        NSString *passwordReply = 
            [NSString stringWithFormat:@"PRE:%@:\n", pass];
        NSData *passData = 
            [passwordReply dataUsingEncoding:NSASCIIStringEncoding];
        
        [remoteSocket writeData:passData withTimeout:-1 tag:0];
    }
    else {
        [self setSourceDescription:@"Connect Cancelled"];
        [remoteSocket disconnect];
    }
}

@end

@implementation NetworkImageSource (PrivateMethods)

- (void)setRecentImage:(NSImage *)newImage
{
    [newImage retain];
    [recentImage release];
    recentImage = newImage;
    [recentTime release];
    recentTime = [[ImageText timeString:timeZone] retain];
}

@end

@implementation NetworkImageSource (AsyncSocketDelegation)
-(void) onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog (@"Socket will disconnect. Error domain %@, code %d (%@).", 
           [err domain], [err code], [err localizedDescription]);
    [self setSourceDescription:@"Connection Failed"];
}

-(void) onSocketDidDisconnect:(AsyncSocket *)sock
{ 
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"SourceDisconnect"
        object:self
        userInfo:nil];
}

-(void) onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)portNum
{
    NSLog (@"Successfully connected to %@:%u", host, portNum);
    isEnabled = YES;
    NSData *newline = [@"\n" dataUsingEncoding:NSASCIIStringEncoding];
    [sock readDataToData:newline withTimeout:-1 tag:0];
}

-(void) onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)t
{
    NSString *incomingString = nil;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSData *newline = [@"\n" dataUsingEncoding:NSASCIIStringEncoding];
    switch (t) {
    case 0:
        incomingString = [[NSString alloc] initWithData:data
                                           encoding:NSASCIIStringEncoding];

        NSArray *components = [incomingString componentsSeparatedByString:@":"];
        
        if ([[components objectAtIndex:0] isEqual:@"DSC"]) {
            [self setSourceDescription:[components objectAtIndex:1]];
            int secondsFromGMT = [[components objectAtIndex:2] intValue];
            timeZone = 
                [[NSTimeZone timeZoneForSecondsFromGMT:secondsFromGMT] retain];
            [nc postNotificationName:@"DescriptionUpdate"
                object:self
                userInfo:nil];
            [sock readDataToData:newline withTimeout:-1 tag:0];
        }
        else if ([[components objectAtIndex:0] isEqual:@"IMG"]) {
            if (!recentImage) {
                NSLog(@"First Image coming in");
                [nc postNotificationName:@"SourceConnect"
                    object:self
                    userInfo:nil];            
            }
            UInt32 length = [[components objectAtIndex:1] intValue];
            [sock readDataToLength:length withTimeout:-1 tag:1];
        }
        else if ([[components objectAtIndex:0] isEqual:@"DED"]) {
            NSLog(@"Server is going down!");
            [self setSourceDescription:@"Server Shut Down"];
            [nc postNotificationName:@"SourceDisconnect"
                object:self
                userInfo:nil];
        }
        else if ([[components objectAtIndex:0] isEqual:@"FUL"]) {
            NSLog(@"Server is full");
            [self setSourceDescription:@"Too Many Clients"];
            [nc postNotificationName:@"SourceDisconnect"
                object:self
                userInfo:nil];
        }
        else if ([[components objectAtIndex:0] isEqual:@"PRQ"]) {
            NSLog(@"Need password");

            [self setSourceDescription:@"Password Required"];
            [nc postNotificationName:@"SourceNeedsPassword"
                object:self
                userInfo:nil];
        }
        else if ([[components objectAtIndex:0] isEqual:@"PRF"]) {
            NSLog(@"Wrong Password");
            [self setSourceDescription:@"Wrong Password"];
            [nc postNotificationName:@"SourceDisconnect"
                object:self
                userInfo:nil];
        }
        else {
            NSLog(@"ERROR!  Unknown string: %@", incomingString);
        }
        [incomingString release];
        break;
        
    case 1:
        NSLog(@"Got image of size %d bytes", [data length]);
        NSImage *theImage = [[NSImage alloc] initWithData:data];

        [self setRecentImage:theImage];

        [nc postNotificationName:@"ImageFromSource"
            object:self
            userInfo:nil];
        [theImage release];

        // do it all over again
        [sock readDataToData:newline withTimeout:-1 tag:0];
        break;
    default:
        NSLog(@"Unknown tag!");
        break;
    }
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"Wrote data with tag: %ld", tag);
    NSData *newline = 
        [@"\n" dataUsingEncoding:NSASCIIStringEncoding];    
    switch (tag) {
    case 0:
        NSLog(@"Wrote password, wait for response");
        [sock readDataToData:newline withTimeout:-1 tag:0];
        break;
    default:
        NSLog(@"Uh oh, unknown tag!");
    }
}

@end

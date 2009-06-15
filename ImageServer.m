//
//  ImageServer.m
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "ImageServer.h"
#import "AsyncSocket.h"

@interface ImageServer (PrivateMethods)
- (BOOL)openListenSocket;
- (void)sendImageToClients;
- (void)sendDescriptionToClients;
- (NSData *)descriptionData;
- (NSData *)passwordRequiredData;
- (NSData *)passwordFailure;
- (void)sendFullMessageToClient:(AsyncSocket *)sock;
- (void)disconnectClientsOverLimit;
- (void)disconnectAllClients;
- (void)updateDelegate;
@end

@interface ImageServer (AsyncSocketDelegation)
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;
- (void)onSocketDidDisconnect:(AsyncSocket *)sock;
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket;
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag;
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag;
@end

@implementation ImageServer
- (id)initWithPortNumber:(int)portNum 
             description:(NSString *)description
                delegate:(id)theDelegate
{
    if (self = [super init]) {
        [self setServerDescription:description];
        serverPortNumber = portNum;
        clients = [[NSMutableArray alloc] init];
        isValid = [self openListenSocket];
        userLimit = 0;
        delegate = theDelegate;
    }

    return self;
}

- (id)init
{
    return [self initWithPortNumber:7548 
                 description:NSFullUserName()
                 delegate:nil];
}

- (void)dealloc
{
    NSLog(@"Deallocating Image Server listening on Port %d",
          serverPortNumber);
    
    [self disconnectAllClients];

    [self setBonjourEnabled:NO];
    [serverListenSocket setDelegate:nil];
    [serverListenSocket disconnect];
    [serverListenSocket release];
    serverListenSocket = nil;

    [serverDescription release];
    [sharedImage release];
    [sharedData release];

    [clients release];

    [super dealloc];
}

- (BOOL)setBonjourEnabled:(BOOL)enable
{
    BOOL wasSuccessful = YES;
    if (enable) {
        NSLog(@"Enabling bonjour announcing");
        if (bonjourAnnouncer) {
            NSLog(@"Cleaning up existing announcer");
            // FIXME
            [bonjourAnnouncer stop];
            [bonjourAnnouncer release];
        }
        bonjourAnnouncer = [[NSNetService alloc] initWithDomain:@""
                                                 type:@"_lapse._tcp."
                                                 name:serverDescription
                                                 port:serverPortNumber];
        [bonjourAnnouncer setDelegate:self];
        [bonjourAnnouncer publish];
        NSLog(@"Server announced over Bonjour as %@",
              serverDescription);
    }
    else {
        NSLog(@"Disabling bonjour announcing");
        if (!bonjourAnnouncer) {
            NSLog(@"Nothing to disable");
        }
        else {
            [bonjourAnnouncer stop];
            [bonjourAnnouncer release];
            bonjourAnnouncer = nil;
        }
    }

    return wasSuccessful;
}

- (BOOL)isBonjourEnabled
{
    return (bonjourAnnouncer) ? YES : NO;
}

- (NSString *)serverDescription
{
    return serverDescription;
}

- (void)setServerDescription:(NSString *)newDesc
{
    [newDesc retain];
    [serverDescription release];
    serverDescription = newDesc;
    [self sendDescriptionToClients];
}


- (NSImage *)sharedImage
{
    return sharedImage;
}

- (void)setSharedImage:(NSImage *)newImage
{
    [newImage retain];
    [sharedImage release];
    sharedImage = newImage;

    NSBitmapImageRep *rep =
        [NSBitmapImageRep imageRepWithData:[sharedImage TIFFRepresentation]];
    [sharedData release];
    sharedData =
        [[rep representationUsingType:NSJPEGFileType properties:nil] retain];

    sharedDataSize = [sharedData length];
    [self sendImageToClients];
}

- (BOOL)limitUsers
{
    return limitUsers;
}

- (void)setLimitUsers:(BOOL)shouldLimit;
{
    limitUsers = shouldLimit;
    if (limitUsers) {
        [self disconnectClientsOverLimit];
    }

    [self updateDelegate];    
}

- (int)userLimit
{
    return userLimit;
}
    
- (void)setUserLimit:(int)limit
{
    if (limit != userLimit) {
        userLimit = limit;
        NSLog(@"New Client Limit: %d Currently %d Connected",
              limit,
              [clients count]);
        if (limit == 0) {
            NSLog(@"Unlimited Users");
        }
        
        [self disconnectClientsOverLimit];
    }

    [self updateDelegate];    
}

- (int)numConnected
{
    return [clients count];
}

- (NSArray *)clients
{
    return [NSArray arrayWithArray:clients];
}

- (BOOL)requirePassword
{
    return requirePassword;
}

- (void)setRequirePassword:(BOOL)reqPass
{
    requirePassword = reqPass;
}

- (NSString *)password
{
    return password;
}

- (void)setPassword:(NSString *)newPass
{
    [newPass retain];
    [password release];
    password = newPass;
}

- (BOOL)isValid
{
    return isValid;
}

@end

@implementation ImageServer (PrivateMethods)

- (BOOL)openListenSocket
{
    BOOL wasSuccessful = NO;
    serverListenSocket = [[AsyncSocket alloc] initWithDelegate:self];
    if (serverListenSocket) {
        NSError *err = nil;
        if ([serverListenSocket acceptOnPort:serverPortNumber
                                error:&err]) {
            NSLog(@"Image Server waiting for connection on port %u.",
                  serverPortNumber);
            wasSuccessful = YES;
        }
        else {
            NSLog (@"Cannot accept connections on port %u. Error domain %@ code %d (%@). Exiting.", 
                   serverPortNumber,
                   [err domain],
                   [err code],
                   [err localizedDescription]);
        }
    }
    else {
        NSLog(@"Error creating Server Listen Socket");
    }
    
    return wasSuccessful;
}

- (void)sendImageToClients
{
    if ([clients count] > 0 && sharedDataSize > 0) {
        NSLog(@"Broadcasting current image to %d clients",
              [clients count]);
        
        AsyncSocket *client = nil;
        NSEnumerator *clientEnum = [clients objectEnumerator];
        while (client = [clientEnum nextObject]) {
            // Don't send image to clients that haven't given the
            // correct password.
            if ([client passwordFailures] > 0) {
                continue;
            }
            NSString *sendString =
                [NSString stringWithFormat:@"IMG:%d:\n",
                          sharedDataSize];
            NSData *data = [sendString dataUsingEncoding:NSASCIIStringEncoding];

            // Can this be done?
            [client writeData:data withTimeout:-1 tag:1];
            [client writeData:sharedData withTimeout:-1 tag:2];
        }
    }
}

- (void)sendDescriptionToClients
{
    if ([clients count] > 0 && sharedDataSize > 0) {
        NSLog(@"Broadcasting current image to %d clients",
              [clients count]);
        
        AsyncSocket *client = nil;
        NSEnumerator *clientEnum = [clients objectEnumerator];
        NSData *descData = [self descriptionData];
        while (client = [clientEnum nextObject]) {
            // Don't send to clients that haven't given the
            // correct password.
            if ([client passwordFailures] > 0) {
                continue;
            }
            [client writeData:descData withTimeout:-1 tag:0];
        }
    }
}

- (NSData *)descriptionData
{
    int secondsFromGMT = 
        [[NSTimeZone localTimeZone] secondsFromGMT];
    NSString *sendString =
        [NSString stringWithFormat:@"DSC:%@:%d:\n",
                  [self serverDescription],
                  secondsFromGMT];
    
    NSLog(@"Telling client we are the description");
    NSData *data = [sendString dataUsingEncoding:NSASCIIStringEncoding];
    return data;
}

- (NSData *)passwordRequiredData
{
    NSString *sendString = 
        [NSString stringWithFormat:@"PRQ:%@:\n",
                  [self serverDescription]];
    NSLog(@"Asking the client for a password");
    NSData *data = [sendString dataUsingEncoding:NSASCIIStringEncoding];
    return data;
}

- (NSData *)passwordFailure
{
    NSString *sendString = 
        [NSString stringWithFormat:@"PRF:%@:\n",
                  [self serverDescription]];
    NSLog(@"Incorrect Password");
    NSData *data = [sendString dataUsingEncoding:NSASCIIStringEncoding];
    return data;
}


- (void)sendFullMessageToClient:(AsyncSocket *)sock
{
    NSLog(@"Sorry, can't connect, too many clients");
    NSString *sendString = [NSString stringWithFormat:@"FUL:%d:\n",
                                     userLimit];
    NSData *data = [sendString dataUsingEncoding:NSASCIIStringEncoding];
    [sock writeData:data withTimeout:-1 tag:4];
    [sock disconnect];
    return;
}

- (void)disconnectClientsOverLimit
{
    if ([clients count] > userLimit) {
        NSLog(@"New connection limit exceeded, disconnecting some users.");
    }

    while ([clients count] > userLimit) {
        AsyncSocket *toBoot = [clients lastObject];
        [self sendFullMessageToClient:toBoot];
        [toBoot setDelegate:nil];
        [clients removeLastObject];
    }
}

- (void)disconnectAllClients
{
    NSLog(@"Disconnecting all clients");
    NSEnumerator *clientEnum = [clients objectEnumerator];
    AsyncSocket *client;
    while (client = [clientEnum nextObject]) {
        NSString *sendString =
            [NSString stringWithFormat:@"DED:0:\n",
                      sharedDataSize];
        NSData *data = [sendString dataUsingEncoding:NSASCIIStringEncoding];
        [client writeData:data withTimeout:-1 tag:3];
        [client setDelegate:nil];
        [client disconnect];
    }
    [clients removeAllObjects];
}


- (void)updateDelegate
{
    if ([delegate respondsToSelector:@selector(imageServerUpdatedStats:)]) {
        [delegate imageServerUpdatedStats:self];
    }
}

@end

@implementation ImageServer (AsyncSocketDelegation)
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    if (err != nil) {
        NSLog(@"Socket will disconnect. Error domain %@, code %d (%@).", 
              [err domain], [err code], [err localizedDescription]);
    }
    else {
        NSLog(@"Socket will disconnect.  No Error.");
    }
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	int index = [clients indexOfObject:sock];
	if (index != NSNotFound) {
		NSLog(@"Socket %d disconnected",
			  index);		
		[clients removeObjectAtIndex:index];
	}
    
    [self updateDelegate];
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
	NSLog(@"Socket %d accepting connection from %@ %u", 
          [clients count], [newSocket connectedHost], [newSocket connectedPort]);

    // Increment the password failures so that we don't send images to 
    // clients that haven't given the correct password.
    if (requirePassword) {
        [newSocket incrementPasswordFailures];
    }
	[clients addObject:newSocket];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"Socket %d successfully accepted connection from %@ %u.", 
          [clients indexOfObject:sock], host, port);
    
    if (limitUsers && [clients count] > userLimit) {
        [self sendFullMessageToClient:sock];
    }
    else {
        if (requirePassword) {
            NSData *data = [self passwordRequiredData];
            [sock writeData:data withTimeout:-1 tag:5];
            [self updateDelegate];
            NSData *newline = [@"\n" dataUsingEncoding:NSASCIIStringEncoding];
            [sock readDataToData:newline withTimeout:-1 tag:1];
        }
        else {
            NSData *data = [self descriptionData];
            [sock writeData:data withTimeout:-1 tag:0];
            [self updateDelegate];
            // This read is so the server will get disconnect notice, no reads should
            // actually occur.  Found this out the hard way...
            [sock readDataToLength:4 withTimeout:-1 tag:0];
        }
    }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
    NSString *incomingString = nil;
    switch (tag) {
    case 0:
        break;
    case 1:
        incomingString = [[NSString alloc] initWithData:data
                                           encoding:NSASCIIStringEncoding];
        NSArray *components = [incomingString componentsSeparatedByString:@":"];
        
        NSString *reply = [components objectAtIndex:1];
        NSData *data = nil;
        if ([reply isEqual:password]) {
            NSLog(@"Password match");

            [sock passwordAccepted];
            
            // Assume everything passed.
            data = [self descriptionData];
            [sock writeData:data withTimeout:-1 tag:0];
            [self updateDelegate];
            
            [sock readDataToLength:4 withTimeout:-1 tag:0];
            [incomingString release];
        }
        else {
            NSLog(@"Password didn't match");
            [sock incrementPasswordFailures];
            if ([sock passwordFailures] > 3) {
                data = [self passwordFailure];
                [sock writeData:data withTimeout:-1 tag:6];
                [sock disconnect];
            }
            else {
                data = [self passwordRequiredData];
                [sock writeData:data withTimeout:-1 tag:5];
                //                NSData *newline = [@"\n" dataUsingEncoding:NSASCIIStringEncoding];
                [sock readDataToData:[AsyncSocket LFData] withTimeout:-1 tag:1];
            }
        }
    }
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSString *sendString;
    NSData *data;
    switch (tag) {
    case 0:
        sendString = [NSString stringWithFormat:@"IMG:%d:\n",
                               sharedDataSize];
        data = [sendString dataUsingEncoding:NSASCIIStringEncoding];
        [sock writeData:data withTimeout:-1 tag:1];
		[sock writeData:sharedData withTimeout:-1 tag:2];
        break;
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
        break;
    default:
        NSLog(@"Uh Oh, wrote unknown tag: %d!", tag);
        break;
	}
}


@end

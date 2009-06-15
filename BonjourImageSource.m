//
//  BonjourImageSource.m
//  Gawker
//
//  Created by Phil Piwonka on 11/13/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "BonjourImageSource.h"
#import "AsyncSocket.h"
#import <netinet/in.h>

@interface BonjourImageSource (PrivateMethods)
- (BOOL)setIpAndPort;
@end

@implementation BonjourImageSource

- (id)initWithService:(NSNetService *)aNetService
{
    if (self = [super init]) {
        [self setSourceDescription:[aNetService name]];
        [self setSourceSubDescription:@"Bonjour"];
        netService = [aNetService retain];
    }

    return self;
}

- (void)dealloc
{
    [netService release];
    [super dealloc];
}

- (BOOL)setEnabled:(BOOL)enable
{
    BOOL wasSuccessful = YES;
    if (enable && ![self isEnabled]) {
        isEnabled = NO;
        wasSuccessful = [self setIpAndPort];
        if (wasSuccessful) {
            remoteSocket = [[AsyncSocket alloc] initWithDelegate:self];
            if ([remoteSocket connectToHost:ipAddress
                              onPort:remotePort
                              error:nil]) {
                NSLog(@"Connecting to %@:%d", ipAddress, remotePort);
                [self setSourceSubDescription:[NSString stringWithFormat:@"Bonjour - %@", ipAddress]];
                isEnabled = YES;
            }
        }
    }
    else if (!enable) {
        isEnabled = NO;
        [remoteSocket setDelegate:nil];
        [remoteSocket disconnect];
        [remoteSocket autorelease];
        remoteSocket = nil;
		
		[recentImage release];
        recentImage = nil;
    }

    return wasSuccessful;

}

@end

@implementation BonjourImageSource (PrivateMethods)

- (BOOL)setIpAndPort
{
    int i = 0;
    NSData *address;
    struct sockaddr *socketAddress;
    char buffer[256];
    BOOL status = NO;
    
    for (i = 0; i < [[netService addresses] count]; i++) {
        address = [[netService addresses] objectAtIndex:i];
        socketAddress = (struct sockaddr *)[address bytes];
        
        if (socketAddress->sa_family == AF_INET) {
            break;
        }
    }
    
    if (socketAddress) {
        switch(socketAddress->sa_family) {
        case AF_INET:
            if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer))) {
                ipAddress = [[NSString stringWithCString:buffer] retain];
                remotePort = ntohs(((struct sockaddr_in *)socketAddress)->sin_port);
            }
                
            status = YES;
            if (ipAddress && remotePort) {
                NSLog(@"Bonjour IP Address %@ Port %d", ipAddress, remotePort);
            }   
                    
            break;
        case AF_INET6:
            // We don't support IPv6
            NSLog(@"NetworkCamera -setIpAndPort: We don't support IPv6");
        }
    }
    return status;
}

@end

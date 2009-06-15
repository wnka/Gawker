//
//  ImageServer.h
//  Gawker
//
//  Created by Phil Piwonka on 10/9/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AsyncSocket;

@interface ImageServer : NSObject {
    NSString *serverDescription;

    NSImage *sharedImage;
    NSData *sharedData;
    UInt32 sharedDataSize;
    
    int serverPortNumber;
    NSNetService *bonjourAnnouncer;
    AsyncSocket *serverListenSocket;

    NSMutableArray *clients;

    BOOL isValid;

    BOOL limitUsers;
    int userLimit;

    BOOL requirePassword;
    NSString *password;

    id delegate;
}

- (id)initWithPortNumber:(int)portNum 
             description:(NSString *)description 
                delegate:(id)theDelegate;
- (id)init;

- (BOOL)setBonjourEnabled:(BOOL)enable;
- (BOOL)isBonjourEnabled;

- (NSString *)serverDescription;
- (void)setServerDescription:(NSString *)newDesc;

- (NSImage *)sharedImage;
- (void)setSharedImage:(NSImage *)newImage;

- (BOOL)limitUsers;
- (void)setLimitUsers:(BOOL)shouldLimit;

- (int)userLimit;
- (void)setUserLimit:(int)limit;

- (int)numConnected;
- (NSArray *)clients;

- (BOOL)requirePassword;
- (void)setRequirePassword:(BOOL)reqPass;

- (NSString *)password;
- (void)setPassword:(NSString *)newPass;

- (BOOL)isValid;
@end

@interface ImageServer (DelegateMethods)
- (void)imageServerUpdatedStats:(ImageServer *)server;
@end

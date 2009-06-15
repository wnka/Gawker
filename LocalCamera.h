//
//  LocalCamera.h
//  Gawker
//
//  Created by Phil Piwonka on 7/1/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Camera.h"

@class ImageServer;

@interface LocalCamera : Camera {
    IBOutlet NSTextField *saveFrameInterval;

    NSString *cameraName;

    NSTimer *shareTimer;
    ImageServer *imageServer;
    BOOL shareOnConnect;

    NSMutableDictionary *sharePreferences;

    BOOL releaseOnWindowClose;
}

- (id)init;
- (id)initWithCameraName:(NSString *)name;

- (void)dealloc;

- (void)setSourceEnabled:(BOOL)enable 
              openWindow:(BOOL)open 
                   share:(BOOL)share;
- (void)setSourceEnabled:(BOOL)enable openWindow:(BOOL)open;
- (BOOL)setSharingEnabled:(BOOL)enable;

- (BOOL)isSharing;
- (BOOL)isBonjourEnabled;
- (void)setBonjourEnabled:(BOOL)enable;

- (void)setSourceDescription:(NSString *)description;

- (int)sharePort;
- (void)setSharePort:(int)portNum;

- (int)numberOfConnectedClients;
- (NSArray *)connectedClients;

- (BOOL)limitUsers;
- (void)setLimitUsers:(BOOL)newLimit;

- (int)shareLimit;
- (void)setShareLimit:(int)newLimit;

- (int)shareInterval;
- (void)setShareInterval:(NSTimeInterval)newInterval;

- (BOOL)sharePasswordRequired;
- (void)setSharePasswordRequired:(BOOL)newReq;

- (NSString *)sharePassword;
- (void)setSharePassword:(NSString *)newPass;

- (NSString *)cameraName;

- (void)deviceDisconnected;

@end

@interface LocalCamera (ImageServerDelegateMethods)
- (void)imageServerUpdatedStats:(ImageServer *)server;
@end

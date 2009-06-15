//
//  LocalCamera.m
//  Gawker
//
//  Created by Phil Piwonka on 7/1/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "LocalCamera.h"

#import "CameraController.h"
#import "LocalCameraController.h"
#import "PreferenceController.h"
#import "SharePreferenceController.h"
#import "CameraPreferences.h"
#import "CameraFeaturesWindowController.h"
#import "CameraStatusView.h"
#import "ImageTransitionView.h"

#import "LapseMovie.h"
#import "ImageServer.h"

#import <QTKit/QTMovie.h>
#import <QTKit/QTKit.h>

@interface LocalCamera (PrivateMethods)
//
// Server Stuff
//
- (BOOL)startSharing;
- (void)stopSharing;

- (void)shareTimerFired:(NSTimer *)timer;

- (NSString *)connectMessage;
- (NSString *)connectErrorMessage;
- (NSString *)connectSuccessMessage;

//
// Record panel handlers
//
- (void)recordDidEnd:(NSSavePanel *)sheet returnCode:(int)code
            contextInfo:(void *)contextInfo;
@end

@implementation LocalCamera

- (id)init
{
    return [self initWithCameraName:[NSString stringWithString:@"Camera"]];
}

- (id)initWithCameraName:(NSString *)name
{
	self = [super initWithWindowNibName:@"LocalCamera"];

	if (self) {
        releaseOnWindowClose = NO;
        cameraName = [name retain];
		camController = [[LocalCameraController alloc] initWithDelegate:self
                                                       cameraName:cameraName];
        if (camController) {
            sharePreferences = 
                [[CameraPreferences prefs] prefsForDevice:cameraName];
            [self setSourceDescription:[sharePreferences objectForKey:WNKShareDescriptionKey]];

            icon = [[NSImage imageNamed:@"iSight"] retain];
            [[self window]
                setTitle:[NSString stringWithFormat:@"%@ - %@",
                                   [camController sourceSubDescription],
                                   [camController sourceDescription]]];
                                              
        }
        else {
            NSLog(@"Error allocating LocalCameraController!");
        }        
    }
	return self;
}

- (void)dealloc
{
    NSLog(@"LocalCamera -dealloc");
    if (timeToNextFrameTimer) {
        [timeToNextFrameTimer invalidate];
        [timeToNextFrameTimer release];
        timeToNextFrameTimer = nil;
    }
    [cameraName release];
    [self setSharingEnabled:NO];
    [super dealloc];
}

- (void)setSourceEnabled:(BOOL)enable openWindow:(BOOL)open share:(BOOL)share
{
    if (!enable) {
        [self setSharingEnabled:NO];
    }
    shareOnConnect = share;

    [super setSourceEnabled:enable openWindow:open];
}

- (void)setSourceEnabled:(BOOL)enable openWindow:(BOOL)open
{
    [self setSourceEnabled:enable openWindow:open share:NO];
}

- (void)setSourceDescription:(NSString *)description
{
    [imageServer setServerDescription:description];
    [camController setSourceDescription:description];

    [sharePreferences setObject:description
                      forKey:WNKShareDescriptionKey];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"UpdateCameraTable"
        object:self
        userInfo:nil];
    NSString *windowHeader = nil;
    if ([self isSharing]) {
        windowHeader = [NSString stringWithFormat:@"My Shared %@",
                        cameraName];
    }
    else {
        windowHeader = [NSString stringWithFormat:@"My %@",
                        cameraName];
    }
    [[self window]
        setTitle:[NSString stringWithFormat:@"%@ - %@",
                           windowHeader,
                           [camController sourceDescription]]];
}

- (void)scheduledStart:(NSTimer *)timer
{
    NSDictionary *scheduling = [[[startTimer userInfo] retain] autorelease];
    [super scheduledStart:timer];

    if ([self isRecording]) {
        double interval = [[scheduling objectForKey:SCHIntervalTag] floatValue];
        [(LocalCameraController *)camController captureFrameAtInterval:interval];        
    }
}

- (int)sharePort
{
    return [[sharePreferences objectForKey:WNKSharePortKey] intValue];
}

- (void)setSharePort:(int)portNum
{
    [sharePreferences setObject:[NSNumber numberWithInt:portNum]
                      forKey:WNKSharePortKey];
}

- (BOOL)isSharing
{
    return (imageServer) ? YES : NO;
}

- (BOOL)setSharingEnabled:(BOOL)state
{
    BOOL wasSuccessful = YES;
    if (state) {
        wasSuccessful = [self startSharing];
        if (wasSuccessful) {
            [[self window]
                setTitle:[NSString stringWithFormat:@"My Shared %@ - %@",
                                   cameraName,
                                   [camController sourceDescription]]];        
        }
    }
    else {
        [self stopSharing];
        [[self window]
            setTitle:[NSString stringWithFormat:@"My %@ - %@",
                               cameraName,
                               [camController sourceDescription]]];
    }
    if (wasSuccessful) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SharingChanged" object:self];
        //        [camFeaturesWindow updateSharingFields:state];
    }
    return wasSuccessful;
}

- (BOOL)isBonjourEnabled
{
    BOOL isEnabled = 
        [[sharePreferences objectForKey:WNKShareBonjourKey] boolValue];
    if (imageServer) {
        isEnabled = [imageServer isBonjourEnabled];
    }

    return isEnabled;
}

- (void)setBonjourEnabled:(BOOL)enable
{
    [imageServer setBonjourEnabled:enable];
    [sharePreferences setObject:[NSNumber numberWithBool:enable]
                      forKey:WNKShareBonjourKey];
}

- (int)numberOfConnectedClients
{
    int numConnected = 0;
    if ([self isSharing]) {
        numConnected = [imageServer numConnected];
    }

    return numConnected;
}

- (NSArray *)connectedClients
{
    NSArray *clients = nil;
    if ([self isSharing]) {
        clients = [imageServer clients];
    }

    return clients;
}

- (BOOL)limitUsers
{
    BOOL isLimit =
        [[sharePreferences objectForKey:WNKShareLimitKey] boolValue];
    if (imageServer) {
        isLimit = [imageServer limitUsers];
    }
    return isLimit;
}

- (void)setLimitUsers:(BOOL)newLimit
{
    if (imageServer) {
        [imageServer setLimitUsers:newLimit];
    }

    [sharePreferences setObject:[NSNumber numberWithBool:newLimit]
                      forKey:WNKShareLimitKey];
}

- (int)shareLimit
{
    int limit = [[sharePreferences objectForKey:WNKShareLimitNumKey] intValue];
    if (imageServer) {
        limit = [imageServer userLimit];
    }
    return limit;
}

- (void)setShareLimit:(int)limit
{
    if (imageServer) {
        [imageServer setUserLimit:limit];
    }

    [sharePreferences setObject:[NSNumber numberWithInt:limit]
                      forKey:WNKShareLimitNumKey];
}

- (int)shareInterval
{
    return [[sharePreferences objectForKey:WNKShareFrequencyKey] intValue];
}

- (void)setShareInterval:(NSTimeInterval)newInterval;
{
    if ([self isSharing]) {
        if (shareTimer && newInterval != [shareTimer timeInterval]) {
            NSLog(@"Changing share timer to %.1f",
                  newInterval);
            [shareTimer invalidate];
            [shareTimer release];
            shareTimer = [[NSTimer scheduledTimerWithTimeInterval:newInterval
                                   target:self
                                   selector:@selector(shareTimerFired:)
                                   userInfo:nil
                                   repeats:YES] retain];
            if (!shareTimer) {
                NSLog(@"Error with share timer alloc!");
            }
        }
    }
    // FIXME accepting double, storing int?
    [sharePreferences setObject:[NSNumber numberWithInt:newInterval]
                      forKey:WNKShareFrequencyKey];
}

- (BOOL)sharePasswordRequired
{
    return [[sharePreferences objectForKey:WNKShareUsePasswordKey] boolValue];
}

- (void)setSharePasswordRequired:(BOOL)newReq
{
    if (imageServer) {
        [imageServer setRequirePassword:newReq];
    }

    NSLog(@"Setting sharePasswordRequired");

    [sharePreferences setObject:[NSNumber numberWithBool:newReq]
                      forKey:WNKShareUsePasswordKey];
}

- (NSString *)sharePassword
{
    return [sharePreferences objectForKey:WNKSharePasswordKey];
}
- (void)setSharePassword:(NSString *)newPass
{
    if (imageServer) {
        [imageServer setPassword:newPass];
    }

    NSLog(@"Setting sharePassword");
    
    [sharePreferences setObject:newPass
                      forKey:WNKSharePasswordKey];
}

- (NSString *)cameraName
{
    return cameraName;
}

- (void)deviceDisconnected
{
    [camFeaturesWindow close];
    if ([self isSourceEnabled]) {
        [imageTransitionView setAcceptUpdates:NO];
        [moreButton setEnabled:NO];
        NSBeep();
        [self showWindow:nil];
        [self retain];
        [self setSourceEnabled:NO];
        [recordButton setEnabled:NO];
        [camStatusView showErrorMessage:@"This device has been unplugged and is no longer available."
                       showButton:NO];
        releaseOnWindowClose = YES;
    }
    
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    if (releaseOnWindowClose) {
        releaseOnWindowClose = NO;
        NSLog(@"Releasing bonjourCamera");
        [self autorelease];
    }
}

@end

@implementation LocalCamera (ImageServerDelegateMethods)
- (void)imageServerUpdatedStats:(ImageServer *)server
{
    NSLog(@"In imageServerUpdatedStats");
    if ([imageServer limitUsers] == 0) {
        [camController setSourceSubDescription:
                           [NSString stringWithFormat:@"My Shared %@ [%d]",
                                     cameraName,
                                     [imageServer numConnected]]];
    }
    else {
        [camController setSourceSubDescription:
                           [NSString stringWithFormat:@"My Shared %@ [%d/%d]",
                                     cameraName,
                                     [imageServer numConnected],
                                     [imageServer userLimit]]];
    }
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"UpdateCameraTable"
        object:self];
    [nc postNotificationName:@"SharingStatsChanged"
        object:self];
}
@end

@implementation LocalCamera (DelegateMethods)

- (void)cameraControllerConnected:(CameraController *)controller
{
    [super cameraControllerConnected:controller];
    
    if (shareOnConnect) {
        [self setSharingEnabled:YES];
        shareOnConnect = NO;
    }
}

- (void)cameraControllerDisconnected:(CameraController *)controller
{
    [super cameraControllerDisconnected:controller];
    
    if (shareOnConnect) {
        shareOnConnect = NO;        
    }
}

@end

@implementation LocalCamera (PrivateMethods)

- (BOOL)startSharing
{
    BOOL wasSuccessful = NO;
    
    int port = [[sharePreferences objectForKey:WNKSharePortKey] intValue];
    NSString *desc = [sharePreferences objectForKey:WNKShareDescriptionKey];
    BOOL enableBonjour = [[sharePreferences objectForKey:WNKShareBonjourKey] boolValue];
    int interval = [[sharePreferences objectForKey:WNKShareFrequencyKey] intValue];
    int userLimit = [[sharePreferences objectForKey:WNKShareLimitNumKey] intValue];
    BOOL limitUsers = [[sharePreferences objectForKey:WNKShareLimitKey] boolValue];
    BOOL requirePassword = [[sharePreferences objectForKey:WNKShareUsePasswordKey] boolValue];
    
    NSString *password = [sharePreferences objectForKey:WNKSharePasswordKey];

    NSLog(@"Starting to share with description: %@\nport: %d interval: %d",
          desc, port, interval);

    //
    // Create Image Server
    imageServer = [[ImageServer alloc] initWithPortNumber:port
                                       description:desc
                                       delegate:self];
    if ([imageServer isValid]) {
        [imageServer setLimitUsers:limitUsers];
        [imageServer setUserLimit:userLimit];
        [imageServer setBonjourEnabled:enableBonjour];
        [imageServer setRequirePassword:requirePassword];
        [imageServer setPassword:password];
        wasSuccessful = YES;
        //
        // Start timer for sharing
        shareTimer = [[NSTimer scheduledTimerWithTimeInterval:interval
                               target:self
                               selector:@selector(shareTimerFired:)
                               userInfo:nil
                               repeats:YES] retain];
        
        [imageServer setSharedImage:[camController recentImage]];

    }
    else {
        [imageServer release];
        imageServer = nil;
        NSLog(@"Unable to initialize Image Server");
        NSString *errString = 
            [NSString stringWithFormat:@"Could not share %@ on port %d",
                      desc, port];
        NSRunAlertPanel(errString,
                        @"Is something else using this port?",
                        @"OK", nil, nil);
    }

    return wasSuccessful;
}

- (void)stopSharing
{
    [shareTimer invalidate];
    [shareTimer release];
    shareTimer = nil;
    [imageServer release];
    imageServer = nil;
    NSString *newSubDesc = [NSString stringWithFormat:@"My %@", cameraName];
    [camController setSourceSubDescription:newSubDesc];
}

- (void)shareTimerFired:(NSTimer *)timer
{
    [imageServer setSharedImage:[camController recentImage]];    
}

- (NSString *)connectMessage
{
    return [NSString stringWithFormat:@"Connecting to %@...",
                     [self cameraName]];
}

- (NSString *)connectErrorMessage
{
    return [NSString stringWithFormat:@"Could not enable your %@!  Ensure it's not already in use.",
                     [self cameraName]];
}

- (NSString *)connectSuccessMessage
{
    return [NSString stringWithFormat:@"%@ Enabled",
                     [self cameraName]];
}


//
// Record panel handlers
//
- (void)recordDidEnd:(NSSavePanel *)sheet
          returnCode:(int)code
         contextInfo:(void *)contextInfo
{
    [super recordDidEnd:sheet
           returnCode:code
           contextInfo:contextInfo];

    if ([camController isRecording]) {
        double interval = [saveFrameInterval floatValue];
        [(LocalCameraController *)camController captureFrameAtInterval:interval];
    }
}

- (void)windowDidLoad
{
    [[self window] setFrameAutosaveName:@"LocalCamera"];
}

- (void)windowDidMove:(NSNotification *)note
{
    [[self window] saveFrameUsingName:@"LocalCamera"];
    [super windowDidMove:note];
}

@end


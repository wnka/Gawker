//
//  BonjourCamera.m
//  Gawker
//
//  Created by Phil Piwonka on 11/20/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "BonjourCamera.h"
#import "BonjourCameraController.h"
#import "CameraStatusView.h"
#import "ImageTransitionView.h"

@interface BonjourCamera (PrivateMethods)
- (NSString *)connectMessage;
- (NSString *)connectErrorMessage;
- (NSString *)connectSuccessMessage;
@end

@implementation BonjourCamera
- (id)initWithService:(NSNetService *)aNetService
{
    if (self = [super initWithWindowNibName:@"NetworkCamera"]) {
        openOnConnect = NO;
        releaseOnWindowClose = NO;
        camController = 
            [[BonjourCameraController alloc] initWithService:aNetService
                                             delegate:self];
        netService = [aNetService retain];

        icon = [[NSImage imageNamed:@"bonjour.png"] retain];
        
        [[self window] setTitle:[aNetService name]];
    }

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib]; 
    [passwordHeader setStringValue:[NSString stringWithFormat:@"Password required to view \"%@\"",
                                             [netService name]]];
    [passwordIcon setImage:[NSImage imageNamed:@"NSApplicationIcon"]];
}

- (void)dealloc
{
    NSLog(@"BonjourCamera -dealloc");
    [netService release];
    [super dealloc];
}

- (NSNetService *)netService
{
    return netService;
}

- (void)serviceDidShutdown
{
    [camFeaturesWindow close];
    if ([self isSourceEnabled] || [[self window] isVisible]) {
        [imageTransitionView setAcceptUpdates:NO];
        [moreButton setEnabled:NO];
        NSBeep();
        [self showWindow:nil];
        [self retain];
        [self setSourceEnabled:NO];
        [recordButton setEnabled:NO];
        [camStatusView showErrorMessage:@"This bonjour camera is no longer available" 
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

@implementation BonjourCamera (DelegateMethods)

- (void)cameraControllerDisconnected:(CameraController *)controller
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [self showEnableError];
    [recordButton setEnabled:NO];
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
    [nc postNotificationName:@"EnabledStatusChanged" object:self];
}

@end

@implementation BonjourCamera (PrivateMethods)

- (NSString *)connectMessage
{
    return [NSString stringWithFormat:@"Connecting to %@...",
                     [[self netService] name]];
}

- (NSString *)connectErrorMessage
{
    NSString *connection = (hasConnected) ? @"Disconnected from"
        : @"Could not connect to";
    return [NSString stringWithFormat:@"%@ %@ - %@",
                     connection,
                     [[self netService] name],
                     [self sourceDescription]];
}

- (NSString *)connectSuccessMessage
{
    return [NSString stringWithFormat:@"Connected to %@",
                     [[self netService] name]];
}

@end

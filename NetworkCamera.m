//
//  NetworkCamera.m
//  Gawker
//
//  Created by Phil Piwonka on 7/30/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "NetworkCamera.h"
#import "CameraController.h"
#import "NetworkCameraController.h"
#import "PreferenceController.h"
#import "ImageTransitionView.h"
#import "CameraStatusView.h"

@interface NetworkCamera (PrivateMethods)

- (NSString *)connectMessage;
- (NSString *)connectErrorMessage;
- (NSString *)connectSuccessMessage;

@end

@implementation NetworkCamera

- (id)initWithIp:(NSString *)address port:(UInt16)aPort
{
    self = [super initWithWindowNibName:@"NetworkCamera"];
    
    if (self) {
        openOnConnect = NO;
        ipAddress = [address retain];
        remotePort = aPort;
        camController = [[NetworkCameraController alloc] initWithIp:ipAddress
                                                         port:remotePort
                                                         delegate:self];
        icon = [[NSImage imageNamed:@"internet.png"] retain];
        
        [[self window] setTitle:ipAddress];
    }
    
    return self;
}

- (id)init
{
    return [self initWithIp:nil port:0];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [imageTransitionView setAnimate:YES];
    [passwordHeader setStringValue:[NSString stringWithFormat:@"Password required to view %@",
                                             ipAddress]];
    [passwordIcon setImage:[NSImage imageNamed:@"NSApplicationIcon"]];    
}

- (void)setSourceEnabled:(BOOL)enable openWindow:(BOOL)open
{
    hasConnected = NO;
    [super setSourceEnabled:enable openWindow:open];
}

- (void)dealloc
{
    NSLog(@"NetworkCamera -dealloc");
    [ipAddress release];
    [super dealloc];
}

- (IBAction)passwordOk:(id)sender
{
    [[camController imageSource] usePassword:[passwordFromUser stringValue]];
    [passwordWindow close];
}

- (IBAction)passwordCancel:(id)sender
{
    [[camController imageSource] usePassword:nil];
    [passwordWindow close];
}

@end


@implementation NetworkCamera (PrivateMethods)

- (NSString *)connectMessage
{
    return [NSString stringWithFormat:@"Connecting to %@...",
                     ipAddress];
}

- (NSString *)connectErrorMessage
{
    NSString *connection = (hasConnected) ? @"Disconnected from"
        : @"Could not connect to";
    return [NSString stringWithFormat:@"%@ %@ - %@",
                     connection,
                     ipAddress,
                     [self sourceDescription]];
}

- (NSString *)connectSuccessMessage
{
    return [NSString stringWithFormat:@"Connected to %@ - %@",
                     ipAddress,
                     [self sourceDescription]];
}

- (void)windowDidLoad
{
    [[self window] setFrameAutosaveName:@"NetworkCamera"];
}

- (void)windowDidMove:(NSNotification *)note
{
    [[self window] saveFrameUsingName:@"NetworkCamera"];
    [super windowDidMove:note];
}

@end

@implementation NetworkCamera (DelegateMethods)
- (void)cameraController:(CameraController *)controller
             hasNewImage:(NSImage *)anImage
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL doFancyTransitions = [defaults boolForKey:WNKDoFancyTransitionsKey];
    [imageTransitionView setAnimate:doFancyTransitions];
    [imageTransitionView setImage:anImage];
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
}

- (void)cameraControllerConnected:(CameraController *)controller
{
    hasConnected = YES;
    [super cameraControllerConnected:controller];
}

- (void)cameraControllerNewDescription:(CameraController *)controller
{
    [[self window] setTitle:[NSString stringWithFormat:@"%@ - %@",
                                      [camController sourceSubDescription],
                                      [camController sourceDescription]]];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
    [nc postNotificationName:@"EnabledStatusChanged" object:self];
}

- (void)cameraControllerNeedsPassword:(CameraController *)controller
{
    NSLog(@"in cameraControllerNeedsPassword:");
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"UpdateCameraTable" object:self];    
    [passwordWindow makeKeyAndOrderFront:nil];
}
@end

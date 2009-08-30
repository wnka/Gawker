//
//  MainWindow.m
//  Gawker
//
//  Created by Phil Piwonka on 7/24/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "MainWindow.h"
#import "Camera.h"
#import "LocalCamera.h"
#import "NetworkCamera.h"
#import "BonjourCamera.h"
#import "CombinedCamera.h"
#import "ScreenCamera.h"
#import "FireWireNotifier.h"
#import "USBNotifier.h"
#import "PreferenceController.h"
#import "CameraPreferences.h"
#import "AppController.h"
#import "CameraMenuButton.h"
#import "CameraManager.h"
#import <QuickTime/QuickTime.h>

@interface MainWindow (BonjourDelegation)
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
		  didRemoveDomain:(NSString *)domainString 
			   moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
		   didFindService:(NSNetService *)aNetService 
			   moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
		 didRemoveService:(NSNetService *)aNetService 
			   moreComing:(BOOL)moreComing;
- (void)netService:(NSNetService *)sender 
	 didNotResolve:(NSDictionary *)errorDict;
- (void)netServiceDidResolveAddress:(NSNetService *)sender;
- (void)netServiceWillResolve:(NSNetService *)sender;
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser;
@end

@interface MainWindow (TableDelegation)
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)row;
- (NSAttributedString *)stringForCameraDescription:(int)row;
@end

@interface MainWindow (ComboBoxDataSource)
- (NSString *)comboBox:(NSComboBox *)aComboBox 
       completedString:(NSString *)uncompletedString;
- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index;
@end

@interface MainWindow (PrivateMethods)
//
// Notification Handlers
//
- (void)updateCameraTable:(NSNotification *)note;
- (void)toggleBonjourBrowsing:(NSNotification *)note;

- (void)startBonjourBrowsing;
- (void)stopBonjourBrowsing;

- (void)connectToIp:(NSString *)ip port:(int)port;
- (NSArray *)validateInternetAddressFormat:(NSString *)netString;
- (NSArray *)getSelectedCameras;

- (void)createTextAttributes;
- (NSMutableArray *)availableInputs;

- (void)addNewInputs:(id)notifier;
- (void)removeInputNamed:(NSString *)name;
@end

@implementation MainWindow

- (id)init
{
	if (self = [super init]) {

        // This event causes autorelease pools to clean up their memory
        // even if the program is inactive (i.e. no events from user).  
        // Otherwise, we run out of memory.
        // ** 6/14/06 it appears as though this isn't needed anymore,
        //    this probably was NOT the problem but instead I had a memory
        //    leak that's now fixed.
        //    [NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod:10.0];
        
        [self createTextAttributes];
        
        //
        // NSComboBox datasource
        //
        recentConnections = [[NSMutableArray alloc] init];
        [recentConnections addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:WNKNetConnectHistoryKey]];
        
		availableCameras = [[NSMutableArray alloc] init];

        //
        // Register for notifications.
        //
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
            selector:@selector(updateCameraTable:)
            name:@"UpdateCameraTable"
            object:nil];

        [nc addObserver:self
            selector:@selector(toggleBonjourBrowsing:)
            name:@"UpdateBonjourBrowsing"
            object:nil];	
    }
	
	return self;
}

- (void)awakeFromNib
{
    [availableCamerasTable setTarget:self];
    [availableCamerasTable setDoubleAction:@selector(openCamera:)];

    [menuButton setCameraMenu:cameraMenu];

    NSTableColumn *connectButtonColumn =
        [availableCamerasTable tableColumnWithIdentifier:@"connect"];

    if (connectButtonColumn) {
        NSButtonCell *tableConnectButton = [connectButtonColumn dataCell];
        [tableConnectButton setTarget:self];
        [tableConnectButton setAction:@selector(toggleCameraEnabled:)];
    }
    else {
        NSLog(@"NIL connectButtonColumn");
    }

    // For now, ScreenCamera doesn't really work all that well.
    ScreenCamera *screenCam = [[ScreenCamera alloc] init];
    [availableCameras insertObject:screenCam atIndex:0];
    [screenCam release];

    //
    // Listen for device connect/disconnect notifications.
    //
    fireWireNotifier = [[FireWireNotifier alloc] initWithDelegate:(id)self];
    usbNotifier = [[USBNotifier alloc] initWithDelegate:(id)self];
    
    //
    // Add all available cameras.  We COULD let the fireWireNotifier do this,
    // however it detects things based on channels, which if another program
    // is using the camera (iChat, etc) it will not be in the channel list.
    // We use the VideoDigitizer list to get all the available inputs.
    // This all relies on the fact that the FireWire device name,
    // VideoDigitizer, and Channel device/input have the same name.  This might
    // not be true, but it has been in all cases I have seen.
    //
    NSArray *inputs = [self availableInputs];
    NSEnumerator *inputEnum = [inputs objectEnumerator];
    NSString *inputName = nil;
    while (inputName = [inputEnum nextObject]) {
        NSLog(@"Creating Camera For Device: %@", inputName);
        LocalCamera *localCamera = 
            [[LocalCamera alloc] initWithCameraName:inputName];
        
        if (!localCamera) {
            NSLog(@"Could not create localCamera");
            continue;
        }
        [availableCameras insertObject:localCamera atIndex:0];
        [fireWireNotifier watchDeviceForDisconnect:inputName];
        [usbNotifier watchDeviceForDisconnect:inputName];
        [localCamera release];        
    }

    //
    // Begin Bonjour Browsing.
    //
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:WNKDoBonjourBrowsingKey]) {
        [self startBonjourBrowsing];
    }

    [availableCamerasTable reloadData];
}

- (void)dealloc
{
    [[CameraPreferences prefs] updatePrefs];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:recentConnections
              forKey:WNKNetConnectHistoryKey];

    [recentConnections release];
    
	[NSEvent stopPeriodicEvents];
	if (availableCameras) {
        [availableCameras
            makeObjectsPerformSelector:@selector(closeCameraFeaturesWindow)];
            
        [availableCameras 
            makeObjectsPerformSelector:@selector(setSourceEnabled:)
            withObject:NO];
		[availableCameras release];
	}
	if (camBrowser) {
		[camBrowser release];
	}

    [topLineTextAttributes release];
    [topSelectedTextAttributes release];
    [topLineDisconnectedTextAttributes release];
    [botLineTextAttributes release];
    [botSelectedTextAttributes release];
    [botLineDisconnectedTextAttributes release];
    
    [fireWireNotifier release];
    [usbNotifier release];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];

	[super dealloc];
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    [self release];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    BOOL areRecording = NO;
    BOOL areSharing = NO;
    NSEnumerator *camEnum = [availableCameras objectEnumerator];
    Camera *cam = nil;
    NSMutableString *shouldQuit = [NSMutableString stringWithCapacity:256];
    
    while (cam = [camEnum nextObject]) {
        if (!areSharing && [cam isKindOfClass:[LocalCamera class]]) {
            int numClients = [(LocalCamera *)cam numberOfConnectedClients];
            if (numClients > 0) {
                if ([shouldQuit length] > 0) {
                    [shouldQuit appendString:@"\n"];
                }
                NSString *temp =
                    [NSString stringWithFormat:@"You have %d client%@ connected to your shared camera.", 
                              numClients,
                              (numClients == 1) ? @"" : @"s"];
                [shouldQuit appendString:temp];
                areSharing = YES;
            }
        }
        
        if (!areRecording && [cam isRecording]) {
            if ([shouldQuit length] > 0) {
                [shouldQuit appendString:@"\n"];
            }
            [shouldQuit appendString:@"You have cameras that are recording."];
            areRecording = YES;
        }

        if (areSharing && areRecording) {
            break;
        }
    }

    NSApplicationTerminateReply shouldTerm = NSTerminateNow;
    if (areRecording || areSharing) {
        NSBeep();
        int choice = NSRunAlertPanel(@"Are you sure you want to quit?",
                                     shouldQuit,
                                     @"Quit",@"Cancel",nil);
        if (choice != NSAlertDefaultReturn) {
            shouldTerm = NSTerminateCancel;
        }
    }
    
    return shouldTerm;
}

- (void)openCamera:(id)sender
{
	int index = [availableCamerasTable selectedRow];
	if (index < 0) {
		return;
	}

    Camera *camToOpen = [availableCameras objectAtIndex:index];
    if ([camToOpen isSourceEnabled]) {
        [camToOpen showWindow:nil];
    }
    else {
        [camToOpen setSourceEnabled:YES openWindow:YES];
    }
}

- (void)toggleCameraEnabled:(id)sender
{
    Camera *selectedCam =
        [availableCameras objectAtIndex:[availableCamerasTable selectedRow]];

    if ([selectedCam isSourceEnabled]) {
        [selectedCam close];
        [selectedCam setSourceEnabled:NO];        
        if ([selectedCam isKindOfClass:[BonjourCamera class]] &&
            camBrowser == nil) {
            NSLog(@"Delete bonjour cam");
            // We disabled bonjour browsing while connected to
            // a bonjour camera.  Therefore, delete the camera from the list
            // otherwise it gets stuck there permanently.
            [availableCameras removeObject:selectedCam];
        }
    }
    else {
        BOOL openWindow = 
            [[NSUserDefaults standardUserDefaults] boolForKey:WNKOpenOnConnectKey];
        [selectedCam setSourceEnabled:YES openWindow:openWindow];
    }
    
    [self updateCameraTable:nil];
}

- (void)toggleCameraShared:(id)sender
{
    if ([availableCamerasTable numberOfSelectedRows] != 1) {
        NSBeep();
        NSLog(@"Can only toggle sharing on one local camera at a time!");
        return;
    }

    int row = [availableCamerasTable selectedRow];
    
    if ([[availableCameras objectAtIndex:row] isKindOfClass:[LocalCamera class]]) {
        LocalCamera *selectedCam =
            [availableCameras objectAtIndex:row];
        if ([selectedCam isSharing]) {
            int choice = NSAlertDefaultReturn;
            int numClients = [selectedCam numberOfConnectedClients];
            if (numClients > 0) {
                NSBeep();
                choice = NSRunAlertPanel(@"Are you sure you want to stop sharing?",
                                         @"You have %d client%@ connected to your shared camera.", 
                                         @"Yes", @"No", nil,
                                         numClients,
                                         (numClients == 1) ? @"" : @"s");
            }

            if (choice == NSAlertDefaultReturn) {
                [selectedCam setSharingEnabled:NO];
            }
        }
        else {
            if (![selectedCam setSharingEnabled:YES]) {
                NSLog(@"Error starting sharing!");
            }
        }
    }
    else {
        NSLog(@"Can only share a local camera!");
    }
}

- (IBAction)openCameraFeatures:(id)sender
{
    NSLog(@"OpenFeatures");
    int row = [availableCamerasTable selectedRow];
    
    Camera *selectedCam =
        [availableCameras objectAtIndex:row];
    [selectedCam showCameraFeaturesWindow:self];
}

- (IBAction)openInternetCamera:(id)sender
{
    NSString *connectTo = [sender stringValue];
    NSLog(@"selection index: %d opening Internet camera: %@",
          [sender indexOfSelectedItem],
          connectTo);

    //
    // Ensure a valid address format
    //
    NSArray *connectionComponents =
        [self validateInternetAddressFormat:connectTo];
    if (connectionComponents == nil) {
        NSLog(@"Invalid connection format!");
        return;
    }

    if ([sender indexOfSelectedItem] >= 0) {
        // User clicked.  Move selection to the top.
        // We can be certain that this string is a valid address format.
        [recentConnections exchangeObjectAtIndex:0 
                           withObjectAtIndex:[sender indexOfSelectedItem]];
    }
    else {
        BOOL shouldAdd = YES;
        
        //
        // If valid, ensure it's not already in the list.
        //
        NSEnumerator *recentEnum = [recentConnections objectEnumerator];
        NSString *recentString = nil;
        while (recentString = [recentEnum nextObject]) {
            if ([recentString isEqual:connectTo]) {
                shouldAdd = NO;
            }
        }
        
        if (shouldAdd) {
            [recentConnections insertObject:connectTo atIndex:0];
        }
    }

    int port = WNK_DEFAULT_PORT;
    if ([connectionComponents count] == 2) {
        port = [[connectionComponents objectAtIndex:1] intValue];
    }
        
    [self connectToIp:[connectionComponents objectAtIndex:0]
          port:port];
}

- (IBAction)openCombinedCamera:(id)sender
{
	NSLog(@"MainWindow openCombinedCamera: - number of open cameras %d",
		  [availableCameras count]);

    int numSelectedCameras = [availableCamerasTable numberOfSelectedRows];
	if (numSelectedCameras > 4) {
        NSBeep();
        NSRunAlertPanel(@"Too many cameras!",
                        @"Currently, 4 is the max.",
                        @"OK",
                        nil,nil);
		return;
	}
    
    NSArray *camsToCombine = [self getSelectedCameras];
    NSEnumerator *camEnum = [camsToCombine objectEnumerator];
    Camera *cam = nil;
    BOOL success = YES;
    while (cam = [camEnum nextObject]) {
        if (![cam isSourceEnabled]) {
            success = NO;
            break;
        }
    }

    if (!success) {
        NSBeep();
        NSRunAlertPanel(@"Can't combine using disabled camera",
                        @"Combining requires all cameras to be enabled.",
                        @"OK",
                        nil,nil);
    }
    else {
        CombinedCamera *compCam = 
            [[CombinedCamera alloc] initWithCameras:camsToCombine];
        
        [availableCameras addObject:compCam];
        [compCam release];
        [availableCamerasTable reloadData];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:WNKOpenOnConnectKey]) {
            [compCam showWindow:nil];
        }
    }
}

- (IBAction)deleteCamera:(id)sender
{
    int row = [availableCamerasTable selectedRow];
    Camera *cam = [availableCameras objectAtIndex:row];

    BOOL shouldDelete = YES;
    
    if ([cam isSourceEnabled]) {
        NSString *panelString = 
            [NSString stringWithFormat:@"Are you sure you want to remove \"%@\"?",
                      [cam sourceDescription]];
        NSBeep();
        int choice = 
            NSRunAlertPanel(panelString,
                            @"This camera will be disabled if it is removed.",
                            @"Yes", @"No", nil,
                            [cam sourceDescription]);
        if (choice != NSAlertDefaultReturn) {
            shouldDelete = NO;
        }
    }

    if (shouldDelete) {
        [cam close];
//        [cam setSourceEnabled:NO];
        [availableCameras removeObjectAtIndex:row];
        [self updateCameraTable:nil];
    }
}

- (IBAction)clearRecentConnections:(id)sender
{
    [recentConnections removeAllObjects];
}


- (void)fireWireDeviceAdded:(FireWireNotifier *)fwNote
{
    [self addNewInputs:fwNote];
}

- (void)fireWireDeviceRemoved:(FireWireNotifier *)fwNote name:(NSString *)device
{
    [self removeInputNamed:device];
}

- (void)usbDeviceAdded:(USBNotifier *)usbNote
{
    [self addNewInputs:usbNote];
}

- (void)usbDeviceRemoved:(USBNotifier *)usbNote name:(NSString *)device
{
    [self removeInputNamed:device];
}
@end

@implementation MainWindow (Network)

@end

@implementation MainWindow (BonjourDelegation)

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
		  didRemoveDomain:(NSString *)domainString 
			   moreComing:(BOOL)moreComing
{
    NSLog( @"Removing the domain %@", domainString );
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
		   didFindService:(NSNetService *)aNetService 
			   moreComing:(BOOL)moreComing
{
    NSLog(@"Adding %@", [aNetService name]);
    [aNetService resolveWithTimeout:5.0];
	
    BonjourCamera *bonjourCam =
        [[BonjourCamera alloc] initWithService:aNetService];
    [availableCameras addObject:bonjourCam];
    [bonjourCam release];
    if (!moreComing) {
        [self updateCameraTable:nil];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
		 didRemoveService:(NSNetService *)aNetService 
			   moreComing:(BOOL)moreComing
{
	NSLog(@"removing: %@", [aNetService name]);

    NSEnumerator *camEnum = [availableCameras objectEnumerator];
    id camToExamine = nil;
    while (camToExamine = [camEnum nextObject]) {
        if ([camToExamine isKindOfClass:[BonjourCamera class]]) {
            BonjourCamera *bonjourCam = camToExamine;
            if ([[bonjourCam netService] isEqual:aNetService]) {
                [camToExamine serviceDidShutdown];
                [availableCameras removeObject:camToExamine];
                [self updateCameraTable:nil];
                break;
            }
        }
    }
    
    if ( moreComing == NO ) {
		[self updateCameraTable:nil];
    }
}

- (void)netService:(NSNetService *)sender 
	 didNotResolve:(NSDictionary *)errorDict
{
    NSLog( @"There was an error while attempting to resolve %@.", 
		   [sender name] );
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog( @"successfully resolved address for %@ = %@", [sender name],
		   [sender hostName]);
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
    NSLog( @"Attempting to resolve address for %@.", [sender name] );
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
    if ( browser == camBrowser ) {
        // FIXME go through and remove all bonjour cameras
        // from availableCameras
    }
}

@end


@implementation MainWindow (TableDelegation)

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == (NSTableView *)availableCamerasTable) {
        return [availableCameras count];
    }
    else {
        return 0;
    }
}

// FIXME this function is way too long and the branching
// is horrible.  break out into functions.
- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)row
{
    if (aTableView == (NSTableView *)availableCamerasTable) {
        if ([[aTableColumn identifier] isEqual:@"image"]) {
            return [[availableCameras objectAtIndex:row] recentImage];
        }
        else if ([[aTableColumn identifier] isEqual:@"connect"]) {
            if ([[availableCameras objectAtIndex:row] isSourceEnabled]) {
                return [NSNumber numberWithInt:NSOnState];
            }
            else {
                return [NSNumber numberWithInt:NSOffState];
            }
        }
        else if ([[aTableColumn identifier] isEqual:@"description"]) {
            return [self stringForCameraDescription:row];
        }
        else if ([[aTableColumn identifier] isEqual:@"status"]) {
            if ([[availableCameras objectAtIndex:row] isRecording]) {
                return [NSImage imageNamed:@"recording.png"];
            }
            else if ([[availableCameras objectAtIndex:row] isScheduled]) {
                return [NSImage imageNamed:@"scheduled.png"];
            }
            else {
                return nil;
            }
        }
    }

    NSLog(@"Unknown column!");
    return nil;
}

- (NSAttributedString *)stringForCameraDescription:(int)row
{
    BOOL isSelectedRow = [availableCamerasTable isRowSelected:row] &&
        ([[NSApp mainWindow] firstResponder] == (NSResponder *)availableCamerasTable);

    id camera = [availableCameras objectAtIndex:row];
    
    BOOL isConnected = [camera isSourceEnabled];
    NSDictionary *topLineDict = nil;
    NSDictionary *botLineDict = nil;
    if (isSelectedRow) {
        // Row is selected
        topLineDict = topSelectedTextAttributes;
        botLineDict = botSelectedTextAttributes;
    }
    else if (isConnected) {
        // Row is connected
        topLineDict = topLineTextAttributes;
        botLineDict = botLineTextAttributes;
    }
    else {
        // Row is disconnected
        topLineDict = topLineDisconnectedTextAttributes;
        botLineDict = botLineDisconnectedTextAttributes;
    }

    NSString *mainString = [camera sourceDescription];
    if (!mainString) {
        mainString = [NSString stringWithString:@"Generic Camera"];
    }
    
    NSString *subString = [camera sourceSubDescription];
    if (!subString) {
        subString = [NSString stringWithString:@"Camera"];
    }

    NSAttributedString *topString = [[NSAttributedString alloc]
                                        initWithString:mainString
                                        attributes:topLineDict];

    NSString *tempBotString = [NSString stringWithFormat:@"\n%@",
                                        subString];

    NSAttributedString *botString = [[NSAttributedString alloc] 
                                        initWithString:tempBotString
                                        attributes:botLineDict];

    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] 
                                                init];
    
    [attrString appendAttributedString:topString];
    [topString release];
    [attrString appendAttributedString:botString];
    [botString release];
    
    return [attrString autorelease];
}

@end

@implementation MainWindow (ComboBoxDataSource)
- (NSString *)comboBox:(NSComboBox *)aComboBox 
       completedString:(NSString *)uncompletedString
{
    NSEnumerator *recentEnum = [recentConnections objectEnumerator];
    NSString *stringToMatch = nil;
    unsigned length = [uncompletedString length];
    while (stringToMatch = [recentEnum nextObject]) {
        if ([stringToMatch length] >= length) {
            if ([uncompletedString isEqual:[stringToMatch substringToIndex:length]]) {
                return stringToMatch;
            }
        }
    }
    return nil;
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [recentConnections count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
    return [recentConnections objectAtIndex:index];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    if ([menuItem action] == @selector(clearRecentConnections:)) {
        return YES;
    }

    int row = [availableCamerasTable selectedRow];
    if (row < 0) {
        return NO;
    }

    int numSelectedRows = [availableCamerasTable numberOfSelectedRows];

    id selectedCam = [availableCameras objectAtIndex:row];

    if (numSelectedRows == 1) {
        if ([menuItem action] == @selector(toggleCameraEnabled:)) {
            if ([selectedCam isSourceEnabled]) {
                [menuItem setState:NSOnState];
            }
            else {
                [menuItem setState:NSOffState];
            }
            return YES;
        }
        else if ([menuItem action] == @selector(openCamera:)) {
            return YES;
        }
        else if ([menuItem action] == @selector(openCameraFeatures:)) {
            return YES;
        }
        else if ([selectedCam isKindOfClass:[LocalCamera class]]) {
            if ([menuItem action] == @selector(openSharePrefs:)) {
                return YES;
            }
            else if ([menuItem action] == @selector(toggleCameraShared:) &&
                     [selectedCam isSourceEnabled]) {
                if ([selectedCam isSharing]) {
                    [menuItem setState:NSOnState];
                }
                else {
                    [menuItem setState:NSOffState];
                }
                return YES;
            }
        }
        else if ([selectedCam isMemberOfClass:[NetworkCamera class]] ||
                 [selectedCam isMemberOfClass:[CombinedCamera class]]) {
            if ([menuItem action] == @selector(deleteCamera:)) {
                return YES;
            }
        }
    }
    else if (numSelectedRows > 1) {
        if ([menuItem action] == @selector(openCombinedCamera:)) {
            return YES;
        }
    }
    return NO;
}

@end

@implementation MainWindow (PrivateMethods)
//
// Notification Methods
//
- (void)updateCameraTable:(NSNotification *)note;
{
    [availableCamerasTable reloadData];
}

- (void)toggleBonjourBrowsing:(NSNotification *)note
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL enable = [defaults boolForKey:WNKDoBonjourBrowsingKey];
    if (enable) {
        [self startBonjourBrowsing];
    }
    else if (camBrowser) {
        [self stopBonjourBrowsing];
    }
    
    [self updateCameraTable:nil];
}

- (void)startBonjourBrowsing
{
    NSLog(@"Enabling bonjour browsing");
	if (!camBrowser) {
		camBrowser = [[NSNetServiceBrowser alloc] init];
		[camBrowser setDelegate:self];
	}
	
	[camBrowser searchForServicesOfType:@"_lapse._tcp." 
								   inDomain:@""];
}

- (void)stopBonjourBrowsing
{
    NSLog(@"Disabling bonjour browsing");
    [camBrowser release];
    camBrowser = nil;
    
    NSEnumerator *camEnum = [availableCameras objectEnumerator];
    id camToExamine = nil;
    while (camToExamine = [camEnum nextObject]) {
        if (![camToExamine isSourceEnabled] &&
            [camToExamine isKindOfClass:[BonjourCamera class]]) {
            [availableCameras removeObject:camToExamine];
        }
    }
}

- (void)connectToIp:(NSString *)ip port:(int)port
{
    NSLog(@"Attemping to connect to %@:%d", ip, port);
    NetworkCamera *remoteCam = [[NetworkCamera alloc] initWithIp:ip
                                                    port:port];

    BOOL openWindow = 
        [[NSUserDefaults standardUserDefaults] boolForKey:WNKOpenOnConnectKey];

    [remoteCam setSourceEnabled:YES openWindow:openWindow];
    [availableCameras addObject:remoteCam];

    [remoteCam release];

    [self updateCameraTable:nil];
}

- (NSArray *)validateInternetAddressFormat:(NSString *)netString
{
    NSArray *returnValue = nil;
    
    //
    // We want to ensure that the user entered the format "host:port"
    // First, split on ":" and make sure there are no more than
    // 2 components
    //
    NSArray *components = [netString componentsSeparatedByString:@":"];
    
    NSLog(@"String has %d components", [components count]);

    int intValue;
    NSScanner *portScanner;
    
    switch ([components count]) {
    case 2:
        //
        // Make sure the 2nd value is numeric.
        //
        portScanner = [NSScanner scannerWithString:[components objectAtIndex:1]];
        if ([portScanner scanInt:&intValue] && ([portScanner isAtEnd])) {
            returnValue = components;
        }
        else {
            NSLog(@"Invalid port format!");
            returnValue = nil;
        }
        break;
    case 1:
        returnValue = components;
        break;
    default:
        NSBeep();
        NSRunAlertPanel(@"Error in Internet Address",
                        @"Address should be of the format: \"IpAddress:Port\"",
                        @"OK", nil, nil);
        returnValue = nil;
    }

    return returnValue;
}

- (NSArray *)getSelectedCameras
{
    NSIndexSet *selected = [availableCamerasTable selectedRowIndexes];
    
    NSMutableArray *camArray = [[NSMutableArray alloc] init];
    unsigned int bufSize = [selected count];
    unsigned int *buf = (unsigned int *) malloc(sizeof(unsigned int) *
                                                bufSize);
    NSRange range = NSMakeRange([selected firstIndex],
                                ([selected lastIndex]-[selected firstIndex]) + 1);
    
    [selected getIndexes:buf maxCount:bufSize inIndexRange:&range];
    int i;
    for (i = 0; i < bufSize; i++) {
        [camArray addObject:[availableCameras objectAtIndex:buf[i]]];
    }
	free(buf);
    
    return [camArray autorelease];
}

- (void)createTextAttributes
{
    // Setup text attribute dictionaries for the connected camera
    // table.
    NSMutableParagraphStyle *lineStyle = 
        [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        
    [lineStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [lineStyle setMinimumLineHeight:16.0];
    [lineStyle setMaximumLineHeight:16.0];

    topLineTextAttributes = [[NSMutableDictionary alloc] init];
    topSelectedTextAttributes = [[NSMutableDictionary alloc] init];
    topLineDisconnectedTextAttributes = [[NSMutableDictionary alloc] init];
    botLineTextAttributes = [[NSMutableDictionary alloc] init];
    botSelectedTextAttributes = [[NSMutableDictionary alloc] init];
    botLineDisconnectedTextAttributes = [[NSMutableDictionary alloc] init];

    NSString *fontName = @"Lucida Grande";
        
    [topLineTextAttributes setObject:[NSColor blackColor]
                           forKey:NSForegroundColorAttributeName]; 
    [topLineTextAttributes setObject:[NSFont fontWithName:fontName
                                             size:12.0]
                           forKey:NSFontAttributeName];
    [topLineTextAttributes setObject:lineStyle
                           forKey:NSParagraphStyleAttributeName];
    [topSelectedTextAttributes setObject:[NSColor whiteColor]
                               forKey:NSForegroundColorAttributeName];
    [topSelectedTextAttributes setObject:[NSFont fontWithName:fontName
                                                 size:12.0]
                               forKey:NSFontAttributeName];
    [topSelectedTextAttributes setObject:lineStyle
                               forKey:NSParagraphStyleAttributeName];
    [topLineDisconnectedTextAttributes setObject:[NSColor grayColor]
                                       forKey:NSForegroundColorAttributeName]; 
    [topLineDisconnectedTextAttributes setObject:[NSFont fontWithName:fontName
                                                         size:12.0]
                                       forKey:NSFontAttributeName];
    [topLineDisconnectedTextAttributes setObject:lineStyle
                                       forKey:NSParagraphStyleAttributeName];
        
    [botLineTextAttributes setObject:[NSColor grayColor]
                           forKey:NSForegroundColorAttributeName];
    [botLineTextAttributes setObject:[NSFont fontWithName:fontName
                                             size:10.0]
                           forKey:NSFontAttributeName];
    [botLineTextAttributes setObject:lineStyle
                           forKey:NSParagraphStyleAttributeName];        
    [botSelectedTextAttributes setObject:[NSColor whiteColor]
                               forKey:NSForegroundColorAttributeName];
    [botSelectedTextAttributes setObject:[NSFont fontWithName:fontName
                                                 size:10.0]
                               forKey:NSFontAttributeName];
    [botSelectedTextAttributes setObject:lineStyle
                               forKey:NSParagraphStyleAttributeName];
    [botLineDisconnectedTextAttributes setObject:[NSColor lightGrayColor]
                                       forKey:NSForegroundColorAttributeName];
    [botLineDisconnectedTextAttributes setObject:[NSFont fontWithName:fontName
                                                         size:10.0]
                                       forKey:NSFontAttributeName];
    [botLineDisconnectedTextAttributes setObject:lineStyle
                                       forKey:NSParagraphStyleAttributeName];        
    [lineStyle release];
}

- (NSMutableArray *)availableInputs
{
    NSMutableArray *theAvailableInputs = [NSMutableArray array];
    ComponentDescription vidDig;
    vidDig.componentType = videoDigitizerComponentType;
    vidDig.componentSubType = 0;
    vidDig.componentManufacturer = 0;
    vidDig.componentFlags = 0;
    vidDig.componentFlagsMask = 0;
    
    Component vd = 0;
    while (vd = FindNextComponent(vd, &vidDig)) {
    
        VideoDigitizerComponent vd2 = OpenComponent(vd);    
        Str255 outname;

		short count;
		VDGetNumberOfInputs(vd2, &count);
		while (count >= 0)
		{
			if (noErr != VDGetInputName(vd2, count, outname)) 
			{
				count--;
				continue;
			}
			
			NSString *name = [NSString stringWithCString:(char *)outname+1 length:outname[0]];
			[theAvailableInputs addObject:name];
			count--;
		}
		
        CloseComponent((ComponentInstance)vd2);
        CloseComponent((ComponentInstance)vd);
    }

    return theAvailableInputs;
}

- (void)addNewInputs:(id)notifier
{
    // 
    // To add a new device, we look at the available channels.
    // We could use the VideoDigitizer, however doing that while my
    // iSight was in use caused it to go nuts.  So, since the device
    // was just plugged in, we can probably get a SGNewChannel for it.
    // 
    NSMutableArray *channels = [CameraManager availableChannels];
    if (!channels) {
        return;
    }

    Camera *cam = nil;
    NSEnumerator *camEnum = [availableCameras objectEnumerator];
    while (cam = [camEnum nextObject]) {
        if ([cam isKindOfClass:[LocalCamera class]]) {
            LocalCamera *lCam = (LocalCamera *)cam;
            [channels removeObject:[lCam cameraName]];
        }
    }

    NSEnumerator *newCams = [channels objectEnumerator];
    NSString *newCam = nil;
    while (newCam = [newCams nextObject]) {
        NSLog(@"Creating Camera For Device: %@", newCam);
        LocalCamera *localCamera = 
            [[LocalCamera alloc] initWithCameraName:newCam];
        
        if (!localCamera) {
            NSLog(@"Could not create localCamera");
            continue;
        }
        [availableCameras insertObject:localCamera atIndex:0];
        [notifier watchDeviceForDisconnect:newCam];
        [localCamera release];        
    }

    [self updateCameraTable:nil];
}

- (void)removeInputNamed:(NSString *)name
{
    Camera *cam = nil;
    NSEnumerator *cams = [availableCameras objectEnumerator];
    while (cam = [cams nextObject]) {
        if ([cam isKindOfClass:[LocalCamera class]]) {
            LocalCamera *lCam = (LocalCamera*)cam;
            if ([[lCam cameraName] isEqual:name]) {
                NSLog(@"Removing device: %@", name);
                [lCam deviceDisconnected];
                [availableCameras removeObject:cam];
                [self updateCameraTable:nil];
                break;
            }
        }
    }
}

@end

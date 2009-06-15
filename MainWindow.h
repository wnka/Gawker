//
//  MainWindow.h
//  Gawker
//
//  Created by Phil Piwonka on 7/24/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LocalCamera;
@class FireWireNotifier;
@class USBNotifier;
@class CameraMenuButton;
@class AppController;

@interface MainWindow : NSObject {
    IBOutlet NSTableView *availableCamerasTable;

    IBOutlet NSComboBox *internetConnect;
    IBOutlet CameraMenuButton *menuButton;
    
    NSMutableArray *recentConnections;

	NSMutableArray *availableCameras;
	NSNetServiceBrowser *camBrowser;

    NSMutableString *xmlString;

    FireWireNotifier *fireWireNotifier;
    USBNotifier *usbNotifier;

    IBOutlet NSMenu *cameraMenu;
    IBOutlet AppController *appController;
    
    NSMutableDictionary *topLineTextAttributes;
    NSMutableDictionary *topSelectedTextAttributes;
    NSMutableDictionary *topLineDisconnectedTextAttributes;
    NSMutableDictionary *botLineTextAttributes;
    NSMutableDictionary *botSelectedTextAttributes;
    NSMutableDictionary *botLineDisconnectedTextAttributes;
}

- (id)init;
- (void)awakeFromNib;
- (void)dealloc;

//
// User Interface functions
//
- (IBAction)openCamera:(id)sender;
- (IBAction)toggleCameraEnabled:(id)sender;
- (IBAction)toggleCameraShared:(id)sender;
- (IBAction)openCameraFeatures:(id)sender;
- (IBAction)openInternetCamera:(id)sender;
- (IBAction)openCombinedCamera:(id)sender;
- (IBAction)deleteCamera:(id)sender;
- (IBAction)clearRecentConnections:(id)sender;
- (void)fireWireDeviceAdded:(FireWireNotifier *)fwNote;
- (void)fireWireDeviceRemoved:(FireWireNotifier *)fwNote
                         name:(NSString *)device;
- (void)usbDeviceAdded:(USBNotifier *)usbNote;
- (void)usbDeviceRemoved:(USBNotifier *)usbNote
                    name:(NSString *)device;
@end


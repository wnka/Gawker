//
//  CameraFeaturesWindowController.h
//  Gawker
//
//  Created by phil piwonka on 6/7/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *SCHFilenameTag;
extern NSString *SCHQualityTag;
extern NSString *SCHFrameScaleTag;
extern NSString *SCHFPSTag;
extern NSString *SCHTimeStampTag;
extern NSString *SCHIntervalTag;
extern NSString *SCHStartTimeTag;
extern NSString *SCHStopTimeTag;

@interface CameraFeaturesWindowController : NSWindowController {
    IBOutlet NSTabView *featureTabs;

    // General Pane
    IBOutlet NSTextField *generalDescriptionField;
    IBOutlet NSTextField *generalSourceField;
    IBOutlet NSTextField *generalEnableTime;

    // Schedule Pane
    IBOutlet NSView *scheduleMainView;
    IBOutlet NSView *scheduleNeedEnableView;

    IBOutlet NSTextField *scheduleStartTimeText;
    IBOutlet NSDatePicker *scheduleStartTime;
    IBOutlet NSTextField *scheduleStartTimeInfo;

    IBOutlet NSDatePicker *scheduleStopTime;
    IBOutlet NSTextField *scheduleStopTimeInfo;
    IBOutlet NSButton *scheduleStopTimeCheckbox;

    IBOutlet NSButton *scheduleEnableButton;
    IBOutlet NSButton *scheduleButton;
    IBOutlet NSBox *scheduleBox;

    IBOutlet NSProgressIndicator *scheduleEnableSpinner;

    NSDate *startDate;
    NSDate *stopDate;

    NSSavePanel *savePanel;
    NSView *saveAccessoryView;

    // Share Pane
    IBOutlet NSBox *shareStatusPortBox;
    IBOutlet NSView *shareStatusView;
    IBOutlet NSView *sharePortView;

    IBOutlet NSTextField *shareStatusField;
    IBOutlet NSProgressIndicator *spinner;
    IBOutlet NSTextField *shareDescription;
    IBOutlet NSButton *shareButton;
    IBOutlet NSTextField *shareExternalIPField;
    IBOutlet NSTextField *shareStartTimeField;

    IBOutlet NSTextField *shareIntervalField;
    IBOutlet NSButton *shareBonjourCheckbox;
    IBOutlet NSButton *shareLimitCheckbox;
    IBOutlet NSTextField *shareLimitNumberField;
    IBOutlet NSTextField *sharePortField;
    IBOutlet NSButton *sharePasswordCheckbox;
    IBOutlet NSTextField *sharePasswordField;

    IBOutlet NSTableColumn *shareConnectedClientCount;
    IBOutlet NSTableView *shareConnectedClientsTable;
    
    NSSize shareStatusViewSize;
    NSSize sharePortViewSize;
    BOOL externalIPFieldIsHidden;

    BOOL showSharing;
    BOOL canSetDescription;
    BOOL needsEnabledForScheduling;

    // Camera
    id myCamera;
    
    // For fetching external IP
    NSURLConnection *ipConnection;
    NSMutableData *ipFetchData;
}

- (id)initWithDelegate:(id)camera saveView:(NSView *)saveView;

// Sharing methods
- (IBAction)toggleSharing:(id)sender;

- (int)portField;
- (IBAction)changePortField:(id)sender;

- (NSString *)descriptionField;
- (IBAction)changeDescriptionField:(id)sender;

- (int)intervalField;
- (IBAction)changeIntervalField:(id)sender;

- (BOOL)bonjourCheckbox;
- (IBAction)changeBonjourCheckbox:(id)sender;

- (BOOL)bonjourCheckbox;
- (IBAction)changeBonjourCheckbox:(id)sender;

- (BOOL)limitCheckbox;
- (IBAction)changeLimitCheckbox:(id)sender;

- (int)limitNumField;
- (IBAction)changeLimitNumField:(id)sender;

- (BOOL)passwordCheckbox;
- (IBAction)changePasswordCheckbox:(id)sender;

- (NSString *)passwordField;
- (IBAction)changePasswordField:(id)sender;

// Scheduling methods
- (IBAction)setRecordOptions:(id)sender;
- (IBAction)setStopDateCheckbox:(id)sender;
- (IBAction)enableCamera:(id)sender;

@end

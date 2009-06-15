//
//  SharePreferenceController.h
//  Gawker
//
//  Created by Phil Piwonka on 12/26/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *WNKShareDeviceKey;
extern NSString *WNKSharePortKey;
extern NSString *WNKShareDescriptionKey;
extern NSString *WNKShareFrequencyKey;
extern NSString *WNKShareBonjourKey;
extern NSString *WNKShareLimitKey;
extern NSString *WNKShareLimitNumKey;
extern NSString *WNKSharePasswordKey;
extern NSString *WNKShareUsePasswordKey;

@class LocalCamera;

@interface SharePreferenceController : NSWindowController {
    IBOutlet NSTextField *portField;
    IBOutlet NSTextField *descriptionField;
    IBOutlet NSTextField *frequencyField;
    IBOutlet NSButton *bonjourCheckbox;
    IBOutlet NSButton *limitCheckbox;
    IBOutlet NSTextField *limitNumField;

    IBOutlet NSButton *fetchIPButton;
    IBOutlet NSTextField *externalIPField;
    IBOutlet NSTextField *internalIPField;

    IBOutlet NSButton *shareButton;
    IBOutlet NSTextField *shareStatusField;
    IBOutlet NSTextField *shareInfoField;

    LocalCamera *delegate;

    NSURLConnection *ipConnection;
    NSMutableData *ipFetchData;
}

- (id)initWithDelegate:(LocalCamera *)theDelegate;

- (int)portField;
- (IBAction)changePortField:(id)sender;

- (NSString *)descriptionField;
- (IBAction)changeDescriptionField:(id)sender;

- (int)frequencyField;
- (IBAction)changeFrequencyField:(id)sender;

- (BOOL)bonjourCheckbox;
- (IBAction)changeBonjourCheckbox:(id)sender;

- (BOOL)bonjourCheckbox;
- (IBAction)changeBonjourCheckbox:(id)sender;

- (BOOL)limitCheckbox;
- (IBAction)changeLimitCheckbox:(id)sender;

- (int)limitNumField;
- (IBAction)changeLimitNumField:(id)sender;

- (IBAction)fetchExternalIP:(id)sender;

- (NSString *)internalIPs;

@end

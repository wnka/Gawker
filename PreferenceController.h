//
//  PreferenceController.h
//  Gawker
//
//  Created by Phil Piwonka on 7/10/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define WNK_DEFAULT_PORT 7548
#define WNK_FONT_SIZE 12.0

extern NSString *WNKCheckForUpdates;
extern NSString *WNKOpenOnConnectKey;
extern NSString *WNKShowTimeToNextFrameKey;
extern NSString *WNKDoFancyTransitionsKey;
extern NSString *WNKDoBonjourBrowsingKey;

extern NSString *WNKDefaultRecordDirectoryKey;
extern NSString *WNKDefaultRecordFontKey;
extern NSString *WNKNetConnectHistoryKey;
extern NSString *WNKCamPreferencesKey;

@interface PreferenceController : NSWindowController {
    //
    // General Tab Outlets
    //
    IBOutlet NSButton *checkForUpdatesCheckbox;
    IBOutlet NSButton *openOnConnectCheckbox;
    IBOutlet NSButton *showTimeToNextFrameCheckbox;
    IBOutlet NSButton *doFancyTransitionsCheckbox;
    IBOutlet NSButton *doBonjourBrowsingCheckbox;
    
    //
    // Recording Tab Outlets
    //
    IBOutlet NSTextField *defaultRecordDirectoryField;
    IBOutlet NSTextField *defaultRecordFontField;
    IBOutlet NSImageView *defaultRecordFontPreview;

    IBOutlet NSTabView *tabView;
}

- (BOOL)checkForUpdatesCheckbox;
- (IBAction)changeCheckForUpdatesCheckbox:(id)sender;

- (BOOL)openOnConnectCheckbox;
- (IBAction)changeOpenOnConnectCheckbox:(id)sender;

- (BOOL)showTimeToNextFrameCheckbox;
- (IBAction)changeShowTimeToNextFrameCheckbox:(id)sender;

- (BOOL)doFancyTransitionsCheckbox;
- (IBAction)changeDoFancyTransitionsCheckbox:(id)sender;

- (BOOL)doBonjourBrowsingCheckbox;
- (IBAction)changeDoBonjourBrowsingCheckbox:(id)sender;

- (NSString *)defaultRecordDirectoryField;
- (void)changeDefaultRecordDirectoryField:(NSString *)newDir;
- (IBAction)openDirectoryChooser:(id)sender;

- (NSString *)defaultRecordFontField;
- (void)changeDefaultRecordFontField:(NSString *)newFont;
- (NSImage *)timePreviewWithFontName:(NSString *)newFont;
- (IBAction)openFontChooser:(id)sender;

@end

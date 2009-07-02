//
//  PreferenceController.m
//  Gawker
//
//  Created by Phil Piwonka on 7/10/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "PreferenceController.h"
#import "ImageText.h"

NSString *WNKCheckForUpdatesKey = @"SUEnableAutomaticChecks";
NSString *WNKOpenOnConnectKey = @"OpenOnConnect";
NSString *WNKShowTimeToNextFrameKey = @"ShowTimeToNextFrame";
NSString *WNKDoFancyTransitionsKey = @"DoFancyTransitions";
NSString *WNKDoBonjourBrowsingKey = @"DoBonjourBrowsing";

NSString *WNKDefaultRecordDirectoryKey = @"DefaultRecordDirectory";
NSString *WNKDefaultRecordFontKey = @"DefaultFontDirectory";
NSString *WNKNetConnectHistoryKey = @"NetConnectHistory";
NSString *WNKCamPreferencesKey = @"CamPreferences";

@implementation PreferenceController

- (id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	return self;
}

- (void)windowDidLoad
{
	NSLog(@"Preferences Nib file loaded");
    [checkForUpdatesCheckbox setState:[self checkForUpdatesCheckbox]];
    [openOnConnectCheckbox setState:[self openOnConnectCheckbox]];
    [showTimeToNextFrameCheckbox setState:[self showTimeToNextFrameCheckbox]];
    [doFancyTransitionsCheckbox setState:[self doFancyTransitionsCheckbox]];
    [doBonjourBrowsingCheckbox setState:[self doBonjourBrowsingCheckbox]];
    [defaultRecordDirectoryField setStringValue:[self defaultRecordDirectoryField]];
    [defaultRecordFontField setStringValue:[self defaultRecordFontField]];
    [defaultRecordFontPreview setImage:[self timePreviewWithFontName:[self defaultRecordFontField]]];
    [[self window] setDelegate:self];
}

- (BOOL)checkForUpdatesCheckbox
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:WNKCheckForUpdatesKey];
}

- (IBAction)changeCheckForUpdatesCheckbox:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[sender state]
              forKey:WNKCheckForUpdatesKey];
}

- (BOOL)openOnConnectCheckbox
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:WNKOpenOnConnectKey];
}

- (IBAction)changeOpenOnConnectCheckbox:(id)sender;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[sender state]
              forKey:WNKOpenOnConnectKey];
}

- (BOOL)showTimeToNextFrameCheckbox
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:WNKShowTimeToNextFrameKey];
}

- (IBAction)changeShowTimeToNextFrameCheckbox:(id)sender;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[sender state]
              forKey:WNKShowTimeToNextFrameKey];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"UpdateShowTimeToNextFrame" object:self];
}

- (BOOL)doFancyTransitionsCheckbox
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:WNKDoFancyTransitionsKey];
}

- (IBAction)changeDoFancyTransitionsCheckbox:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[sender state]
              forKey:WNKDoFancyTransitionsKey];
}

- (BOOL)doBonjourBrowsingCheckbox
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:WNKDoBonjourBrowsingKey];
}

- (IBAction)changeDoBonjourBrowsingCheckbox:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[sender state]
              forKey:WNKDoBonjourBrowsingKey];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"UpdateBonjourBrowsing" object:self];
}

- (NSString *)defaultRecordDirectoryField
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:WNKDefaultRecordDirectoryKey];
}

- (void)changeDefaultRecordDirectoryField:(NSString *)newDir
{
    
    [defaultRecordDirectoryField setStringValue:newDir];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[defaultRecordDirectoryField stringValue] stringByExpandingTildeInPath]
              forKey:WNKDefaultRecordDirectoryKey];
}

- (IBAction)openDirectoryChooser:(id)sender
{
    [NSEvent stopPeriodicEvents];
    NSOpenPanel *dirChooser = [NSOpenPanel openPanel];
    
    [dirChooser setCanChooseDirectories:YES];
    [dirChooser setCanChooseFiles:NO];
    
    int result = [dirChooser runModalForDirectory:[self defaultRecordDirectoryField]
                             file:nil
                             types:nil];
    
    if (result == NSOKButton) {
        [self changeDefaultRecordDirectoryField:[dirChooser directory]];
    }
    [NSEvent startPeriodicEventsAfterDelay:0 withPeriod:10];
}

- (NSString *)defaultRecordFontField
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:WNKDefaultRecordFontKey];
}

- (void)changeDefaultRecordFontField:(NSString *)newFont
{
    [defaultRecordFontField setStringValue:newFont];
 
    [defaultRecordFontPreview setImage:[self timePreviewWithFontName:newFont]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[defaultRecordFontField stringValue]
              forKey:WNKDefaultRecordFontKey];        
}

- (NSImage *)timePreviewWithFontName:(NSString *)newFont
{
    NSMutableDictionary *timeTextAttributes = 
        [[NSMutableDictionary alloc] init];
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize(1.1, -1.1)];
    [shadow setShadowBlurRadius:0.3];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0
                                    alpha:0.8]];
    
    [timeTextAttributes setObject:[NSColor whiteColor]
                        forKey:NSForegroundColorAttributeName];        
    [timeTextAttributes setObject:shadow
                        forKey:NSShadowAttributeName];
    [timeTextAttributes setObject:[NSFont fontWithName:newFont size:15.0]
                        forKey:NSFontAttributeName];
    [shadow release];
    NSImage *previewImage = 
        [ImageText roundedTextWithString:[ImageText timeString:[NSTimeZone localTimeZone]]
                   attributes:timeTextAttributes];
    [timeTextAttributes release];
    return previewImage;
}

- (IBAction)openFontChooser:(id)sender
{
    NSFont *existingFont = [NSFont fontWithName:[self defaultRecordFontField]
                                   size:25.0];
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager setDelegate:self];
    [fontManager orderFrontFontPanel:self];
    [fontManager setSelectedFont:existingFont
                 isMultiple:NO];
}

- (void)changeFont:(id)sender
{
    NSFont *existingFont = [NSFont fontWithName:[self defaultRecordFontField]
                                   size:25.0];
    NSFont *newFont = [sender convertFont:existingFont];
    [self changeDefaultRecordFontField:[newFont fontName]];
}

- (unsigned int)validModesForFontPanel:(NSFontPanel *)fontPanel
{
    return (NSFontPanelFaceModeMask & NSFontPanelStandardModesMask);
}
@end

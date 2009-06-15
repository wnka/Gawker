//
//  AppController.h
//  Gawker
//
//  Created by Phil Piwonka on 7/10/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PreferenceController;
@class SharePreferenceController;
@class AboutController;

@interface AppController : NSObject {
	PreferenceController *preferences;
    AboutController *about;

    IBOutlet NSWindow *window;
    IBOutlet NSWindow *aboutPanel;
}

- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)showAboutPanel:(id)sender;
@end

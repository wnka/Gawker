//
//  AppController.m
//  Gawker
//
//  Created by Phil Piwonka on 7/10/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "AppController.h"
#import "PreferenceController.h"
#import "SharePreferenceController.h"
#import "AboutController.h"

@implementation AppController

- (IBAction)showPreferencePanel:(id)sender
{
	if (!preferences) {
		preferences = [[PreferenceController alloc] init];
	}

	[preferences showWindow:self];
}

- (IBAction)showAboutPanel:(id)sender
{
    if (!about) {
        about = [[AboutController alloc] init];
    }

    [about showWindow:self];
}

- (void)dealloc
{
	[preferences release];
	[super dealloc];
}

+ (void)initialize
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];

    [defaultValues setObject:[NSNumber numberWithBool:YES]
                   forKey:WNKOpenOnConnectKey];

    [defaultValues setObject:[NSNumber numberWithBool:YES]
                   forKey:WNKShowTimeToNextFrameKey];

    [defaultValues setObject:[NSNumber numberWithBool:YES]
                   forKey:WNKDoFancyTransitionsKey];

    [defaultValues setObject:[NSNumber numberWithBool:YES]
                   forKey:WNKDoBonjourBrowsingKey];

    [defaultValues setObject:[[NSString stringWithString:@"~/Desktop"] stringByExpandingTildeInPath]
                   forKey:WNKDefaultRecordDirectoryKey];

    [defaultValues setObject:[[NSFont userFontOfSize:12.0] fontName]
                   forKey:WNKDefaultRecordFontKey];

    [defaultValues setObject:[NSNumber numberWithInt:WNK_DEFAULT_PORT]
                   forKey:WNKSharePortKey];

    [defaultValues setObject:NSFullUserName()
                   forKey:WNKShareDescriptionKey];

    [defaultValues setObject:[NSNumber numberWithInt:30]
                   forKey:WNKShareFrequencyKey];

    [defaultValues setObject:[NSNumber numberWithBool:YES]
                   forKey:WNKShareBonjourKey];

    [defaultValues setObject:[NSNumber numberWithBool:NO]
                    forKey:WNKShareLimitKey];

    [defaultValues setObject:[NSNumber numberWithInt:5]
                    forKey:WNKShareLimitNumKey];

    NSMutableArray *netHistory = [[NSMutableArray alloc] init];
    [netHistory addObject:[NSString stringWithString:@"localhost"]];

    [defaultValues setObject:netHistory
                   forKey:WNKNetConnectHistoryKey];

    [netHistory release];
    
    NSMutableArray *camPreferences = [[NSMutableArray alloc] init];
    [defaultValues setObject:camPreferences
                   forKey:WNKCamPreferencesKey];

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (void)awakeFromNib
{
    [window setFrameAutosaveName:@"MainMenu"];
}

- (void)windowDidMove:(NSNotification *)note
{
    [window saveFrameUsingName:@"MainMenu"];
}


@end

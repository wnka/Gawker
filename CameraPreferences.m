//
//  CameraPreferences.m
//  Gawker
//
//  Created by phil piwonka on 5/16/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "CameraPreferences.h"
#import "PreferenceController.h"
#import "SharePreferenceController.h"

@implementation CameraPreferences

+ (CameraPreferences *)prefs
{
    static CameraPreferences *camPrefs = nil;
    if (!camPrefs) {
        NSLog(@"Creating camPrefs instance");
        camPrefs = [[CameraPreferences alloc] init];
    }

    NSLog(@"CamPrefs: %@", [camPrefs cameraPrefs]);

    return camPrefs;
}

- (id)init
{
    if (self = [super init]) {
        cameraPrefs = [[NSMutableArray alloc] init];
        [cameraPrefs addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:WNKCamPreferencesKey]];
    }

    return self;
}

- (void)dealloc
{
    [cameraPrefs release];
    [super dealloc];
}

- (NSMutableArray *)cameraPrefs
{
    return cameraPrefs;
}

- (NSMutableDictionary *)prefsForDevice:(NSString *)devName
{
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] init];
    NSDictionary *camPrefs = nil;
    NSEnumerator *prefEnum = [cameraPrefs objectEnumerator];
    NSDictionary *validPrefs = nil;
    while (camPrefs = [prefEnum nextObject]) {
        if ([[camPrefs objectForKey:WNKShareDeviceKey] isEqual:devName]) {
            validPrefs = camPrefs;
            break;
        }
    }
    
    if (validPrefs) {
        NSLog(@"Found valid preferences for \"%@\"", devName);
        [prefs addEntriesFromDictionary:validPrefs];
        [cameraPrefs removeObject:validPrefs];
    }
    else {
        NSLog(@"\"%@\" not found, creating default preferences", devName);
        [prefs setObject:devName
               forKey:WNKShareDeviceKey];
        [prefs setObject:[NSNumber numberWithInt:7548]
               forKey:WNKSharePortKey];
        [prefs setObject:NSFullUserName()
               forKey:WNKShareDescriptionKey];
        [prefs setObject:[NSNumber numberWithInt:30]
               forKey:WNKShareFrequencyKey];
        [prefs setObject:[NSNumber numberWithBool:YES]
               forKey:WNKShareBonjourKey];
        [prefs setObject:[NSNumber numberWithBool:NO]
               forKey:WNKShareLimitKey];
        [prefs setObject:[NSNumber numberWithInt:10]
               forKey:WNKShareLimitNumKey];
        [prefs setObject:[NSString stringWithString:@""]
               forKey:WNKSharePasswordKey];
        [prefs setObject:[NSNumber numberWithBool:NO]
               forKey:WNKShareUsePasswordKey];
    }

    [cameraPrefs addObject:prefs];
    [prefs release];
    return prefs;
}

- (void)updatePrefs
{
    NSLog(@"Updating camera preferences.");
    [[NSUserDefaults standardUserDefaults] setObject:cameraPrefs
                                           forKey:WNKCamPreferencesKey];
}

@end

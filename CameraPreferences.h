//
//  CameraPreferences.h
//  Gawker
//
//  Created by phil piwonka on 5/16/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CameraPreferences : NSObject {
    NSMutableArray *cameraPrefs;
}

+ (CameraPreferences *)prefs;

- (id)init;
- (NSMutableArray *)cameraPrefs;
- (NSMutableDictionary *)prefsForDevice:(NSString *)devName;
- (void)updatePrefs;

@end

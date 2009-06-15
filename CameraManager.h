//
//  CameraManager.h
//  Gawker
//
//  Created by phil piwonka on 5/11/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>


@interface CameraManager : NSObject {

}

+ (BOOL)findCamera:(NSString *)cameraName 
       inComponent:(SeqGrabComponent)seqGrab
           channel:(SGChannel *)channel;

+ (NSMutableArray *)availableChannels;

@end

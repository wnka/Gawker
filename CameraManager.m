//
//  CameraManager.m
//  Gawker
//
//  Created by phil piwonka on 5/11/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "CameraManager.h"

@implementation CameraManager

+ (BOOL)findCamera:(NSString *)cameraName 
       inComponent:(SeqGrabComponent)seqGrab
           channel:(SGChannel *)channel
{
    OSErr theErr = noErr;

    BOOL wasSuccessful = NO;

    // Get a new channel
    theErr = SGNewChannel(seqGrab, VideoMediaType, channel);
    if (theErr != noErr) {
        NSLog(@"ComponentChannel couldn't get Channel: %lu", theErr);
        return NO;
    }

    // Get the device list for the channel (IIDC, USB, etc)
    SGDeviceList list = nil;
    theErr = SGGetChannelDeviceList(*channel, sgDeviceListIncludeInputs,
                                    &list);
    if (theErr != noErr || !list) {
        NSLog(@"ComponentChannel couldn't get ChannelDeviceList: %lu",
              theErr);
        return NO;
    }

    short inputNum;
    int i;

    // For each device, get a list of inputs.
    for (i = 0; i < (*list)->count; ++i) {
        theErr = SGGetChannelDeviceAndInputNames(*channel, nil, nil,
                                                 &inputNum);
        if (theErr != noErr) {
            NSLog(@"ComponentChannel couldn't get DeviceAndInputNames: %lu",
                  theErr);
            SGDisposeDeviceList(seqGrab, list);
            return NO;
        }

        SGDeviceInputList inputList = 
            ((SGDeviceName*)(&((*list)->entry[i])))->inputs;
        
        if (!inputList) {
            // No inputs on this device
            continue;
        }
        
		int x = 0;
		for (x = 0; x < ((*inputList)->count); x ++)
		{
			
			// Get the device name.
			NSString *inputDev = 
				[NSString stringWithCString:(char *)((*inputList)->entry[x].name + 1)
						  length:(int)((*inputList)->entry[x].name[0])];

			// Check for a match
			// If a match is found, set the device and input properly on the
			// channel.
			NSLog(@"Found device: %@", inputDev);
			if ([inputDev isEqual:cameraName]) {
				NSLog(@"Found the device/input for \"%@\"", cameraName);
				theErr = SGSetChannelDevice(*channel, (*list)->entry[i].name);
				if (theErr != noErr) {
					NSLog(@"SGSetChannelDevice error %ld", theErr);
					break;
				}
				theErr = SGSetChannelDeviceInput(*channel, x);
				if (theErr != noErr) {
					NSLog(@"SGSetChannelDeviceInput error %ld", theErr);
					break;
				}
				wasSuccessful = YES;
				break;
			}
		}
		if (wasSuccessful)
			break;
    }
    
    // Clean up our list
    if (list) {
        SGDisposeDeviceList(seqGrab, list);
    }

    // If we didn't succeed, the channel won't be used
    // so we can clean it up.
    if (!wasSuccessful) {
        SGDisposeChannel(seqGrab, *channel);
    }

    return wasSuccessful;
}

+ (NSMutableArray *)availableChannels
{
    SeqGrabComponent seqGrab = OpenDefaultComponent(SeqGrabComponentType, 0);
    if (!seqGrab) {
        NSLog(@"Error getting SeqGrab for availableChannels");
        return nil;
    }

    // Initialize sequence grabber component
    OSErr theErr = SGInitialize(seqGrab);
    if (theErr != noErr) {
        NSLog(@"SGInitialize() returned %ld", theErr);
        return nil;
    }

    SGChannel channel;

    // Get a new channel
    theErr = SGNewChannel(seqGrab, VideoMediaType, &channel);
    if (theErr != noErr) {
        NSLog(@"ComponentChannel couldn't get Channel: %ld", theErr);
        return nil;
    }

    // Get the device list for the channel (IIDC, USB, etc)
    SGDeviceList list = nil;
    theErr = SGGetChannelDeviceList(channel, sgDeviceListIncludeInputs,
                                    &list);
    if (theErr != noErr || !list) {
        NSLog(@"ComponentChannel couldn't get ChannelDeviceList: %lu",
              theErr);
        return nil;
    }

    short inputNum;
    int i;

    // For each device, get a list of inputs.
    NSMutableArray *channels = [NSMutableArray array];

    for (i = 0; i < (*list)->count; ++i) {
        theErr = SGGetChannelDeviceAndInputNames(channel, nil, nil,
                                                 &inputNum);
        if (theErr != noErr) {
            NSLog(@"ComponentChannel couldn't get DeviceAndInputNames: %lu",
                  theErr);
            SGDisposeDeviceList(seqGrab, list);
            return channels;
        }

        SGDeviceInputList inputList = 
            ((SGDeviceName*)(&((*list)->entry[i])))->inputs;
        
        if (!inputList) {
            // No inputs on this device
            continue;
        }

  
		int x = 0;
		for (x = 0; x < ((*inputList)->count); x ++)
		{
			
			// Get the device name.
			NSString *inputDev = 
				[NSString stringWithCString:(char *)((*inputList)->entry[x].name + 1)
						  length:(int)((*inputList)->entry[x].name[0])];

			[channels addObject:inputDev];
		}
    }
    
    // Clean up our list
    if (list) {
        SGDisposeDeviceList(seqGrab, list);
    }

    SGDisposeChannel(seqGrab, channel);

    return channels;
}

@end

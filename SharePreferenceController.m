//
//  SharePreferenceController.m
//  Gawker
//
//  Created by Phil Piwonka on 12/26/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "SharePreferenceController.h"
#import "LocalCamera.h"

NSString *WNKShareDeviceKey = @"ShareDevice";
NSString *WNKSharePortKey = @"SharePort";
NSString *WNKShareDescriptionKey = @"ShareDescription";
NSString *WNKShareFrequencyKey = @"ShareFrequency";
NSString *WNKShareBonjourKey = @"ShareBonjour";
NSString *WNKShareLimitKey = @"ShareLimit";
NSString *WNKShareLimitNumKey = @"ShareLimitNum";
NSString *WNKSharePasswordKey = @"SharePassword";
NSString *WNKShareUsePasswordKey = @"ShareUsePassword";

#define EXT_IP_ERR @"Error updating External IP Address"

@interface SharePreferenceController (NSURLConnectionDelegateMethods)
- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response;

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;

- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error;

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
@end


@implementation SharePreferenceController

- (id)initWithDelegate:(LocalCamera *)theDelegate
{
    if (![theDelegate isKindOfClass:[LocalCamera class]]) {
        NSLog(@"SharePreferenceController needs a LocalCamera as a delegate!");
        return nil;
    }

    if (self = [super initWithWindowNibName:@"SharePreferences"]) {
        ipConnection = nil;
        ipFetchData = nil;
        delegate = theDelegate;
    }

    return self;
}

- (id)init
{
    if (self = [super initWithWindowNibName:@"SharePreferences"]) {
        ipConnection = nil;
        ipFetchData = nil;
    }
    return self;
}

- (void)windowDidLoad
{
    [portField setIntValue:[self portField]];
    [descriptionField setStringValue:[self descriptionField]];
    [frequencyField setIntValue:[self frequencyField]];
    [bonjourCheckbox setState:[self bonjourCheckbox]];
    [limitCheckbox setState:[self limitCheckbox]];
    [limitNumField setIntValue:[self limitNumField]];

    [internalIPField setStringValue:[self internalIPs]];

    [[self window] setDelegate:self];
}

- (IBAction)showWindow:(id)sender
{
    [internalIPField setStringValue:[self internalIPs]];
    [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [portField sendAction:[portField action]
               to:[portField target]];
    [descriptionField sendAction:[descriptionField action]
                      to:[descriptionField target]];
    [frequencyField sendAction:[frequencyField action]
                    to:[frequencyField target]];
    if ([limitCheckbox state]) {
        [limitNumField sendAction:[limitNumField action]
                       to:[limitNumField target]];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    BOOL shouldClose = YES;
    if ([limitNumField intValue] < 1) {
        shouldClose = NO;
        NSBeep();
    }
    if ([frequencyField intValue] < 5) {
        shouldClose = NO;
        NSBeep();
    }

    return shouldClose;
}

- (int)portField
{
    return [delegate sharePort];
}

- (IBAction)changePortField:(id)sender
{
    [delegate setSharePort:[sender intValue]];
}

- (NSString *)descriptionField
{
    return [delegate sourceDescription];
}

- (IBAction)changeDescriptionField:(id)sender
{
    [delegate setSourceDescription:[sender stringValue]];
}

- (int)frequencyField
{
    return [delegate shareInterval];
}

- (IBAction)changeFrequencyField:(id)sender
{
    [delegate setShareInterval:[frequencyField intValue]];
}

- (BOOL)bonjourCheckbox
{
    return [delegate isBonjourEnabled];
}

- (IBAction)changeBonjourCheckbox:(id)sender
{
    [delegate setBonjourEnabled:[sender state]];
}

- (BOOL)limitCheckbox
{
    return [delegate limitUsers];
}

- (IBAction)changeLimitCheckbox:(id)sender
{
    [delegate setLimitUsers:[sender state]];
}

- (int)limitNumField
{
    return [delegate shareLimit];
}

- (IBAction)changeLimitNumField:(id)sender
{
    [delegate setShareLimit:[sender intValue]];
}

- (IBAction)fetchExternalIP:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://whatsmyip.islayer.net/"];
    NSURLRequest *ipReq = [NSURLRequest requestWithURL:url
                                        cachePolicy:NSURLRequestReloadIgnoringCacheData
                                        timeoutInterval:60.0];
    ipConnection = 
        [[NSURLConnection alloc] initWithRequest:ipReq delegate:self];
    if (ipConnection) {
        ipFetchData = [[NSMutableData data] retain];
    }
    else {
        // Could not connect
        [externalIPField setStringValue:EXT_IP_ERR];
    }
}

- (NSString *)internalIPs
{
    NSHost *myHost = [NSHost currentHost];
    NSString *ipAddress = nil;
    NSEnumerator *ipEnum = [[myHost addresses] objectEnumerator];
    NSMutableString *addresses = [[NSMutableString alloc] init];
    [addresses appendString:@"Internal IP Addresses: "];
    int count = 0;
    while (ipAddress = [ipEnum nextObject]) {
        if (![ipAddress isEqualToString:@"127.0.0.1"] &&
            [[ipAddress componentsSeparatedByString:@"."] count] == 4) {
            if (count > 0) {
                [addresses appendString:@", "];
            }
            [addresses appendString:ipAddress];
            count++;
        }
    }

    return [addresses autorelease];
}

@end

@implementation SharePreferenceController (NSURLConnectionDelegateMethods)
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [ipFetchData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [ipFetchData appendData:data];
}

- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error
{
    [ipFetchData release];
    [ipConnection release];

    [externalIPField setStringValue:EXT_IP_ERR];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *ipString = [[NSString alloc] initWithData:ipFetchData
                                           encoding:NSUTF8StringEncoding];
    if ([[ipString componentsSeparatedByString:@"."] count] != 4) {
        [externalIPField setStringValue:EXT_IP_ERR];        
    }
    else {
        [externalIPField setStringValue:[NSString stringWithFormat:@"External IP Address: %@",
                                                  ipString]];
    }
    [ipString release];
    
    [ipFetchData release];
    [ipConnection release];
}
@end

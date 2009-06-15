//
//  CameraFeaturesWindowController.m
//  Gawker
//
//  Created by phil piwonka on 6/7/06.
//  Copyright 2006 Phil Piwonka. All rights reserved.
//

#import "CameraFeaturesWindowController.h"
#import "PreferenceController.h"
#import "Camera.h"
#import "LocalCamera.h"
#import "ScreenCamera.h"
#import "NetworkCamera.h"
#import "CombinedCamera.h"
#import "AsyncSocket.h"

static const float WNKExternalIPHeight = 36.0;

static NSString *WNKInitialDateFormat = @"%Y-%m-%d %H:%M:00 %z";
static NSString *WNKOutputDateFormat = @"%1m/%1d/%Y  %1I:%M %p";

NSString *SCHFilenameTag = @"Filename";
NSString *SCHQualityTag = @"Quality";
NSString *SCHFrameScaleTag = @"FrameScale";
NSString *SCHFPSTag = @"FPS";
NSString *SCHTimeStampTag = @"TimeStamp";
NSString *SCHIntervalTag = @"Interval";
NSString *SCHStartTimeTag = @"StartTime";
NSString *SCHStopTimeTag = @"StopTime";

@interface CameraFeaturesWindowController (PrivateMethods)
- (void)sendActionsToTargets;
- (void)registerForNotifications;
- (void)updateSharingFields:(NSNotification *)note;
- (void)updateSharingStats:(NSNotification *)note;
- (void)drawShareTab;
- (void)drawGeneralTab;
- (void)drawScheduleTab;

- (void)optionsDidEnd:(NSSavePanel *)sheet
           returnCode:(int)code
          contextInfo:(void *)contextInfo;

- (void)fetchExternalIP;

- (void)initialSchedulingValues;
- (void)initialSchedulingValuesWhenAlreadyRecording;
- (void)initialSchedulingValuesWhenScheduled;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error;
- (void)hideExternalIPField;
- (void)showExternalIPField;
- (void)resizeWindowDownwardToSize:(NSRect)newSize;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)tabView:(NSTabView *)tabView 
didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

@end

@interface CameraFeaturesWindowController (TableDelegation)

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)row;

@end

@implementation CameraFeaturesWindowController

- (id)initWithDelegate:(id)camera saveView:(NSView *)saveView
{
    if (self = [super initWithWindowNibName:@"CameraFeatures"]) {
        saveAccessoryView = saveView;
        myCamera = camera;
        externalIPFieldIsHidden = NO;
        showSharing = NO;
        canSetDescription = NO;
        needsEnabledForScheduling = YES;
        if ([camera isKindOfClass:[LocalCamera class]]) {
            NSLog(@"Features for LocalCamera");
            showSharing = YES;
            canSetDescription = YES;
            needsEnabledForScheduling = NO;
        }
        else if ([camera isKindOfClass:[ScreenCamera class]]) {
            NSLog(@"Features for ScreenCamera");
            needsEnabledForScheduling = NO;
        }
        else if ([camera isKindOfClass:[NetworkCamera class]]) {
            NSLog(@"Features for NetworkCamera");
        }
        else if ([camera isKindOfClass:[CombinedCamera class]]) {
            NSLog(@"Features for CombinedCamera");
        }

        [self registerForNotifications];

    }
    return self;
}

- (void)awakeFromNib
{
    [spinner setHidden:YES];
    [scheduleStopTimeCheckbox setState:NO];

    [scheduleStartTimeInfo setEnabled:NO];
    [scheduleStopTimeInfo setEnabled:NO];
    [scheduleStartTime setEnabled:YES];
    [scheduleStopTime setEnabled:YES];

    [self enabledStatusChanged:nil];

    if (!canSetDescription) {
        [generalDescriptionField setEditable:NO];
        [generalDescriptionField setDrawsBackground:NO];
        [generalDescriptionField setBordered:NO];
        NSRect descRect = [generalDescriptionField frame];
        descRect.origin.x -= 3;
        descRect.origin.y += 2;
        descRect.size.height -= 5;
        [generalDescriptionField setFrame:descRect];
        [generalDescriptionField setStringValue:[myCamera sourceDescription]];
    }
    
    [generalSourceField setStringValue:[myCamera sourceSubDescription]];

    shareStatusViewSize = [shareStatusView frame].size;
    sharePortViewSize = [sharePortView frame].size;

    [shareStatusPortBox setContentView:sharePortView];
    
    NSTabViewItem *shareItem = nil;
    if (!showSharing) {
        NSTabViewItem *item = nil;
        NSEnumerator *tabEnum = [[featureTabs tabViewItems] objectEnumerator];
        while (item = [tabEnum nextObject]) {
            NSLog(@"Item label: %@", [item label]);
            if ([[item label] isEqual:@"Share"]) {
                shareItem = item;
                break;
            }
        }
        
        if (!shareItem) {
            NSLog(@"No Share tab, something is wrong!");
        }
        else {
            [featureTabs removeTabViewItem:shareItem];
        }
    }

    [self tabView:featureTabs 
          didSelectTabViewItem:[featureTabs selectedTabViewItem]];
}

- (void)windowDidLoad
{
    if (showSharing) {
        [sharePortField setIntValue:[self portField]];
        if (canSetDescription) {
            [generalDescriptionField setStringValue:[self descriptionField]];
        }
        else {            
            [generalDescriptionField setStringValue:[myCamera sourceDescription]];
        }
        [shareIntervalField setIntValue:[self intervalField]];
        [shareBonjourCheckbox setState:[self bonjourCheckbox]];
        [shareLimitCheckbox setState:[self limitCheckbox]];
        [shareLimitNumberField setIntValue:[self limitNumField]];
        [sharePasswordCheckbox setState:[self passwordCheckbox]];
        [sharePasswordField setStringValue:[self passwordField]];
    }

    [[self window] setTitle:[NSString stringWithFormat:@"%@ Options", [myCamera sourceSubDescription]]];

    [[self window] setDelegate:self];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [self sendActionsToTargets];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (IBAction)toggleSharing:(id)sender
{
    [self sendActionsToTargets];

    BOOL delayShareEnabling = NO;
    
    BOOL isSharing = NO;

    // Check if we are sharing
    if ([myCamera respondsToSelector:@selector(isSharing)]) {
        isSharing = [myCamera isSharing];
    }

    if (!isSharing) {
        // If not, first check if camera is enabled
        if ([myCamera respondsToSelector:@selector(isSourceEnabled)]) {
            if (![myCamera isSourceEnabled]) {
                [shareStatusField setStringValue:@"Enabling Camera..."];
                [shareStatusField display];
                [spinner setHidden:NO];
                [spinner startAnimation:self];
                [myCamera setSourceEnabled:YES openWindow:YES share:YES];
                delayShareEnabling = YES;
            }
        }
        if (!delayShareEnabling) {
            if ([myCamera respondsToSelector:@selector(setSharingEnabled:)]) {
                [myCamera setSharingEnabled:YES];
            }
        }
    }
    else if ([myCamera respondsToSelector:@selector(setSharingEnabled:)]) {
        [myCamera setSharingEnabled:NO];
    }
    
}

- (int)portField
{
    return [myCamera sharePort];
}

- (IBAction)changePortField:(id)sender
{
    [myCamera setSharePort:[sender intValue]];
}

- (NSString *)descriptionField
{
    return [myCamera sourceDescription];
}

- (IBAction)changeDescriptionField:(id)sender
{
    [myCamera setSourceDescription:[sender stringValue]];
}

- (int)intervalField
{
    return [myCamera shareInterval];
}

- (IBAction)changeIntervalField:(id)sender
{
    [myCamera setShareInterval:[sender intValue]];
}

- (BOOL)bonjourCheckbox
{
    return [myCamera isBonjourEnabled];
}

- (IBAction)changeBonjourCheckbox:(id)sender
{
    [myCamera setBonjourEnabled:[sender state]];
}

- (BOOL)limitCheckbox
{
    return [myCamera limitUsers];
}

- (IBAction)changeLimitCheckbox:(id)sender
{
    [myCamera setLimitUsers:[sender state]];
}

- (int)limitNumField
{
    return [myCamera shareLimit];
}

- (IBAction)changeLimitNumField:(id)sender
{
    [myCamera setShareLimit:[sender intValue]];
}

- (BOOL)passwordCheckbox
{
    return [myCamera sharePasswordRequired];
}

- (IBAction)changePasswordCheckbox:(id)sender
{
    NSLog(@"changePasswordCheckbox");
    [myCamera setSharePasswordRequired:[sender state]];
}

- (NSString *)passwordField
{
    return [myCamera sharePassword];
}

- (IBAction)changePasswordField:(id)sender
{
    [myCamera setSharePassword:[sender stringValue]];
}

// Scheduling methods

- (IBAction)setRecordOptions:(id)sender
{
    NSLog(@"In setRecordOptions");
    if ([myCamera isScheduled]) {
        NSLog(@"Clearing scheduled events");
        [myCamera clearScheduledEvents];
        return;
    }

    if ([myCamera isRecording]) {
        if ([scheduleStopTimeCheckbox state]) {
            [myCamera setScheduledStop:[scheduleStopTime dateValue]];
            [self drawScheduleTab];
        }
    }
    else {
        NSLog(@"Start time: %@", [scheduleStartTime dateValue]);
        if ([scheduleStopTimeCheckbox state]) {
            if ([[scheduleStopTime dateValue] compare:[scheduleStartTime dateValue]] != NSOrderedDescending) {
                NSRunAlertPanel(@"Stop Time must come after Start Time!",
                                @"Please choose a Stop Time that comes after your Start Time.",
                                @"OK", nil, nil);
                return;
            }
            NSLog(@" Stop time: %@", [scheduleStopTime dateValue]);
            [myCamera setScheduledStop:[scheduleStopTime dateValue]];
        }
        NSString *defaultDir = [[NSUserDefaults standardUserDefaults]
                                   objectForKey:WNKDefaultRecordDirectoryKey];
        NSLog(@"Beginning Recording.  Default Dir: %@", defaultDir);
        savePanel = [[NSSavePanel savePanel] retain];
        [savePanel setDelegate:self];
        [savePanel setRequiredFileType:@"mov"];
        [savePanel setPrompt:@"Schedule"];
        [savePanel setAccessoryView:saveAccessoryView];
        [savePanel beginSheetForDirectory:defaultDir
                   file:nil
                   modalForWindow:[self window]
                   modalDelegate:self
                   didEndSelector:@selector(optionsDidEnd:returnCode:contextInfo:)
                   contextInfo:NULL];      
    }  
}

- (IBAction)setStopDateCheckbox:(id)sender
{
    NSLog(@"In setStopDateCheckbox");
    BOOL useStopTime = [sender state];
    
    NSDate *now = [NSDate date];
    NSString *stopDateString = 
        [now descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:00 %z" 
             timeZone:nil
             locale:nil];

    NSDate *initialStopDate = [NSDate dateWithString:stopDateString];

    [scheduleStopTime setHidden:!useStopTime];
    [scheduleStopTime setDateValue:[initialStopDate addTimeInterval:300.0]];
    [scheduleStopTimeInfo setHidden:useStopTime];
    [scheduleStopTimeInfo setStringValue:@"No Stop Time set"];
}

- (IBAction)enableCamera:(id)sender
{
    [scheduleEnableSpinner setHidden:NO];
    [scheduleEnableSpinner startAnimation:nil];
    [myCamera setSourceEnabled:YES openWindow:YES];
}

@end

@implementation CameraFeaturesWindowController (PrivateMethods)

- (void)sendActionsToTargets
{
    if (showSharing) {
        [sharePortField sendAction:[sharePortField action]
                        to:[sharePortField target]];
        [shareIntervalField sendAction:[shareIntervalField action]
                            to:[shareIntervalField target]];
        [sharePasswordField sendAction:[sharePasswordField action]
                            to:[sharePasswordField target]];
        if ([shareLimitCheckbox state]) {
            [shareLimitNumberField sendAction:[shareLimitNumberField action]
                                   to:[shareLimitNumberField target]];
        }
    }
    if (canSetDescription) {
        [generalDescriptionField sendAction:[generalDescriptionField action]
                                 to:[generalDescriptionField target]];
    }
}

- (void)registerForNotifications
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
        selector:@selector(updateSharingFields:)
        name:@"SharingChanged"
        object:myCamera];
    [nc addObserver:self
        selector:@selector(updateSharingStats:)
        name:@"SharingStatsChanged"
        object:myCamera];
    [nc addObserver:self
        selector:@selector(recordStatusChanged:)
        name:@"RecordStatusChanged"
        object:myCamera];
    [nc addObserver:self
        selector:@selector(enabledStatusChanged:)
        name:@"EnabledStatusChanged"
        object:myCamera];
}

- (void)updateSharingFields:(NSNotification *)note
{
    [spinner setHidden:YES];
    [spinner stopAnimation:self];

    // Do sharing stuff
    if ([[note object] isSharing]) {
        [shareStatusField setStringValue:@"Sharing On"];
        [shareDescription setStringValue:@"Click Stop to stop sharing your camera.  Users currently connected will be disconnected."];
        [shareButton setTitle:@"Stop"];
        NSString *timeString = 
            [[NSDate date] descriptionWithCalendarFormat:@"%I:%M %p on %m/%d/%Y" 
                           timeZone:nil
                           locale:nil];
        [shareStartTimeField setStringValue:[NSString stringWithFormat:@"Sharing since %@", timeString]];
        [self fetchExternalIP];
    }
    else {
        [shareStatusField setStringValue:@"Sharing Off"];
        [shareDescription setStringValue:@"Click Start to make this camera available to other Gawker users."];
        [shareButton setTitle:@"Start"];
        [self drawShareTab];
    }
}

- (void)recordStatusChanged:(NSNotification *)note
{
    NSLog(@"Updating record status!");
    [self drawScheduleTab];
    [self drawGeneralTab];
}

- (void)enabledStatusChanged:(NSNotification *)note
{
    NSLog(@"Updating for enabled status change!");
    [self drawScheduleTab];
    [self drawGeneralTab];
}

- (void)updateSharingStats:(NSNotification *)note
{
    [[shareConnectedClientCount headerCell] setStringValue:[NSString stringWithFormat:@"%d Connected Users:", [myCamera numberOfConnectedClients]]];
    [shareConnectedClientsTable reloadData];
}

- (void)drawShareTab
{
    // No need to do anything is share tab isn't showing.
    if (![[[featureTabs selectedTabViewItem] label] isEqual:@"Share"]) {
        return;
    }
    NSRect boxRect = [shareStatusPortBox frame];

    BOOL isSharing = NO;

    if ([myCamera respondsToSelector:@selector(isSharing)]) {
        isSharing = [myCamera isSharing];
    }

    NSRect newWindowFrame = [[self window] frame];

    if (isSharing) {
        [shareStatusPortBox setContentView:shareStatusView];
        static const float statusHeight = 493.0;
        newWindowFrame.size.height = statusHeight;
        boxRect.size = shareStatusViewSize;
        if (externalIPFieldIsHidden) {
            newWindowFrame.size.height -= WNKExternalIPHeight;
            boxRect.size.height -= WNKExternalIPHeight;
        }
    }
    else {
        [shareStatusPortBox setContentView:sharePortView];        
        static const float portHeight = 284.0;
        newWindowFrame.size.height = portHeight;
        boxRect.size = sharePortViewSize;
    }
    
    [shareStatusPortBox setHidden:YES];
    boxRect.origin.y = 0;
    [shareStatusPortBox setFrame:boxRect];
    NSLog(@"Box Rect origin: %f, %f", boxRect.origin.x, boxRect.origin.y);
    [self resizeWindowDownwardToSize:newWindowFrame];
    [shareStatusPortBox setHidden:NO];
}

- (void)drawGeneralTab
{
    if (![[[featureTabs selectedTabViewItem] label] isEqual:@"General"]) {
        return;
    }

    if ([myCamera isSourceEnabled]) {
        NSString *startTimeString = 
            [[NSDate date] descriptionWithCalendarFormat:@"%1I:%M %p" 
                           timeZone:nil 
                           locale:nil];
        NSString *startDateString = 
            [[NSDate date] descriptionWithCalendarFormat:@"%1m/%1d/%Y" 
                           timeZone:nil 
                           locale:nil];
        NSString *enableString = 
            [NSString stringWithFormat:@"Enabled since %@ on %@",
                      startTimeString, startDateString];
                                           
        [generalEnableTime setStringValue:enableString];
    }
    else {
        [generalEnableTime setStringValue:@"Not enabled"];
    }

    if (!canSetDescription) {
        [generalDescriptionField setStringValue:[myCamera sourceDescription]];
        [generalSourceField setStringValue:[myCamera sourceSubDescription]];
    }
    
    NSRect newWindowFrame = [[self window] frame];
    static const float generalHeight = 152.0;
    newWindowFrame.size.height = generalHeight;
    [self resizeWindowDownwardToSize:newWindowFrame];
}

- (void)drawScheduleTab
{
    if (![[[featureTabs selectedTabViewItem] label] isEqual:@"Schedule"]) {
        return;
    }

    [scheduleEnableSpinner stopAnimation:nil];
    [scheduleEnableSpinner setHidden:YES];

    if (needsEnabledForScheduling && ![myCamera isSourceEnabled]) {
        [scheduleBox setContentView:scheduleNeedEnableView];
    }
    else {
        [scheduleBox setContentView:scheduleMainView];
        if ([myCamera isScheduled]) {
            NSLog(@"Camera already scheduled");
            [self initialSchedulingValuesWhenScheduled];
            
        }
        else if ([myCamera isRecording]) {
            NSLog(@"Camera already recording");
            [self initialSchedulingValuesWhenAlreadyRecording];
        }
        else {
            [self initialSchedulingValues];
        }
        [scheduleBox setContentView:scheduleMainView];
    }
    NSRect newWindowFrame = [[self window] frame];
    static const float scheduleHeight = 165.0;
    newWindowFrame.size.height = scheduleHeight;
    [self resizeWindowDownwardToSize:newWindowFrame];    
}

- (void)optionsDidEnd:(NSSavePanel *)sheet
           returnCode:(int)code
          contextInfo:(void *)contextInfo
{
    if (code == NSOKButton) {
		NSLog(@"Will save movie to: %@", [sheet filename]);
	}
    else {
        [myCamera clearScheduledEvents];
        [savePanel release];
        savePanel = nil;
        return;
    }

    static const int qualityTag = 1;
    static const int frameScaleTag = 2;
    static const int fpsTag = 3;
    static const int timeStampTag = 4;
    static const int intervalTag = 5;

    NSMutableDictionary *scheduling = [[NSMutableDictionary alloc] init];

    [scheduling setObject:[sheet filename]
                     forKey:SCHFilenameTag];
    if ([saveAccessoryView viewWithTag:qualityTag]) {
        [scheduling setObject:[[saveAccessoryView viewWithTag:qualityTag] titleOfSelectedItem]
                    forKey:SCHQualityTag];
    }
    
    if ([saveAccessoryView viewWithTag:frameScaleTag]) {
        NSNumber *frameScale = 
            [NSNumber numberWithFloat:(1.0 / ([[saveAccessoryView viewWithTag:frameScaleTag] indexOfSelectedItem] + 1.0))];
        [scheduling setObject:frameScale
                    forKey:SCHFrameScaleTag];
    }
    
    if ([saveAccessoryView viewWithTag:fpsTag]) {
        NSNumber *fps =
            [NSNumber numberWithFloat:[[saveAccessoryView viewWithTag:fpsTag] floatValue]];
        [scheduling setObject:fps
                    forKey:SCHFPSTag];
    }
    
    if ([saveAccessoryView viewWithTag:timeStampTag]) {
        NSNumber *useTimestamp = 
            [NSNumber numberWithBool:[[saveAccessoryView viewWithTag:timeStampTag] state]];
        [scheduling setObject:useTimestamp
                    forKey:SCHTimeStampTag];
    }
    
    if ([saveAccessoryView viewWithTag:intervalTag]) {
        NSNumber *interval =
            [NSNumber numberWithFloat:[[saveAccessoryView viewWithTag:intervalTag] floatValue]];
        [scheduling setObject:interval
                    forKey:SCHIntervalTag];
    }
    
    NSLog(@"Schedule dictionary: %@", scheduling);
    
    NSLog(@"Start time: %@", [scheduleStartTime dateValue]);

    [myCamera setScheduledStart:[scheduleStartTime dateValue]
              recordOptions:scheduling];

    [savePanel release];
    savePanel = nil;
}

- (void)fetchExternalIP
{
    NSURL *url = [NSURL URLWithString:@"http://whatsmyip.islayer.net/"];
    NSURLRequest *ipReq = [NSURLRequest requestWithURL:url
                                        cachePolicy:NSURLRequestReloadIgnoringCacheData
                                        timeoutInterval:3.0];
    ipConnection = 
        [[NSURLConnection alloc] initWithRequest:ipReq delegate:self];
    if (ipConnection) {
        ipFetchData = [[NSMutableData data] retain];
    }
    else {
        // Could not connect
        [self hideExternalIPField];
        [self drawShareTab];
    }
}

- (void)initialSchedulingValues
{
    NSDate *now = [NSDate date];
    NSString *startDateString = 
        [now descriptionWithCalendarFormat:WNKInitialDateFormat 
             timeZone:nil
             locale:nil];

    NSDate *initialStartDate = [NSDate dateWithString:startDateString];
    [scheduleStartTimeText setTextColor:[NSColor controlTextColor]];
    [scheduleStartTime setHidden:NO];
    [scheduleStartTime setDateValue:initialStartDate];
    [scheduleStartTimeInfo setHidden:YES];

    [scheduleStopTimeCheckbox setEnabled:YES];
    [scheduleStopTimeInfo setStringValue:@"No Stop Time set"];
    BOOL showStop = [scheduleStopTimeCheckbox state];
    [scheduleStopTime setHidden:!showStop];
    [scheduleStopTimeInfo setHidden:showStop];

    [scheduleButton setTitle:@"Continue"];
}

- (void)initialSchedulingValuesWhenAlreadyRecording
{
    NSDate *now = [NSDate date];
    NSString *stopDateString = 
        [now descriptionWithCalendarFormat:WNKInitialDateFormat
             timeZone:nil
             locale:nil];

    NSDate *initialStopDate = [NSDate dateWithString:stopDateString];
    [scheduleStopTime setHidden:NO];
    [scheduleStopTime setDateValue:initialStopDate];
    [scheduleStopTimeInfo setHidden:YES];
    [scheduleStopTimeCheckbox setState:YES];
    [scheduleStopTimeCheckbox setEnabled:YES];

    [scheduleStartTime setHidden:YES];
    [scheduleStartTimeInfo setHidden:NO];
    [scheduleStartTimeInfo setStringValue:@"Already recording"];
    [scheduleStartTimeText setTextColor:[NSColor secondarySelectedControlColor]];

    [scheduleButton setTitle:@"Schedule"];
}

- (void)initialSchedulingValuesWhenScheduled
{
    [scheduleStartTime setHidden:YES];
    [scheduleStopTime setHidden:YES];

    [scheduleStartTimeInfo setHidden:NO];
    [scheduleStopTimeInfo setHidden:NO];

    [scheduleStartTimeText setTextColor:[NSColor secondarySelectedControlColor]];

    // I can be "Scheduled" but already recording since stop time is scheduled
    NSString *startString = [NSString stringWithString:@"Already Recording"];
    NSDate *startDateForCamera = [myCamera startTime];
    if (startDateForCamera) {
        startString = [startDateForCamera descriptionWithCalendarFormat:WNKOutputDateFormat timeZone:nil locale:nil];
    }

    [scheduleStartTimeInfo setStringValue:startString];

    NSString *stopString = [NSString stringWithString:@"No stop date set"];
    NSDate *stopDateForCamera = [myCamera stopTime];
    if (stopDateForCamera) {
        stopString = [stopDateForCamera descriptionWithCalendarFormat:WNKOutputDateFormat timeZone:nil locale:nil];
        [scheduleStopTimeCheckbox setState:YES];
    }
    else {
        [scheduleStopTimeCheckbox setState:NO];        
    }
    [scheduleStopTimeInfo setStringValue:stopString];
    [scheduleStopTimeCheckbox setEnabled:NO];
    
    [scheduleButton setTitle:@"Unschedule"];
}

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
    ipFetchData = nil;
    [ipConnection release];
    ipConnection = nil;

    [self hideExternalIPField];
    [self drawShareTab];
}

- (void)hideExternalIPField
{
    if (![shareExternalIPField isHidden]) {
        NSLog(@"Hiding externalIPField");
        [shareExternalIPField setHidden:YES];
        externalIPFieldIsHidden = YES;
    }
}

- (void)showExternalIPField
{
    if ([shareExternalIPField isHidden]) {
        [shareExternalIPField setHidden:NO];
        externalIPFieldIsHidden = NO;
    }
}

- (void)resizeWindowDownwardToSize:(NSRect)newSize
{
    NSRect currentSize = [[self window] frame];
    float yDelta = currentSize.size.height - newSize.size.height;
    newSize.origin.y += yDelta;
    [[self window] setFrame:newSize display:YES animate:YES];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *ipString = [[NSString alloc] initWithData:ipFetchData
                                           encoding:NSUTF8StringEncoding];
    NSArray *ipComps = [ipString componentsSeparatedByString:@"."];
    if ([ipComps count] != 4) {
        [self hideExternalIPField];
    }
    else {
        NSMutableString *mutString = [NSMutableString stringWithCapacity:15];
        [mutString appendFormat:@"%@.%@.%@.",
                   [ipComps objectAtIndex:0],
                   [ipComps objectAtIndex:1],
                   [ipComps objectAtIndex:2]];
        NSString *finalOct = [ipComps objectAtIndex:3];
        [mutString appendFormat:[[NSNumber numberWithInt:atoi([finalOct UTF8String])] stringValue]];
        if ([self portField] != 7548) {
            [mutString appendFormat:@":%d", [self portField]];
        }
        [shareExternalIPField setStringValue:
                                  [NSString stringWithFormat:@"Internet users can view this camera by entering %@ in the Connect To field.",
                                                  mutString]];
        [self showExternalIPField];
    }
    [ipString release];
    
    [ipFetchData release];
    ipFetchData = nil;

    [ipConnection release];
    ipConnection = nil;

    [self drawShareTab];
}

- (void)tabView:(NSTabView *)tabView 
didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSLog(@"TabViewItem changed to %@", [tabViewItem label]);
    if ([[tabViewItem label] isEqual:@"Share"]) {
        [self drawShareTab];
    }
    else if ([[tabViewItem label] isEqual:@"Schedule"]) {
        [self drawScheduleTab];
    }
    else {
        [self drawGeneralTab];
    }
}

- (BOOL)control:(NSControl *)control
didFailToFormatString:(NSString *)string
errorDescription:(NSString *)error
{
    NSString *errorTitle;
    NSString *errorDesc;
    if (control == shareIntervalField) {
        errorTitle = [NSString stringWithString:@"Invalid Broadcast Interval"];
        errorDesc = 
            [NSString stringWithString:@"Broadcast interval must be a number greater than or equal to 1"];
    }
    else if (control ==  sharePortField) {
        errorTitle = [NSString stringWithString:@"Invalid Port for Sharing"];
        errorDesc = [NSString stringWithString:@"Port must be a number between 1024 and 65535"];
    }
    else if (control == shareLimitNumberField) {
        errorTitle = [NSString stringWithString:@"Invalid number of users"];
        errorDesc = [NSString stringWithString:@"Simultaneous user limit must be a number greater than or equal to 1"];
    }

    if (errorTitle && errorDesc) {
        NSBeep();
        NSRunAlertPanel(errorTitle, errorDesc, @"OK", nil, nil);
    }

    return NO;
}

@end

@implementation CameraFeaturesWindowController (TableDelegation)

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    int rows = 0;
    if ([myCamera respondsToSelector:@selector(numberOfConnectedClients)]) {
        rows = [myCamera numberOfConnectedClients];
    }

    return rows;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)row
{
    NSString *ipAddress = nil;
    if ([myCamera respondsToSelector:@selector(connectedClients)]) {
        NSArray *clients = [myCamera connectedClients];
        if (clients) {
            ipAddress = [(AsyncSocket *)[clients objectAtIndex:row] connectedHost];
        }
    }

    return ipAddress;
}

@end

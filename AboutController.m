//
//  AboutController.m
//  Gawker
//
//  Created by phil piwonka on 2/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AboutController.h"


@implementation AboutController
- (id)init
{
    self = [super initWithWindowNibName:@"AboutPanel"];
    return self;
}

- (void)windowDidLoad
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *gawkerVersion = 
        [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *versionString = [NSString stringWithFormat:@"Version %@",
                                        gawkerVersion];

    [versionField setStringValue:versionString];
    
    NSString *licensePath = [bundle pathForResource:@"License" ofType:@"txt"];

    [licenseField setString:[NSString stringWithContentsOfFile:licensePath]];
}

- (IBAction)showLicenseSheet:(id)sender
{
    [NSApp beginSheet:licenseSheet
           modalForWindow:[self window]
           modalDelegate:self
           didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
           contextInfo:NULL];
}

- (IBAction)endLicenseSheet:(id)sender
{
    [licenseSheet orderOut:sender];
    
    [NSApp endSheet:licenseSheet returnCode:1];
}

- (void)sheetDidEnd:(NSWindow *)sheet
         returnCode:(int)returnCode
        contextInfo:(void *)contextInfo
{

}

@end

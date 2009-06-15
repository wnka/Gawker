//
//  AboutController.h
//  Gawker
//
//  Created by phil piwonka on 2/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AboutController : NSWindowController {
    IBOutlet NSTextField *versionField;
    IBOutlet NSWindow *licenseSheet;
    IBOutlet NSTextView *licenseField;
}

- (IBAction)showLicenseSheet:(id)sender;
- (IBAction)endLicenseSheet:(id)sender;
- (void)sheetDidEnd:(NSWindow *)sheet
         returnCode:(int)returnCode
        contextInfo:(void *)contextInfo;


@end

//
//  InternetComboBox.m
//  Gawker
//
//  Created by Phil Piwonka on 9/24/05.
//  Copyright 2005 Phil Piwonka. All rights reserved.
//

#import "InternetComboBox.h"


@implementation InternetComboBox

- (void)awakeFromNib
{
    NSString *tempString = [NSString stringWithString:@"Connect To"];
    NSMutableDictionary *stringAttrs = [[NSMutableDictionary alloc] init];
    
    [stringAttrs setObject:[NSColor grayColor]
                 forKey:NSForegroundColorAttributeName];

    placeholder = [[NSAttributedString alloc] initWithString:tempString
                                              attributes:stringAttrs];

    [self setStringValue:(NSString *)placeholder];
}

- (void)dealloc
{
    [placeholder release];
    [super dealloc];
}

- (BOOL)becomeFirstResponder
{
    BOOL superResponse = [super becomeFirstResponder];
    if (superResponse) {
        if ([[self stringValue] isEqual:[placeholder string]]) {
            [self setStringValue:@""];
        }
    }
    return superResponse;
}

- (void)textDidEndEditing:(NSNotification *)aNote
{
    [super textDidEndEditing:aNote];
    if([[self stringValue] isEqual:@""]) {
        [self setStringValue:(NSString *)placeholder];
    }
}

@end

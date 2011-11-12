//
//  SNIRCTextView.m
//  MacIRC
//
//  Created by Pablo Merino on 30/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SNIRCTextView.h"


@implementation NSTextView (MyAdditions) 
- (void) insertText: (NSString*) aS color: (NSColor*) aColor { 
    long start = [[self textStorage] length]; 
    long len = [aS length]-1;
    NSRange area = NSMakeRange(start, len);
    
    //remove existing coloring
    [[self textStorage] removeAttribute:NSForegroundColorAttributeName range:area];
    
    //add new coloring
    [[self textStorage] addAttribute:NSForegroundColorAttributeName 
                        value:[NSColor yellowColor] 
                        range:area];

} 
@end


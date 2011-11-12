//
//  SNIRCTextView.h
//  MacIRC
//
//  Created by Pablo Merino on 30/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSTextView (MyAdditions) 
- (void) insertText: (NSString*) aS color: (NSColor*) aColor;
@end 

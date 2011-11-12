//
//  AppDelegate.h
//  MacIRC
//
//  Created by Pablo Merino on 29/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SNIRCController.h"
typedef enum {
    parseTypeMessage,
    parseTypeNick
} parseType;
@interface AppDelegate : NSObject <NSApplicationDelegate, NSStreamDelegate, SNIRCControllerDelegate> {
    
    IBOutlet NSTextView *logField;
    SNIRCController *ircController;
    NSString *newsender;
    NSString *newmessage;
    BOOL isConnected;
    NSString *command;
    IBOutlet NSTextFieldCell *textField;

    NSArray *userArray;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) NSArray *userArray;
- (void)writeToLog:(NSString*)data;
- (IBAction)sendTestMsg:(id)sender;
- (IBAction)leaveChannel:(id)sender;
- (IBAction)sendMessage:(id)sender;
- (NSString*)parseString:(NSString*)string withType:(parseType)type;
@end

//
//  AppDelegate.m
//  MacIRC
//
//  Created by Pablo Merino on 29/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "SNIRCController.h"
#import "SNIRCTextView.h"
@implementation AppDelegate

@synthesize window = _window, userArray;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    ircController = [[SNIRCController alloc] init];
    [ircController setDelegate:self];

    [ircController connectToServer:@"irc.nightcoast.net" withPort:6667 withNick:@"zad0xsis|macirc" andUser:@"zad0xsis|macirc" andPass:nil useSSL:NO];
    //[ircController joinChannel:@"#nightcoast"];
}
- (void)connectedToTheServer {
    if([command isEqualToString:@"372"]) {
        [ircController joinChannel:@"#nightcoast"];
        [ircController sendMessage:@"NAMES #nightcoast"];

    }
}
- (void)gotPing:(NSString *)debug {
    [self writeToLog:[NSString stringWithFormat:@"[DEBUG] Got server ping: %@", [debug substringWithRange:NSMakeRange(0,[debug length]-2)]]];
}
- (void) serverTalked:(id)data {
    /* SCAN MAIN STRING */
    NSScanner* scan=[NSScanner scannerWithString:data];
    if([data hasPrefix:@":"]) {
        [scan setScanLocation:1];
    }
    //NSLog(data);
    NSString *sender = nil;
    
    command = nil;
    NSString *argument = nil;
    
    [scan scanUpToString:@" " intoString:&sender];
    [scan scanUpToString:@" " intoString:&command];
    [scan scanUpToString:@"\r\n" intoString:&argument];
    NSString *test = nil;
    if([command isEqualToString:@"353"]) {
        NSScanner* userscan=[NSScanner scannerWithString:data];

        NSString *usersender = nil;
        NSString *usercommand = nil;
        NSString *userargument = nil;
        
        [userscan scanUpToString:@" " intoString:&usersender];
        [userscan scanUpToString:@" " intoString:&usercommand];
        [userscan scanUpToString:@"\r\n" intoString:&userargument];
        //NSLog(@"Sender:%@\nCmd:%@\nArgs: %@",usersender, usercommand, userargument);
        
        NSString *users;

        
        @try {
            NSScanner *theScanner = [NSScanner scannerWithString:userargument];
            NSCharacterSet *separator = [NSCharacterSet characterSetWithCharactersInString:@":"];
            
            [theScanner scanUpToCharactersFromSet:separator intoString:NULL];
            [theScanner setScanLocation: [theScanner scanLocation]+1];
            [theScanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&users];
        }
        @catch ( NSException *e ) {
            //we don't care, we do?
        }
        self.userArray = [users componentsSeparatedByString:@" "];
        
        


    }
    

    @try {
        NSScanner *theScanner = [NSScanner scannerWithString:data];
        NSCharacterSet *separator = [NSCharacterSet characterSetWithCharactersInString:@":"];

        [theScanner scanUpToCharactersFromSet:separator intoString:NULL];
        [theScanner setScanLocation: [theScanner scanLocation]+1];
        [theScanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&test];
    }
    @catch ( NSException *e ) {
        //we don't care, we do?
    }
    if ([test substringToIndex:1] == @"#") {
        NSLog(@"YAY! %@", test);
    }
    //NSLog(test);

    NSString *user = [self parseString:sender withType:parseTypeNick];
    NSMutableArray *usersMutable = [NSMutableArray arrayWithArray:userArray];
    [usersMutable removeLastObject];
    
    if ([command isEqualToString:@"PRIVMSG"]) {
        NSLog(@"%@", usersMutable);
        for(int i=0; i<[usersMutable count]; i++) {
                NSString *userInArray = [[usersMutable objectAtIndex:i] substringFromIndex:1];
               

                if([userInArray isEqualToString:user]) {
                    user = [usersMutable objectAtIndex:i];
                    
                    
                }
        
            
        }
        [self writeToLog:[NSString stringWithFormat:@"<%@> %@",user, [self parseString:argument withType:parseTypeMessage]]];

    }
    
}

- (void)serverGaveError:(IRCErrorType)error {
    switch (error) {
        case ServerError:
            [self writeToLog:@"Server error"];
            break;
            
        default:
            [self writeToLog:@"Unknown error"];
            break;
    }
}
-(NSString*)parseString:(NSString*)string withType:(parseType)type {
    switch (type) {
        case parseTypeNick:
        {
            [[NSScanner scannerWithString:string] scanUpToString:@"!" intoString:&newsender];
            return newsender;
            break;
        }
        case parseTypeMessage:
        {
            NSScanner *argscan = [NSScanner scannerWithString:string];
            [argscan scanUpToString:@"" intoString:NULL];
            NSScanner *theScanner = [NSScanner scannerWithString:string];
            NSCharacterSet *seperator = [NSCharacterSet characterSetWithCharactersInString:@":"];
            NSCharacterSet *newLine = [NSCharacterSet newlineCharacterSet];
            while ([theScanner isAtEnd] == NO) {
                
                [theScanner scanUpToCharactersFromSet:seperator intoString:NULL];
                [theScanner setScanLocation: [theScanner scanLocation]+1];
                [theScanner scanUpToCharactersFromSet:newLine intoString:&newmessage];
                
                
            }
            return newmessage;
            break;
        }
        default:
            return @"Error when parsing";
            break;
    }
}
-(IBAction)sendTestMsg:(id)sender {
    [ircController sendMessage:@"PRIVMSG #nightcoast :hi"];
    [self writeToLog:@"<me> hi"];

}
-(IBAction)leaveChannel:(id)sender {
    [ircController sendMessage:@"PART #nightcoast"];

}
- (IBAction)sendMessage:(id)sender {
    [ircController sendMessage:[NSString stringWithFormat:@"PRIVMSG #nightcoast :%@", textField.stringValue]];
    [self writeToLog:[NSString stringWithFormat:@"<me> %@", textField.stringValue]];
}
-(void)writeToLog:(NSString*)data {
    
    NSAttributedString *stringToAppend = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", data]];
    [[logField textStorage] appendAttributedString:stringToAppend];
    [logField setFont:[NSFont fontWithName:@"Monaco" size:12]];

}
-(void)applicationWillTerminate:(NSNotification *)notification {
    [ircController sendMessage:@"QUIT :thx qwerty :D"];
    NSLog(@"bye");

}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
return YES;
}
@end

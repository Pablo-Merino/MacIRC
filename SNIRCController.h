//
//  SNIRCController.h
//  MacIRC
//
//  Created by Pablo Merino on 30/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    ServerError
} IRCErrorType;

@protocol SNIRCControllerDelegate

- (void) serverTalked:(id)data;
- (void)serverGaveError:(IRCErrorType)error;
- (void)connectedToTheServer;
- (void)gotPing:(NSString*)debug;

@end

@interface SNIRCController : NSObject <NSStreamDelegate> {
    id<SNIRCControllerDelegate> delegate;
    BOOL bConnect;
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    NSString *nick;
    NSString *user;
    NSString *pass;

    NSString *server;
    BOOL registered;
    NSMutableString* queuedCommands;
    NSString *cmd;


}
- (void) setDelegate:(id<SNIRCControllerDelegate>)_delegate;
- (id)connectToServer:(NSString *)server withPort:(int)port withNick:(NSString *)_nick andUser:(NSString *)user andPass:(NSString *)pass useSSL:(BOOL)useSSL;
- (void)joinChannel:(NSString*)channelName;
- (void)sendMessage:(NSString*)command;
- (void)authInServerWithNick:(NSString*)_nick andUser:(NSString*)_user andPass:(NSString*)_pass;
- (NSArray*)parseString:(NSString*)string;
- (NSString*)nickName;
- (NSString*)userName;

@end

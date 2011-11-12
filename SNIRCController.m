//
//  SNIRCController.m
//  MacIRC
//
//  Created by Pablo Merino on 30/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SNIRCController.h"


@implementation SNIRCController

- (void) setDelegate:(id<SNIRCControllerDelegate>)_delegate {
    delegate = _delegate;
}
- (id)connectToServer:(NSString *)_server withPort:(int)port withNick:(NSString *)_nick andUser:(NSString *)_user andPass:(NSString *)_pass useSSL:(BOOL)useSSL {
    registered = NO;
    nick = _nick;
    server = _server;
    user = _user;
    pass = _pass;
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)server, port, &readStream, &writeStream);
    inputStream = (NSInputStream *)readStream;
    outputStream = (NSOutputStream *)writeStream;
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    if ([inputStream streamStatus] == NSStreamStatusNotOpen)
        [inputStream open];
    
    if ([outputStream streamStatus] == NSStreamStatusNotOpen)
        [outputStream open];
    if (useSSL)
    {            
        [inputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL 
                       forKey:NSStreamSocketSecurityLevelKey];
        [outputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL 
                        forKey:NSStreamSocketSecurityLevelKey];  
        
        NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredCertificates,
                                  [NSNumber numberWithBool:YES], kCFStreamSSLAllowsAnyRoot,
                                  [NSNumber numberWithBool:NO], kCFStreamSSLValidatesCertificateChain,
                                  kCFNull,kCFStreamSSLPeerName,
                                  nil];
        
        CFReadStreamSetProperty((CFReadStreamRef)inputStream, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
        CFWriteStreamSetProperty((CFWriteStreamRef)outputStream, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
        
    }
    bConnect = YES;
    [self sendMessage:[NSString stringWithFormat:@"USER %@ lulz tech %@", _user, _user]];
    [self sendMessage:[NSString stringWithFormat:@"NICK %@", _nick]];
    
    return self;
}
- (void)authInServerWithNick:(NSString*)_nick andUser:(NSString*)_user andPass:(NSString*)_pass {
    if([inputStream streamStatus] == NSStreamStatusOpen && [outputStream streamStatus] == NSStreamStatusOpen) {
        if (pass) {
            [self sendMessage:[NSString stringWithFormat:@"PASS %@:%@", _user, _pass]];
        }
        
        [self sendMessage:[NSString stringWithFormat:@"USER %@ %@ %@ %@", _user, _user, _user, _user]];
        [self sendMessage:[NSString stringWithFormat:@"NICK %@", _nick]];
    }
}
- (void)joinChannel:(NSString*)channelName {
    [self sendMessage:[NSString stringWithFormat:@"JOIN %@", channelName]];
    registered = YES;

}
- (void)sendMessage:(NSString*)command{
    NSString *msg  = [NSString stringWithFormat:@"%@\r\n", command];
    NSData *msgdata = [[NSData alloc] initWithData:[msg dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[msgdata bytes] maxLength:[msgdata length]];
    /*NSLog(@"Command: %@ Args: %@", command, args);
    if (registered) {
        if(args)
            cmd = [command stringByAppendingFormat:@" :%@\r\n", args];
        else
            cmd = [command stringByAppendingString:@"\r\n"];
        
        NSData *msgdata = [[NSData alloc] initWithData:[cmd dataUsingEncoding:NSASCIIStringEncoding]];
        [outputStream write:[msgdata bytes] maxLength:[msgdata length]];
        NSLog(@"sent");
    } else {
        if (!queuedCommands) queuedCommands = [NSMutableString new];
        [queuedCommands appendFormat:@"%@\r\n", cmd];
    }*/
   
  
   
}
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    if(streamEvent == NSStreamEventHasBytesAvailable)
    {
        uint8_t buffer[1024];
        long len;
        
        while ([inputStream hasBytesAvailable]) {
            len = [inputStream read:buffer maxLength:sizeof(buffer)];
            if (len > 0) {
                
                NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                
                if (nil != output) {
                
                    [delegate serverTalked:output];
                    
                    [delegate connectedToTheServer];
                    

                    NSArray *msg = [self parseString:output];
                    NSString *antispoof = nil;
                    [[NSScanner scannerWithString:[msg objectAtIndex:0]] scanUpToString:@"!" intoString:&antispoof];
                    if ([[msg objectAtIndex:0] isEqualToString:@"PING"]) {
                        [self sendMessage:[@"PONG " stringByAppendingString:[msg objectAtIndex:1]]];
                        [delegate gotPing:[msg objectAtIndex:1]];
                        NSLog(@"Pingie!");
                    } else if([[msg objectAtIndex:1] isEqualToString:@"PRIVMSG"] && [[msg objectAtIndex:0] isEqualToString:antispoof]) {
                        [self sendMessage:[@"NOTICE " stringByAppendingString:[msg objectAtIndex:1]]];
                    }
                }
            }
        } 
        
    }
    else if (streamEvent == NSStreamEventEndEncountered)
    {
        if (inputStream) {
            [inputStream release];
        }
        if (outputStream) {
            [outputStream release];
        }
        NSLog(@"NSStreamEventEndEncountered");
        [delegate serverGaveError:ServerError];
    } else if (streamEvent == NSStreamEventHasSpaceAvailable)
    {
        if (registered && queuedCommands) {
            [outputStream write:(uint8_t*)[queuedCommands UTF8String] maxLength:[queuedCommands length]];
            [queuedCommands release];
            queuedCommands=nil;
        }
        NSLog(@"NSStreamEventHasSpaceAvailable");
    }
}
- (NSString*)userName {
    if (user) {
        return user;
    } else {
        return @"Not set";
    }
    return nil;
}
- (NSString*)nickName {
    if (nick) {
        return nick;
    } else {
        return @"Not set";
    }
    return nil;
}

- (NSArray*)parseString:(NSString*)string {
    NSScanner* scan=[NSScanner scannerWithString:string];
    if([string hasPrefix:@":"]) {
        [scan setScanLocation:1];
    }
    NSString *sender = nil;
    
    NSString *command = nil;
    NSString *argument = nil;
    
    [scan scanUpToString:@" " intoString:&sender];
    [scan scanUpToString:@" " intoString:&command];
    [scan scanUpToString:@"\r\n" intoString:&argument];
    return [NSArray arrayWithObjects:sender, command, argument, nil];
}

@end

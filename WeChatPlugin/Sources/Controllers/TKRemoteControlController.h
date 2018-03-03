//
//  TKRemoteControlController.h
//  WeChatPlugin
//
//  Created by TK on 2017/8/8.
//  Copyright © 2017年 tk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKRemoteControlController : NSObject

+ (void)executeRemoteControlCommandWithVoiceMsg:(NSString *)msg;
+ (void)executeRemoteControlCommandWithMsg:(NSString *)msg;
+ (void)executeShellCommand:(NSString *)msg;
+ (NSString *)remoteControlCommandsString;

@end

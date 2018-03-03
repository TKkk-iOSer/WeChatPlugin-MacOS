//
//  TKRemoteControlController.m
//  WeChatPlugin
//
//  Created by TK on 2017/8/8.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "TKRemoteControlController.h"
#import "TKWeChatPluginConfig.h"
#import "TKRemoteControlModel.h"
#import "WeChatPlugin.h"

typedef NS_ENUM(NSUInteger, MessageDataType) {
    MessageDataTypeText,
    MessageDataTypeVoice
};

//      执行 AppleScript
static NSString * const kRemoteControlAppleScript = @"osascript /Applications/WeChat.app/Contents/MacOS/WeChatPlugin.framework/Resources/TKRemoteControlScript.scpt";

@implementation TKRemoteControlController

+ (void)executeRemoteControlCommandWithVoiceMsg:(NSString *)msg {
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    NSString *callBack = [NSString stringWithFormat:@"小助手收到一条语音消息，转文字后👇👇👇：\n\n\n%@",msg];
    MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    [service SendTextMessage:currentUserName toUsrName:currentUserName msgText:callBack atUserList:nil];
    
    [self executeRemoteControlCommandWithMsg:msg msgType:MessageDataTypeVoice];
}

+ (void)executeRemoteControlCommandWithMsg:(NSString *)msg {
    [self executeRemoteControlCommandWithMsg:msg msgType:MessageDataTypeText];
}

+ (void)executeRemoteControlCommandWithMsg:(NSString *)msg msgType:(MessageDataType)type {
    NSArray *remoteControlModels = [TKWeChatPluginConfig sharedConfig].remoteControlModels;
    [remoteControlModels enumerateObjectsUsingBlock:^(NSArray *subModels, NSUInteger index, BOOL * _Nonnull stop) {
        [subModels enumerateObjectsUsingBlock:^(TKRemoteControlModel *model, NSUInteger idx, BOOL * _Nonnull subStop) {
            if ([self sholdExecuteRemoteControlWithModel:model msg:msg msgType:type]) {
                if ([model.function isEqualToString:@"屏幕保护"] || [model.function isEqualToString:@"锁屏"]) {
                    //      屏幕保护 & 锁屏 通过 Shell 命令来执行即可
                    [self executeShellCommand:model.executeCommand];
                } else {
                    //      拼接相关参数，执行 AppleScript
                    NSString *command = [NSString stringWithFormat:@"%@ %@",kRemoteControlAppleScript, model.executeCommand];
                    [self executeShellCommand:command];
                    //      bug: 有些程序在第一次时会无法关闭，需要再次关闭
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if ([model.function isEqualToString:@"退出所有程序"]) {
                            NSString *command = [NSString stringWithFormat:@"%@ %@",kRemoteControlAppleScript, model.executeCommand];
                            [self executeShellCommand:command];
                        }
                    });
                }
                NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
                NSString *callBack = [NSString stringWithFormat:@"小助手收到一条指令：%@",model.function];
                MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
                [service SendTextMessage:currentUserName toUsrName:currentUserName msgText:callBack atUserList:nil];
                *stop = YES;
                *subStop = YES;
            }
        }];
    }];
}

+ (BOOL)sholdExecuteRemoteControlWithModel:(TKRemoteControlModel *)model msg:(NSString *)msg msgType:(MessageDataType)type {
    if (model.enable && ![model.keyword isEqualToString:@""]) {
        if ((type == MessageDataTypeText && [msg isEqualToString:model.keyword]) || (type == MessageDataTypeVoice && [msg containsString:model.keyword])) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

/**
 通过 NSTask 执行 Shell 命令

 @param cmd Terminal命令
 */
+ (void)executeShellCommand:(NSString *)cmd {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:@[@"-c", cmd]];
    [task launch];
}

+ (NSString *)remoteControlCommandsString {
    NSMutableString *replyContent = [NSMutableString stringWithFormat:@"远程控制指令：\n(功能-指令-是否开启)\n\n"];

    NSArray *remoteControlModels = [TKWeChatPluginConfig sharedConfig].remoteControlModels;
    [remoteControlModels enumerateObjectsUsingBlock:^(NSArray *subModels, NSUInteger index, BOOL * _Nonnull stop) {
        switch (index) {
            case 0:
                [replyContent appendString:@"macbook控制:\n"];
                break;
            case 1:
                [replyContent appendString:@"app控制:\n"];
                break;
            case 2:
                [replyContent appendString:@"网易云音乐控制:\n"];
                break;
            default:
                break;
        }
        [subModels enumerateObjectsUsingBlock:^(TKRemoteControlModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            [replyContent appendFormat:@"%@-%@-%@\n", model.function, model.keyword, model.enable ? @"开启":@"关闭"];
        }];
        [replyContent appendString:@"\n"];
    }];
    return replyContent;
}

@end

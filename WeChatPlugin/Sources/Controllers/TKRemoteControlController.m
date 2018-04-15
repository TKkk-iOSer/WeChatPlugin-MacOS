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
    NSString *callBack = [NSString stringWithFormat:@"%@\n\n\n%@", TKLocalizedString(@"assistant.remoteControl.voiceRecall"), msg];
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
                if ([model.function isEqualToString:@"Assistant.Directive.ScreenSave"] || [model.function isEqualToString:@"Assistant.Directive.LockScreen"]) {
                    //      屏幕保护 & 锁屏 通过 Shell 命令来执行即可
                    [self executeShellCommand:model.executeCommand];
                } else {
                    //      拼接相关参数，执行 AppleScript
                    NSString *command = [NSString stringWithFormat:@"%@ %@",kRemoteControlAppleScript, model.executeCommand];
                    [self executeShellCommand:command];
                    //      bug: 有些程序在第一次时会无法关闭，需要再次关闭
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if ([model.function isEqualToString:@"Assistant.Directive.KillAll"]) {
                            NSString *command = [NSString stringWithFormat:@"%@ %@",kRemoteControlAppleScript, model.executeCommand];
                            [self executeShellCommand:command];
                        }
                    });
                }
                NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
                NSString *callBack = [NSString stringWithFormat:@"%@%@", TKLocalizedString(@"assistant.remoteControl.recall"), model.function];
                MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
                [service SendTextMessage:currentUserName toUsrName:currentUserName msgText:callBack atUserList:nil];
                [service ClearUnRead:currentUserName FromID:0 ToID:0];
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
    NSMutableString *replyContent = [NSMutableString stringWithString:TKLocalizedString(@"assistant.remoteControl.listTip")];

    NSArray *remoteControlModels = [TKWeChatPluginConfig sharedConfig].remoteControlModels;
    [remoteControlModels enumerateObjectsUsingBlock:^(NSArray *subModels, NSUInteger index, BOOL * _Nonnull stop) {
        switch (index) {
            case 0:
                [replyContent appendFormat:@"%@:\n",TKLocalizedString(@"assistant.remoteControl.mac")];
                break;
            case 1:
                [replyContent appendFormat:@"%@:\n",TKLocalizedString(@"assistant.remoteControl.app")];
                break;
            case 2:
                [replyContent appendFormat:@"%@:\n",TKLocalizedString(@"assistant.remoteControl.neteaseMusic")];
                break;
            default:
                break;
        }
        [subModels enumerateObjectsUsingBlock:^(TKRemoteControlModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            [replyContent appendFormat:@"%@-%@-%@\n", model.function, model.keyword, model.enable ? TKLocalizedString(@"assistant.remoteControl.open") : TKLocalizedString(@"assistant.remoteControl.close")];
        }];
        [replyContent appendString:@"\n"];
    }];
    return replyContent;
}

@end

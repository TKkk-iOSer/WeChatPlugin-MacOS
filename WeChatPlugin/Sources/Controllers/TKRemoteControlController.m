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

//      执行 AppleScript
static NSString * const kRemoteControlAppleScript = @"osascript /Applications/WeChat.app/Contents/MacOS/WeChatPlugin.framework/Resources/TKRemoteControlScript.scpt";

@implementation TKRemoteControlController

+ (void)executeRemoteControlCommandWithMsg:(NSString *)msg {
    NSArray *remoteControlModels = [TKWeChatPluginConfig sharedConfig].remoteControlModels;
    [remoteControlModels enumerateObjectsUsingBlock:^(NSArray *subModels, NSUInteger index, BOOL * _Nonnull stop) {
        [subModels enumerateObjectsUsingBlock:^(TKRemoteControlModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            if (model.enable && ![model.keyword isEqualToString:@""] && [msg isEqualToString:model.keyword]) {
                if ([model.function isEqualToString:@"屏幕保護"] || [model.function isEqualToString:@"鎖屏"]) {
                    //      屏幕保護 & 鎖屏 通过 Shell 命令来执行即可
                    [self executeShellCommand:model.executeCommand];
                } else {
                    //      拼接相关参数，执行 AppleScript
                    NSString *command = [NSString stringWithFormat:@"%@ %@",kRemoteControlAppleScript, model.executeCommand];
                    [self executeShellCommand:command];
                    //      bug: 有些程式在第一次时会无法關閉，需要再次關閉
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if ([model.function isEqualToString:@"退出所有程式"]) {
                            NSString *command = [NSString stringWithFormat:@"%@ %@",kRemoteControlAppleScript, model.executeCommand];
                            [self executeShellCommand:command];
                        }
                    });
                }
                NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
                NSString *callBack = [NSString stringWithFormat:@"小助手收到一則指令：%@",model.function];
                MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
                [service SendTextMessage:currentUserName toUsrName:currentUserName msgText:callBack atUserList:nil];
            }
        }];
    }];
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
    NSMutableString *replyContent = [NSMutableString stringWithFormat:@"遠端控制指令：\n(功能-指令-是否開啟)\n\n"];

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
                [replyContent appendString:@"网易云音樂控制:\n"];
                break;
            default:
                break;
        }
        [subModels enumerateObjectsUsingBlock:^(TKRemoteControlModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            [replyContent appendFormat:@"%@-%@-%@\n", model.function, model.keyword, model.enable ? @"開啟":@"關閉"];
        }];
        [replyContent appendString:@"\n"];
    }];
    return replyContent;
}

@end

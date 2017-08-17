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

//      执行 AppleScript
static NSString * const kRemoteControlAppleScript = @"osascript /Applications/WeChat.app/Contents/MacOS/WeChatPlugin.framework/Resources/TKRemoteControlScript.scpt";

@implementation TKRemoteControlController

+ (void)executeRemoteControlCommandWithMsg:(NSString *)msg {
    NSArray *remoteControlModels = [TKWeChatPluginConfig sharedConfig].remoteControlModels;
    [remoteControlModels enumerateObjectsUsingBlock:^(NSArray *subModels, NSUInteger index, BOOL * _Nonnull stop) {
        [subModels enumerateObjectsUsingBlock:^(TKRemoteControlModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            if (model.enable && ![model.keyword isEqualToString:@""] && [msg isEqualToString:model.keyword]) {
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

@end

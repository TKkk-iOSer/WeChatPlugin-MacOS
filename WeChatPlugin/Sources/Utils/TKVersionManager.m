//
//  TKVersionManager.m
//  WeChatPlugin
//
//  Created by TK on 2018/2/24.
//  Copyright © 2018年 tk. All rights reserved.
//

#import "TKVersionManager.h"
#import "TKWeChatPluginConfig.h"

@implementation TKVersionManager

+ (instancetype)shareManager {
    static TKVersionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TKVersionManager alloc] init];
    });
    return manager;
}

- (void)checkVersionFinish:(void (^)(TKVersionStatus, NSString *))finish {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *localInfo = [[TKWeChatPluginConfig sharedConfig] localInfoPlist];
        NSDictionary *romoteInfo = [[TKWeChatPluginConfig sharedConfig] romoteInfoPlist];
        NSString *localBundle = localInfo[@"CFBundleShortVersionString"];
        NSString *romoteBundle = romoteInfo[@"CFBundleShortVersionString"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([localBundle isEqualToString:romoteBundle]) {
                NSString *versionMsg = [localInfo[@"versionInfo"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                finish(TKVersionStatusOld, versionMsg);
            } else if (romoteInfo[@"versionInfo"]) {
                NSString *versionMsg = [romoteInfo[@"versionInfo"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                finish(TKVersionStatusNew, versionMsg);
            }
        });
    });
}

@end

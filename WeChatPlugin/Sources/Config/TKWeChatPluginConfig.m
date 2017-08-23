//
//  TKWeChatPluginConfig.m
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "TKWeChatPluginConfig.h"
#import "TKRemoteControlModel.h"
#import "TKAutoReplyModel.h"

static NSString * const kTKPreventRevokeEnableKey = @"kTKPreventRevokeEnableKey";
static NSString * const kTKAutoReplyModelsFilePath = @"/Applications/WeChat.app/Contents/MacOS/WeChatPlugin.framework/Resources/TKAutoReplyModels.plist";
static NSString * const kTKRemoteControlModelsFilePath = @"/Applications/WeChat.app/Contents/MacOS/WeChatPlugin.framework/Resources/TKRemoteControlCommands.plist";

@implementation TKWeChatPluginConfig

+ (instancetype)sharedConfig {
    static TKWeChatPluginConfig *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[TKWeChatPluginConfig alloc] init];
    });
    
    return config;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _preventRevokeEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kTKPreventRevokeEnableKey];
    }
    return self;
}

- (void)setPreventRevokeEnable:(BOOL)preventRevokeEnable {
    _preventRevokeEnable = preventRevokeEnable;
    [[NSUserDefaults standardUserDefaults] setBool:preventRevokeEnable forKey:kTKPreventRevokeEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - 自动回复
- (NSArray *)autoReplyModels {
    if (!_autoReplyModels) {
        _autoReplyModels = ({
            NSArray *originModels = [NSArray arrayWithContentsOfFile:kTKAutoReplyModelsFilePath];
            NSMutableArray *newModels = [NSMutableArray array];
            [originModels enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
                TKAutoReplyModel *model = [[TKAutoReplyModel alloc] initWithDict:dict];
                [newModels addObject:model];
            }];
            
            newModels;
        });
    }
    return _autoReplyModels;
}

- (void)saveAutoReplyModels {
    NSMutableArray *needSaveModels = [NSMutableArray array];
    [_autoReplyModels enumerateObjectsUsingBlock:^(TKAutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (model.hasEmptyKeywordOrReplyContent) {
            model.enable = NO;
            model.enableGroupReply = NO;
        }
        model.replyContent = model.replyContent == nil ? @"" : model.replyContent;
        model.keyword = model.keyword == nil ? @"" : model.keyword;
        [needSaveModels addObject:model.dictionary];
    }];
    [needSaveModels writeToFile:kTKAutoReplyModelsFilePath atomically:YES];
}

#pragma mark - 远程控制
- (NSArray *)remoteControlModels {
    if (!_remoteControlModels) {
        _remoteControlModels = ({
            NSArray *originModels = [NSArray arrayWithContentsOfFile:kTKRemoteControlModelsFilePath];
            NSMutableArray *newRemoteControlModels = [NSMutableArray array];
            [originModels enumerateObjectsUsingBlock:^(NSArray *subModels, NSUInteger idx, BOOL * _Nonnull stop) {
                NSMutableArray *newSubModels = [NSMutableArray array];
                [subModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    TKRemoteControlModel *model = [[TKRemoteControlModel alloc] initWithDict:obj];
                    [newSubModels addObject:model];
                }];
                [newRemoteControlModels addObject:newSubModels];
            }];
            
            newRemoteControlModels;
        });
    }
    return _remoteControlModels;
}

- (void)saveRemoteControlModels {
    NSMutableArray *needSaveModels = [NSMutableArray array];
    [_remoteControlModels enumerateObjectsUsingBlock:^(NSArray *subModels, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray *newSubModels = [NSMutableArray array];
        [subModels enumerateObjectsUsingBlock:^(TKRemoteControlModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [newSubModels addObject:obj.dictionary];
        }];
        [needSaveModels addObject:newSubModels];
    }];
    [needSaveModels writeToFile:kTKRemoteControlModelsFilePath atomically:YES];
}

@end

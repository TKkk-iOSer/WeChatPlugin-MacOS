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
#import "TKIgnoreSessonModel.h"

static NSString * const kTKPreventRevokeEnableKey = @"kTKPreventRevokeEnableKey";
static NSString * const kTKAutoAuthEnableKey = @"kTKAutoAuthEnableKey";

static NSString * const kTKAutoReplyModelsFilePath = @"/Applications/WeChat.app/Contents/MacOS/WeChatPlugin.framework/Resources/TKAutoReplyModels.plist";
static NSString * const kTKRemoteControlModelsFilePath = @"/Applications/WeChat.app/Contents/MacOS/WeChatPlugin.framework/Resources/TKRemoteControlCommands.plist";

static NSString * const kTKIgnoreSessionModelsFilePath = @"/Applications/WeChat.app/Contents/MacOS/WeChatPlugin.framework/Resources/TKIgnoreSessons.plist";

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
        _autoAuthEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kTKAutoAuthEnableKey];
    }
    return self;
}

- (void)setPreventRevokeEnable:(BOOL)preventRevokeEnable {
    _preventRevokeEnable = preventRevokeEnable;
    [[NSUserDefaults standardUserDefaults] setBool:preventRevokeEnable forKey:kTKPreventRevokeEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoAuthEnable:(BOOL)autoAuthEnable {
    _autoAuthEnable = autoAuthEnable;
    [[NSUserDefaults standardUserDefaults] setBool:autoAuthEnable forKey:kTKAutoAuthEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
#pragma mark - 自动回复
- (NSArray *)autoReplyModels {
    if (!_autoReplyModels) {
        _autoReplyModels = [self getArrayClass:[TKAutoReplyModel class] filePath:kTKAutoReplyModelsFilePath];
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

#pragma mark - 置底
- (NSArray *)ignoreSessionModels {
    if (!_ignoreSessionModels) {
        _ignoreSessionModels = [self getArrayClass:[TKIgnoreSessonModel class] filePath:kTKIgnoreSessionModelsFilePath];
        
    }
    return _ignoreSessionModels;
}

- (void)saveIgnoreSessionModels {
    [self saveArray:_ignoreSessionModels filePath:kTKIgnoreSessionModelsFilePath];
}

#pragma mark - common

- (NSMutableArray *)getArrayClass:(Class)class filePath:(NSString *)filePath {
    NSArray *originModels = [NSArray arrayWithContentsOfFile:filePath];
    NSMutableArray *newModels = [NSMutableArray array];
    
    __weak Class weakClass = class;
    [originModels enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TKIgnoreSessonModel *model = [[weakClass alloc] initWithDict:obj];
        [newModels addObject:model];
    }];
    
   return newModels;
    
}

- (void)saveArray:(NSMutableArray *)array filePath:(NSString *)filePath {
    NSMutableArray *needSaveArray = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(TKBaseModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [needSaveArray addObject:obj.dictionary];
    }];
    
    [needSaveArray writeToFile:filePath atomically:YES];
}

@end

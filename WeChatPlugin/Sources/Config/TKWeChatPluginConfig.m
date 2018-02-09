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
static NSString * const kTKAutoLoginEnableKey = @"kTKAutoLoginEnableKey";
static NSString * const kTKOnTopKey = @"kTKOnTopKey";
static NSString * const kTKWeChatResourcesPath = @"/Applications/WeChat.app/Contents/MacOS/WeChatPlugin.framework/Resources/";

@interface TKWeChatPluginConfig ()

@property (nonatomic, copy) NSString *remoteControlPlistFilePath;
@property (nonatomic, copy) NSString *autoReplyPlistFilePath;
@property (nonatomic, copy) NSString *ignoreSessionPlistFilePath;

@end

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
        _autoLoginEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kTKAutoLoginEnableKey];
        _onTop = [[NSUserDefaults standardUserDefaults] boolForKey:kTKOnTopKey];
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

- (void)setAutoLoginEnable:(BOOL)autoLoginEnable {
    _autoLoginEnable = autoLoginEnable;
    [[NSUserDefaults standardUserDefaults] setBool:autoLoginEnable forKey:kTKAutoLoginEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setOnTop:(BOOL)onTop {
    _onTop = onTop;
    [[NSUserDefaults standardUserDefaults] setBool:_onTop forKey:kTKOnTopKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - 自动回复
- (NSArray *)autoReplyModels {
    if (!_autoReplyModels) {
        _autoReplyModels = [self getModelsWithClass:[TKAutoReplyModel class] filePath:self.autoReplyPlistFilePath];
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
    [needSaveModels writeToFile:self.autoReplyPlistFilePath atomically:YES];
}

#pragma mark - 远程控制
- (NSArray *)remoteControlModels {
    if (!_remoteControlModels) {
        _remoteControlModels = ({
            NSArray *originModels = [NSArray arrayWithContentsOfFile:self.remoteControlPlistFilePath];
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
    [needSaveModels writeToFile:self.remoteControlPlistFilePath atomically:YES];
}

#pragma mark - 置底
- (NSArray *)ignoreSessionModels {
    if (!_ignoreSessionModels) {
        _ignoreSessionModels = [self getModelsWithClass:[TKIgnoreSessonModel class] filePath:self.ignoreSessionPlistFilePath];
    }
    return _ignoreSessionModels;
}

- (void)saveIgnoreSessionModels {
    NSMutableArray *needSaveArray = [NSMutableArray array];
    [self.ignoreSessionModels enumerateObjectsUsingBlock:^(TKBaseModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [needSaveArray addObject:obj.dictionary];
    }];
    
    [needSaveArray writeToFile:self.ignoreSessionPlistFilePath atomically:YES];
    
}

#pragma mark - 选中的会话
- (NSMutableArray *)selectSessions {
    if (!_selectSessions) {
        _selectSessions = [NSMutableArray array];
    }
    return _selectSessions;
}

#pragma mark - 获取沙盒上的 plist 文件，包括：远程控制，自动回复，置底列表。
- (NSString *)remoteControlPlistFilePath {
    if (!_remoteControlPlistFilePath) {
        _remoteControlPlistFilePath = [self getSandboxFilePathWithPlistName:@"TKRemoteControlCommands.plist"];
    }
    return _remoteControlPlistFilePath;
}

- (NSString *)autoReplyPlistFilePath {
    if (!_autoReplyPlistFilePath) {
        _autoReplyPlistFilePath = [self getSandboxFilePathWithPlistName:@"TKAutoReplyModels.plist"];
    }
    return _autoReplyPlistFilePath;
}

- (NSString *)ignoreSessionPlistFilePath {
    if (!_ignoreSessionPlistFilePath) {
        _ignoreSessionPlistFilePath = [self getSandboxFilePathWithPlistName:@"TKIgnoreSessons.plist"];
    }
    return _ignoreSessionPlistFilePath;
}

#pragma mark - common
- (NSMutableArray *)getModelsWithClass:(Class)class filePath:(NSString *)filePath {
    NSArray *originModels = [NSArray arrayWithContentsOfFile:filePath];
    NSMutableArray *newModels = [NSMutableArray array];
    
    __weak Class weakClass = class;
    [originModels enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TKIgnoreSessonModel *model = [[weakClass alloc] initWithDict:obj];
        [newModels addObject:model];
    }];
    return newModels;
}

- (NSString *)getSandboxFilePathWithPlistName:(NSString *)plistName {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *wechatPluginDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"TKWeChatPlugin"];
    NSString *plistFilePath = [wechatPluginDirectory stringByAppendingPathComponent:plistName];
    if ([manager fileExistsAtPath:plistFilePath]) {
        return plistFilePath;
    }
    
    [manager createDirectoryAtPath:wechatPluginDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *resourcesFilePath = [kTKWeChatResourcesPath stringByAppendingString:plistName];
    if (![manager fileExistsAtPath:resourcesFilePath]) {
        return plistFilePath;
    }
    
    NSError *error = nil;
    [manager copyItemAtPath:resourcesFilePath toPath:plistFilePath error:&error];
    if (!error) {
        return plistFilePath;
    }
    
    return resourcesFilePath;
}

@end

//
//  TKWeChatPluginConfig.m
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "TKWeChatPluginConfig.h"

static NSString * const kTKPreventRevokeEnableKey = @"kTKPreventRevokeEnableKey";
static NSString * const kTKAutoReplyEnableKey = @"kTKAutoReplyEnableKey";
static NSString * const kTKAutoReplyKeywordKey = @"kTKAutoReplyKeywordKey";
static NSString * const kTKAutoReplyTextKey = @"kTKAutoReplyTextKey";

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
        _autoReplyEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kTKAutoReplyEnableKey];
        _autoReplyKeyword = [[NSUserDefaults standardUserDefaults] objectForKey:kTKAutoReplyKeywordKey];
        _autoReplyText = [[NSUserDefaults standardUserDefaults] objectForKey:kTKAutoReplyTextKey];
    }
    return self;
}

- (void)setPreventRevokeEnable:(BOOL)preventRevokeEnable {
    _preventRevokeEnable = preventRevokeEnable;
    [[NSUserDefaults standardUserDefaults] setBool:preventRevokeEnable forKey:kTKPreventRevokeEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyEnable:(BOOL)autoReplyEnable {
    _autoReplyEnable = autoReplyEnable;
    [[NSUserDefaults standardUserDefaults] setBool:autoReplyEnable forKey:kTKAutoReplyEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyKeyword:(NSString *)autoReplyKeyword {
    _autoReplyKeyword = autoReplyKeyword;
    [[NSUserDefaults standardUserDefaults] setObject:autoReplyKeyword forKey:kTKAutoReplyKeywordKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyText:(NSString *)autoReplyText {
    _autoReplyText = autoReplyText;
    [[NSUserDefaults standardUserDefaults] setObject:autoReplyText forKey:kTKAutoReplyTextKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

//
//  TKAutoReplyWindowController.m
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "TKAutoReplyWindowController.h"
#import "WeChatPlugin.h"

@interface TKAutoReplyWindowController ()

@property (weak) IBOutlet NSTextField *keywordTextField;
@property (weak) IBOutlet NSTextField *autoReplyTextField;
@property (weak) IBOutlet NSButton *saveButton;

@end

@implementation TKAutoReplyWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.title = @"自动回复设置";
    [self setup];
}

- (void)setup {
    TKWeChatPluginConfig *config = [TKWeChatPluginConfig sharedConfig];
    self.keywordTextField.stringValue = config.autoReplyKeyword != nil ? config.autoReplyKeyword : @"";
    self.autoReplyTextField.stringValue = config.autoReplyText != nil ? config.autoReplyText : @"";
}

- (IBAction)saveAutoReplySetting:(id)sender {
    [[TKWeChatPluginConfig sharedConfig] setAutoReplyEnable:YES];
    [[TKWeChatPluginConfig sharedConfig] setAutoReplyKeyword:self.keywordTextField.stringValue];
    [[TKWeChatPluginConfig sharedConfig] setAutoReplyText:self.autoReplyTextField.stringValue];
    if (self.startAutoReply) {
        self.startAutoReply();
    }
    [self close];
}

@end

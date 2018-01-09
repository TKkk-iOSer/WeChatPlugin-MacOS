//
//  TKAutoReplyContentView.m
//  WeChatPlugin
//
//  Created by TK on 2017/8/20.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "TKAutoReplyContentView.h"

@interface TKAutoReplyContentView () <NSTextFieldDelegate>

@property (nonatomic, strong) NSTextField *keywordLabel;
@property (nonatomic, strong) NSTextField *keywordTextField;
@property (nonatomic, strong) NSTextField *autoReplyLabel;
@property (nonatomic, strong) NSTextField *autoReplyContentField;
@property (nonatomic, strong) NSButton *enableGroupReplyBtn;
@property (nonatomic, strong) NSButton *enableSingleReplyBtn;
@property (nonatomic, strong) NSButton *enableRegexBtn;

@end

@implementation TKAutoReplyContentView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    self.enableRegexBtn = ({
        NSButton *btn = [NSButton tk_checkboxWithTitle:@"開啟正規匹配" target:self action:@selector(clickEnableRegexBtn:)];
        btn.frame = NSMakeRect(20, 15, 400, 20);
        
        btn;
    });
    
    self.enableGroupReplyBtn = ({
        NSButton *btn = [NSButton tk_checkboxWithTitle:@"開啟群聊自動回覆" target:self action:@selector(clickEnableGroupBtn:)];
        btn.frame = NSMakeRect(20, 40, 400, 20);
        
        btn;
    });
    
    self.enableSingleReplyBtn = ({
        NSButton *btn = [NSButton tk_checkboxWithTitle:@"開啟私聊自動回覆" target:self action:@selector(clickEnableSingleBtn:)];
        btn.frame = NSMakeRect(200, 40, 400, 20);
        
        btn;
    });
    
    self.autoReplyContentField = ({
        NSTextField *textField = [[NSTextField alloc] init];
        textField.frame = NSMakeRect(20, 70, 350, 175);
        textField.placeholderString = @"請輸入自動回覆的内容（‘|’ 為隨機回覆其中任一内容）";
        textField.delegate = self;
        
        textField;
    });
    
    self.autoReplyLabel = ({
        NSTextField *label = [NSTextField tk_labelWithString:@"自動回覆："];
        label.frame = NSMakeRect(20, 250, 350, 20);
        
        label;
    });
    
    self.keywordTextField = ({
        NSTextField *textField = [[NSTextField alloc] init];
        textField.frame = NSMakeRect(20, 290, 350, 50);
        textField.placeholderString = @"請輸入關鍵字（ ‘*’ 為任何消息都回覆，‘|’ 為匹配多個關鍵字）";
        textField.delegate = self;
        
        textField;
    });
    
    self.keywordLabel = ({
        NSTextField *label = [NSTextField tk_labelWithString:@"關鍵字："];
        label.frame = NSMakeRect(20, 345, 350, 20);
        
        label;
    });
    
    [self addSubviews:@[self.enableRegexBtn,
                        self.enableGroupReplyBtn,
                        self.enableSingleReplyBtn,
                        self.autoReplyContentField,
                        self.autoReplyLabel,
                        self.keywordTextField,
                        self.keywordLabel]];
}

- (void)clickEnableRegexBtn:(NSButton *)btn {
    self.model.enableRegex = btn.state;
}

- (void)clickEnableGroupBtn:(NSButton *)btn {
    self.model.enableGroupReply = btn.state;
    if (btn.state) {
        self.model.enable = YES;
    } else if(!self.model.enableSingleReply) {
        self.model.enable = NO;
    }
    
    if (self.endEdit) self.endEdit();
}

- (void)clickEnableSingleBtn:(NSButton *)btn {
    self.model.enableSingleReply = btn.state;
    if (btn.state) {
        self.model.enable = YES;
    } else if(!self.model.enableGroupReply) {
        self.model.enable = NO;
    }
    if (self.endEdit) self.endEdit();
}

- (void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview];
    self.layer.backgroundColor = [kBG2 CGColor];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [TK_RGBA(0, 0, 0, 0.1) CGColor];
    self.layer.cornerRadius = 3;
    self.layer.masksToBounds = YES;
    [self.layer setNeedsDisplay];
}

- (void)setModel:(TKAutoReplyModel *)model {
    _model = model;
    self.keywordTextField.stringValue = model.keyword != nil ? model.keyword : @"";
    self.autoReplyContentField.stringValue = model.replyContent != nil ? model.replyContent : @"";
    self.enableGroupReplyBtn.state = model.enableGroupReply;
    self.enableSingleReplyBtn.state = model.enableSingleReply;
    self.enableRegexBtn.state = model.enableRegex;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    if (self.endEdit) self.endEdit();
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSControl *control = notification.object;
    if (control == self.keywordTextField) {
        self.model.keyword = self.keywordTextField.stringValue;
    } else if (control == self.autoReplyContentField) {
        self.model.replyContent = self.autoReplyContentField.stringValue;
    }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    BOOL result = NO;
    
    if (commandSelector == @selector(insertNewline:)) {
        [textView insertNewlineIgnoringFieldEditor:self];
        result = YES;
    } else if (commandSelector == @selector(insertTab:)) {
        if (control == self.keywordTextField) {
            [self.autoReplyContentField becomeFirstResponder];
        } else if (control == self.autoReplyContentField) {
            [self.keywordTextField becomeFirstResponder];
        }
    }
    
    return result;
}

@end

//
//  TKDownloadProgressView.m
//  WeChatPlugin
//
//  Created by TK on 2018/4/21.
//  Copyright © 2018年 tk. All rights reserved.
//

#import "TKDownloadProgressView.h"


@interface TKDownloadProgressView ()

@property (nonatomic, strong) NSTextField *titleView;
@property (nonatomic, strong) NSTextField *progressView;
@property (nonatomic, strong) NSProgressIndicator *indicator;

@end

@implementation TKDownloadProgressView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    
    self.titleView = ({
        NSTextField *label = [NSTextField tk_labelWithString:@""];
        label.placeholderString = TKLocalizedString(@"assistant.autoReply.content");
        [[label cell] setLineBreakMode:NSLineBreakByCharWrapping];
        [[label cell] setTruncatesLastVisibleLine:YES];
        label.frame = NSMakeRect(0, 45, 160, 15);
        
        label;
    });
    
    self.progressView = ({
        NSTextField *label = [NSTextField tk_labelWithString:@""];
        label.placeholderString = TKLocalizedString(@"assistant.autoReply.keyword");
        [[label cell] setLineBreakMode:NSLineBreakByCharWrapping];
        [[label cell] setTruncatesLastVisibleLine:YES];
        label.font = [NSFont systemFontOfSize:10];
        label.frame = NSMakeRect(0, 0, 160, 15);
        
        label;
    });
    
    self.indicator = ({
        NSProgressIndicator *indicator = [[NSProgressIndicator alloc] init];
        indicator.frame = NSMakeRect(0, 20, 220, 15);
        
        indicator;
    });
    
    [self addSubviews:@[self.titleView,
                        self.progressView,
                        self.indicator]];
    self.titleView.stringValue = @"标题";
    self.progressView.stringValue = @"正在下载";
}

- (void)setProgress:(NSProgress *)progress {

    self.titleView.stringValue = @"正在下";
    self.progressView.stringValue = @"正在下";
//    if (model.keyword == nil && model.replyContent == nil) return;
//
//    self.selectBtn.state = model.enable;
//    self.keywordLabel.stringValue = model.keyword != nil ? model.keyword : @"";
//    self.replyContentLabel.stringValue = model.replyContent != nil ? model.replyContent : @"";
}
@end

//
//  TKEmojiCollectionView.m
//  WeChatPlugin
//
//  Created by KenHan on 2018/7/20.
//  Copyright © 2018 tk. All rights reserved.
//

#import "TKEmojiCollectionViewItem.h"

#import "TKEmojiItem.h"

@interface TKEmojiCollectionViewItem ()

@end


@implementation TKEmojiCollectionViewItem
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
}

- (void)loadView {
    self.view = [[TKEmojiItem alloc] init];
    self.collImageView = [[NSImageView alloc] initWithFrame:self.view.bounds];
    self.collImageView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.view addSubview:self.collImageView];
}


// 重写选中方法
- (void)setSelected:(BOOL)selected
{
    [(TKEmojiItem *)[self view] setIsSelected:selected];
    [super setSelected:selected];
}

@end

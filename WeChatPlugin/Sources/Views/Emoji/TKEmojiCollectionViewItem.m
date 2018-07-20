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

//@property (weak) IBOutlet NSImageView *collImageView;
@property (weak) IBOutlet NSImageView *collImageView;
@property (weak) IBOutlet NSTextField *titleField;

@end


@implementation TKEmojiCollectionViewItem
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
}

- (void)viewWillAppear {
    if(!self.representedObject){
        return;
    }
    self.collImageView.image = [self.representedObject objectForKey:@"image"];
    self.titleField.stringValue = [self.representedObject objectForKey:@"title"];
    
}



// 重写选中方法
- (void)setSelected:(BOOL)selected
{
    [(TKEmojiItem *)[self view] setIsSelected:selected];
    [super setSelected:selected];
}

@end

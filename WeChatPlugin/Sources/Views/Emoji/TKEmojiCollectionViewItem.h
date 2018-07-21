//
//  TKEmojiCollectionView.h
//  WeChatPlugin
//
//  Created by KenHan on 2018/7/20.
//  Copyright © 2018 tk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TKEmojiCollectionViewItem : NSCollectionViewItem
@property (nonatomic, strong) NSImageView *collImageView;
@property (nonatomic, strong) NSString *imageName;
@end

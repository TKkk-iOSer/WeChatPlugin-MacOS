//
//  TKEmojiItem.h
//  WeChatPlugin
//
//  Created by KenHan on 2018/7/20.
//  Copyright © 2018 tk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TKEmojiItem : NSView

@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) NSCollectionViewItemHighlightState highlightState;
@end

//
//  NSObject+MMStickerPickerCell.m
//  WeChatPlugin
//
//  Created by TK on 2019/3/13.
//  Copyright © 2019 tk. All rights reserved.
//

#import "MMStickerPickerCell+hook.h"
#import "TKEmoticonManager.h"

@implementation NSObject (MMStickerPickerCell)

+ (void)hookMMStickerPickerCell {
    tk_hookMethod(objc_getClass("MMStickerPickerCell"), @selector(rightMouseDown:), [self class], @selector(hook_rightMouseDown:));
}

- (void)hook_rightMouseDown:(id)theEvent {
    [self hook_rightMouseDown:theEvent];
    if ([self.className isEqualToString:@"MMStickerPickerCell"]) {
        MMStickerPickerCell *pickerCell = (MMStickerPickerCell *)self;
        NSMenu *popupMenu = [[NSMenu alloc] init];
        popupMenu.delegate = pickerCell;
        
        NSMenuItem *preventRevokeItem = [[NSMenuItem alloc] initWithTitle:@"存储" action:@selector(pickerExportEmoji) keyEquivalent:@""];
        
        NSMenuItem *copyItem = [[NSMenuItem alloc] initWithTitle:@"复制" action:@selector(pickerCopyEmoji) keyEquivalent:@""];
        [popupMenu addItems:@[preventRevokeItem,copyItem]];
        [NSMenu popUpContextMenu:popupMenu withEvent:theEvent forView:pickerCell];
    }
}

- (void)pickerExportEmoji {
    if (![self.className isEqualToString:@"MMStickerPickerCell"]) return;
    
    MMStickerPickerCell *currentCellView = (MMStickerPickerCell *)self;
    MMEmoticonData *emotionData = currentCellView.emoticonData;
    if (!emotionData.md5) {
        return;
    }
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    MMMainWindowController *mainWC = wechat.mainWindowController;
    [[TKEmoticonManager shareManager] exportEmoticonWithMd5:emotionData.md5 window:mainWC.window];
}

- (void)pickerCopyEmoji {
    if (![self.className isEqualToString:@"MMStickerPickerCell"]) return;
    
    MMStickerPickerCell *currentCellView = (MMStickerPickerCell *)self;
    MMEmoticonData *emotionData = currentCellView.emoticonData;
    if (!emotionData.md5) {
        return;
    }
    [[TKEmoticonManager shareManager] copyEmoticonWithMd5:emotionData.md5];
    if([currentCellView.collectionView respondsToSelector:@selector(delegate)]) {
       MMStickerCollectionViewController *stickerVC = [currentCellView.collectionView performSelector:@selector(delegate)];
        MMStickerPicker *picker = stickerVC.delegate;
        [picker hide];
    }
}

@end

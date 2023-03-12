//
//  TKEmoticonManager.m
//  WeChatPlugin
//
//  Created by TK on 2019/3/13.
//  Copyright © 2019 tk. All rights reserved.
//

#import "TKEmoticonManager.h"
#import "WeChatPlugin.h"

@implementation TKEmoticonManager

+ (instancetype)shareManager {
    static TKEmoticonManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TKEmoticonManager alloc] init];
    });
    return manager;
}

- (void)copyEmoticonWithMd5:(NSString *)md5Str {
    if (!md5Str) {
        return;
    }
    
    EmoticonMgr *emoticonMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("EmoticonMgr")];
    NSData *imageData = [emoticonMgr getEmotionDataWithMD5:md5Str];
    if (!imageData) return;
    
    NSString *imageType = [TKUtility getTypeForImageData:imageData];
    if (![imageType isEqualToString:@"gif"]) {
        NSImage *image = [emoticonMgr getEmotionImgWithMD5:md5Str];
        image = [self resizeImage:image forSize:CGSizeMake(60, 60)];
        imageData = [image TIFFRepresentation];
    }
    NSString *imageName = [NSString stringWithFormat:@"temp_paste_image_%@.%@", md5Str, imageType];
    NSString *tempImageFilePath = [NSTemporaryDirectory() stringByAppendingString:imageName];
    NSURL *imageUrl = [NSURL fileURLWithPath:tempImageFilePath];
    [imageData writeToURL:imageUrl atomically:YES];
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard declareTypes:@[NSFilenamesPboardType] owner:nil];
    [pasteboard writeObjects:@[imageUrl]];
}

- (NSImage *)resizeImage:(NSImage *)sourceImage forSize:(NSSize)size {
    NSRect targetFrame = NSMakeRect(0, 0, size.width, size.height);
    NSSize imageSize = sourceImage.size;
    if (imageSize.height * 0.5 < size.height && imageSize.width * 0.5 < size.width) {
        targetFrame = NSMakeRect(0, 0, imageSize.width * 0.5, imageSize.height * 0.5);
    } else {
        if (imageSize.height > imageSize.width) {
            targetFrame = NSMakeRect(0, 0, imageSize.width / imageSize.height * size.width, size.height);
        } else {
            targetFrame = NSMakeRect(0, 0, size.width, size.height * imageSize.height / imageSize.width);
        }
    }
    NSImageRep *sourceImageRep = [sourceImage bestRepresentationForRect:targetFrame context:nil hints:nil];
    NSImage *targetImage = [[NSImage alloc] initWithSize:targetFrame.size];
    
    [targetImage lockFocus];
    [sourceImageRep drawInRect: targetFrame];
    [targetImage unlockFocus];
    
    return targetImage;
}

- (void)exportEmoticonWithMd5:(NSString *)md5Str window:(NSWindow *)window {
    if (!md5Str || !window) {
        return;
    }
    
    EmoticonMgr *emoticonMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("EmoticonMgr")];
    NSData *imageData = [emoticonMgr getEmotionDataWithMD5:md5Str];
    if (!imageData) return;
    
    NSSavePanel *savePanel = ({
        NSSavePanel *panel = [NSSavePanel savePanel];
        [panel setDirectoryURL:[NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Pictures"]]];
        [panel setNameFieldStringValue:md5Str];
        [panel setAllowedFileTypes:@[[TKUtility getTypeForImageData:imageData]]];
        [panel setAllowsOtherFileTypes:YES];
        [panel setExtensionHidden:NO];
        [panel setCanCreateDirectories:YES];
        
        panel;
    });

    [savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            [imageData writeToFile:[[savePanel URL] path] atomically:YES];
        }
    }];
}

@end

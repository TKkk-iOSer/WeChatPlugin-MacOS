//
//  TKEmojiWindowController.m
//  WeChatPlugin
//
//  Created by KenHan on 2018/7/18.
//  Copyright © 2018 tk. All rights reserved.
//

#import "TKEmojiWindowController.h"
#import "TKEmojiCollectionViewItem.h"

@interface TKEmojiWindowController ()<NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSCollectionView *collectionView;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) NSMutableArray *imageNames;

@end


@implementation TKEmojiWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.collectionView reloadData];
//    self.window.backgroundColor = [NSColor greenColor];
    [self setup];
    [self addCollection];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [self setup];
    [self.collectionView reloadData];
}


#pragma mark -- addCollection
- (void)addCollection {

    NSCollectionViewFlowLayout *layout = [[NSCollectionViewFlowLayout alloc]init];
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    layout.itemSize = NSMakeSize(110, 110);
    layout.scrollDirection = NSCollectionViewScrollDirectionVertical;
    layout.sectionInset = NSEdgeInsetsMake(0, 0, 0, 0);

    self.collectionView = [[NSCollectionView alloc]initWithFrame:[self.window.contentView bounds]];
    self.collectionView.collectionViewLayout = layout;
    [self.collectionView registerClass:[TKEmojiCollectionViewItem class] forItemWithIdentifier:@"Emoji"];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView setSelectable:YES];

    // 给collectionview添加背景颜色
    //    [self.collectionView setWantsLayer:YES];
//    self.collectionView.layer.backgroundColor = [NSColor redColor].CGColor;
    
    self.scrollView = [[NSScrollView alloc]initWithFrame:[self.window.contentView bounds]];
//    self.scrollView.backgroundColor = [NSColor blueColor];
    [self.scrollView setDocumentView:self.collectionView];
    [self.window.contentView addSubview: self.scrollView];
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.scrollView.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor].active = YES;
    [self.scrollView.bottomAnchor constraintEqualToAnchor:self.window.contentView.bottomAnchor].active = YES;
    
    [self.scrollView.leadingAnchor constraintEqualToAnchor:self.window.contentView.leadingAnchor].active = YES;

    [self.scrollView.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor].active = YES;
    
    [self.collectionView reloadData];
}

#pragma mark -- collectionView delegate
- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView  {
    return 1;
}


- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (self.images.count == 0) {
        return 0;
    }
    return self.images.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    TKEmojiCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"Emoji" forIndexPath:indexPath];
    
    item.collImageView.image = [self.images objectAtIndex:indexPath.item];
    item.imageName = [self.imageNames objectAtIndex:indexPath.item];
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    NSLog(@"----%lu", (unsigned long)collectionView.selectionIndexes.firstIndex);
    NSString *imageName = [self.imageNames objectAtIndex:(unsigned long)collectionView.selectionIndexes.firstIndex];
    
    NSString *strpath1 = @"/Users/kenhan/Dropbox/gifs";
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", strpath1, imageName];
    NSURL *imageUrl = [NSURL fileURLWithPath:filePath];
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard declareTypes:@[NSFilenamesPboardType] owner:nil];
    [pasteboard writeObjects:@[imageUrl]];
    
    [self.window close];
}

- (void)setup {
    self.images = [NSMutableArray arrayWithCapacity:0];
    self.imageNames = [NSMutableArray arrayWithCapacity:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *strpath1 = @"/Users/kenhan/Dropbox/gifs";
    NSArray *dirs = [fm contentsOfDirectoryAtPath:strpath1 error:nil];

    NSString *dir;

    for (dir in dirs)
    {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", strpath1, dir];
        NSImage *image = [self getImage:filePath];
        if (image) {
            [self.images addObject:image];
            [self.imageNames addObject:dir];
        }
    }

}

- (NSImage *)getImage:(NSString *)path {
    NSArray *imageReps = [NSBitmapImageRep imageRepsWithContentsOfFile:path];
    NSInteger width = 0;
    NSInteger height = 0;
    for (NSImageRep * imageRep in imageReps) {
        if ([imageRep pixelsWide] > width) width = [imageRep pixelsWide];
        if ([imageRep pixelsHigh] > height) height = [imageRep pixelsHigh];
    }
    NSImage *imageNSImage = [[NSImage alloc] initWithSize:NSMakeSize((CGFloat)width, (CGFloat)height)];
    [imageNSImage addRepresentations:imageReps];
    return imageNSImage;
}


@end




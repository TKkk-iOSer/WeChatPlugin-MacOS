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

@property (nonatomic, strong) NSArray *content;
@property (nonatomic, strong) NSCollectionView *collectionView;
@property (nonatomic, strong) NSScrollView *collectionContentView;
@property (nonatomic, strong) NSScrollView *scrollView;

@end


@implementation TKEmojiWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    [self addCollection];
}


- (void)dataSource {
    NSImage *computerimage = [NSImage imageNamed:NSImageNameComputer];
    NSImage *folderimage = [NSImage imageNamed:NSImageNameFolder];
    NSImage *homeimage = [NSImage imageNamed:NSImageNameHomeTemplate];
    NSImage *listimage = [NSImage imageNamed:NSImageNameListViewTemplate];
    NSImage *networkimage = [NSImage imageNamed:NSImageNameNetwork];
    NSImage *shareimage = [NSImage imageNamed:NSImageNameShareTemplate];
    
    NSDictionary *item1 =@{
//                           @"title":@"computer",
                           @"image":computerimage
                           };
    
    NSDictionary *item2 =@{
//                           @"title":@"folder",
                           @"image":folderimage};
    
    NSDictionary *item3 =@{
//                           @"title":@"home",
                           @"image":homeimage
                           };
    
    NSDictionary *item4 =@{
//                           @"title":@"list",
                           @"image":listimage
                           };
    
    NSDictionary *item5 =@{
//                           @"title":@"network",
                           @"image":networkimage
                           };
    
    NSDictionary *item6 =@{
//                           @"title":@"share",
                           @"image":shareimage
                           };
    
    self.content = @[
                     item1,
                     item2,
                     item3,
                     item4,
                     item5,
                     item6,
                     item1,
                     item2,
                     item3,
                     item4,
                     item5,
                     item6,
                     item1,
                     item2,
                     item3,
                     item4,
                     item5,
                     item6,
                     item1,
                     item2,
                     item3,
                     item4,
                     item5,
                     item6
                     ];
    [self.collectionView reloadData];
}


#pragma mark -- addCollection
- (void)addCollection {
    // 创建scrollview
    NSCollectionViewFlowLayout *layout = [[NSCollectionViewFlowLayout alloc]init];
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    layout.itemSize = NSMakeSize(110, 110);
    layout.scrollDirection = NSCollectionViewScrollDirectionVertical;
    layout.sectionInset = NSEdgeInsetsMake(0, 0, 0, 0);
    
    //    self.collectionView = [[NSCollectionView alloc]initWithFrame:NSMakeRect(0, 0, 500, 500)];

    self.scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    self.collectionView = [[NSCollectionView alloc]initWithFrame:[self.window.contentView bounds]];
    
    
    
//    self.collectionView = [[NSCollectionView alloc]initWithFrame:[self.window.contentView bounds]];
    
    self.collectionView.collectionViewLayout = layout;
    
    [self.collectionView registerClass:[TKEmojiCollectionViewItem class] forItemWithIdentifier:@"Slide"];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.collectionView setSelectable:YES];
    
    //    self.collectionContentView = [[NSScrollView alloc]initWithFrame:NSMakeRect(0, 0, 300, 300)];
    
#pragma mark -- NSScrollView
    self.collectionContentView = [[NSScrollView alloc]initWithFrame:[self.window.contentView bounds]];
#pragma mark -- 给NSScrollView添加自动布局
    
    
    // 给collectionview添加背景颜色
    //    [self.collectionView setWantsLayer:YES];
    self.collectionView.layer.backgroundColor = [NSColor greenColor].CGColor;
    
    [self.collectionContentView setDocumentView:self.collectionView];
    self.scrollView.documentView = self.collectionView;
    [self.window.contentView addSubview:self.scrollView];
    [self.window.contentView addSubview: self.collectionContentView];
    
    
    
    
    self.collectionContentView.translatesAutoresizingMaskIntoConstraints = NO;
    
//    [self.collectionContentView.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor].active = YES;
//    [self.collectionContentView.bottomAnchor constraintEqualToAnchor:self.window.contentView.bottomAnchor].active = YES;
//    
//    [self.collectionContentView.leadingAnchor constraintEqualToAnchor:self.window.contentView.leadingAnchor].active = YES;
//    
//    [self.collectionContentView.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor].active = YES;
//    
    [self dataSource];
}

#pragma mark -- collectionView delegate
- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView  {
    return 1;
}


- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (self.content.count == 0) {
        return 0;
    }
    return self.content.count;
}


//-(NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
//    return NSMakeSize(50, 50);
//}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    TKEmojiCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"Slide" forIndexPath:indexPath];
    item.representedObject = self.content[indexPath.item];
#pragma mark -- item 添加背景颜色
    //     [item.view setWantsLayer:YES];
    //    [item.view.layer setBackgroundColor:[NSColor redColor].CGColor];
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    NSLog(@"----%lu", (unsigned long)collectionView.selectionIndexes.firstIndex);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag{
    [self.window makeKeyAndOrderFront:self];
    return YES;
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return YES;
}
//////////////////////////////

//
//- (void)initSubviews {
////    self.window.backgroundColor = [NSColor whiteColor];
//
//    self.imageBrowser = ({
//        IKImageBrowserView *imageBrowser = [[IKImageBrowserView alloc] init];
//        imageBrowser.frame = NSMakeRect(0, 0, 630, 450);
//
//        imageBrowser;
//    });
//
//    [self.imageBrowser setAllowsReordering:YES];
//    [self.imageBrowser setAnimates:YES];
//    [self.imageBrowser setDraggingDestinationDelegate:self];
//    [self.window.contentView addSubviews:@[self.imageBrowser]];
//
//}

//- (void)setup {
//    NSFileManager *fm = [NSFileManager defaultManager];
//    NSString *strpath1 = [NSString stringWithFormat:@"%@/gifs",NSHomeDirectory()];
//    NSArray *dirs = [fm contentsOfDirectoryAtPath:strpath1 error:nil];
//
//    NSString *dir;
//
//    for (dir in dirs)
//    {
//
////
////        NSImageView *imgView = [[NSImageView alloc]initWithFrame:NSMakeRect(100, 100, 100, 100)];
////        imgView.imageFrameStyle = NSImageFramePhoto; //图片边框的样式
////        imgView.wantsLayer = YES;
////        imgView.layer.backgroundColor = [NSColor cyanColor].CGColor;
////        imgView.imageScaling = NSImageScaleNone;
////
////        [imgView setAnimates:YES];
////
////        imgView.imageAlignment = NSImageAlignTopRight; //图片内容对于控件的位置
////
////        [imgView setEditable:YES]; //用户能否直接将图片拖到一个NSImageView类里,666
////
////        [imgView setAllowsCutCopyPaste:YES];//表示用户能否对图片内容进行剪切、复制、粘贴行操作
////
////        file:///Users/kenhan/Downloads/airport.jpg
//        NSString *filePath = [NSString stringWithFormat:@"%@/%@", strpath1, dir ];
////        NSImage *img1 = [self getImage:filePath];
////        imgView.imageScaling = NSImageScaleNone;
////        imgView.animates = YES;
////        imgView.image = img1;
////
////        imgView.canDrawSubviewsIntoLayer = YES;
////
////        [self.window.contentView addSubview:imgView];
//
//        NSURL *url = [NSURL URLWithString:filePath];
//        [self addImagesWithPathURL:url];
//    }
//
//}

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




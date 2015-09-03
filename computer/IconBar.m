//
//  IconBar.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "IconBar.h"
#import "Canvas.h"
#import "PhotoDrawable.h"
#import "EditorViewController.h"
#import "TextDrawable.h"
#import "InsertItemViewController.h"

@interface IconBarModel : NSObject

@property (nonatomic) UIImage *image;
@property (nonatomic,copy) void(^action)();

@end

@implementation IconBarModel

@end



@interface IconBar () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSArray *models;

@end

@implementation IconBar

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (!self.collectionView) {
        UICollectionViewFlowLayout *flow = [UICollectionViewFlowLayout new];
        flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flow.minimumInteritemSpacing = 0;
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flow];
        self.collectionView.backgroundColor = nil;
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        [self addSubview:self.collectionView];
        
        __weak IconBar *weakSelf = self;
        IconBarModel *undo = [IconBarModel new];
        undo.image = [UIImage imageNamed:@"Undo"];
        IconBarModel *addText = [IconBarModel new];
        addText.image = [UIImage imageNamed:@"Text"];
        addText.action = ^{
            TextDrawable *d = [TextDrawable new];
            d.bounds = CGRectMake(0, 0, 250, 250);
            [weakSelf.editor.canvas insertDrawable:d];
        };
        IconBarModel *addImage = [IconBarModel new];
        addImage.image = [UIImage imageNamed:@"Pictures"];
        addImage.action = ^{
            PhotoDrawable *d = [PhotoDrawable new];
            d.bounds = CGRectMake(0, 0, 250, 250);
            [weakSelf.editor.canvas insertDrawable:d];
        };
        IconBarModel *scroll = [IconBarModel new];
        scroll.image = [UIImage imageNamed:@"Scroll"];
        IconBarModel *done = [IconBarModel new];
        done.image = [UIImage imageNamed:@"Grid"];
        IconBarModel *add = [IconBarModel new];
        add.image = [UIImage imageNamed:@"Add"];
        add.action = ^{
            InsertItemViewController *inserter = [InsertItemViewController new];
            inserter.editorVC = weakSelf.editor;
            [inserter present];
        };
        IconBarModel *options = [IconBarModel new];
        options.image = [UIImage imageNamed:@"Controls"];
        IconBarModel *share = [IconBarModel new];
        share.image = [UIImage imageNamed:@"Share"];
        // IconBarModel *divider = [IconBarModel new];
        self.models = @[done, share, scroll, options, add];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UICollectionViewFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake(self.bounds.size.height, self.bounds.size.height);
    self.collectionView.frame = self.bounds;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    UIImageView *imageView = (id)cell.backgroundView;
    if (![imageView isKindOfClass:[UIImageView class]]) {
        imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeCenter;
        cell.backgroundView = imageView;
    }
    IconBarModel *model = self.models[indexPath.item];
    imageView.image = model.image;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    IconBarModel *model = self.models[indexPath.item];
    if (model.action) model.action();
}

@end

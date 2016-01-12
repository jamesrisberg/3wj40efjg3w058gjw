//
//  IconBar.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "IconBar.h"
#import "CanvasEditor.h"
#import "EditorViewController.h"
#import "InsertItemViewController.h"
#import "ConvenienceCategories.h"

@interface IconBarModel : NSObject

@property (nonatomic) UIImage *image;
@property (nonatomic,copy) void(^action)();
@property (nonatomic) BOOL disableWhenNoSelection;
@property (nonatomic) UIColor *color;

@end

@implementation IconBarModel

@end



@interface IconBar () <UICollectionViewDataSource, UICollectionViewDelegate> {
}

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
        
        [self updateIconModels];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UICollectionViewFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    layout.itemSize = CGSizeMake(MAX(self.bounds.size.height, self.bounds.size.width / self.models.count), self.bounds.size.height);
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
    imageView.image = [model.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    imageView.tintColor = model.color ? : [UIColor whiteColor];
    imageView.alpha = 1;
    if (model.disableWhenNoSelection && !self.hasSelection) {
        imageView.alpha = 0.5;
    }
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    IconBarModel *model = self.models[indexPath.item];
    return !(model.disableWhenNoSelection && !self.hasSelection);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    IconBarModel *model = self.models[indexPath.item];
    if (model.action) model.action();
}

- (void)updateIconModels {
    NSMutableArray *items = [NSMutableArray new];
    __weak IconBar *weakSelf = self;
    
    UIColor *specialColor = [UIColor colorWithRed:0.0 green:0.868658483028 blue:0.761248767376 alpha:1.0];
    
    IconBarModel *done = [IconBarModel new];
    done.color = specialColor;
    done.image = [UIImage imageNamed:@"BackDown"];
    done.action = ^{
        weakSelf.onDoneButtonPressed();
    };
    [items addObject:done];
    if (!self.isModalEditing) {
        IconBarModel *share = [IconBarModel new];
        share.image = [UIImage imageNamed:@"Share"];
        share.action = ^{
            [weakSelf.editor beginExportFlow];
        };
        [items addObject:share];
    }
    
    /*IconBarModel *undo = [IconBarModel new];
    undo.image = [UIImage imageNamed:@"Undo"];*/
    
    IconBarModel *time = [IconBarModel new];
    time.image = [UIImage imageNamed:@"Time"];
    time.action = ^{
        weakSelf.editor.mode = EditorModeTimeline;
    };
    [items addObject:time];
    
    IconBarModel *scroll = [IconBarModel new];
    scroll.image = [UIImage imageNamed:@"Scroll"];
    scroll.action = ^{
        weakSelf.editor.mode = EditorModeScroll;
    };
    [items addObject:scroll];
    
    IconBarModel *add = [IconBarModel new];
    add.image = [UIImage imageNamed:@"Add"];
    add.action = ^{
        InsertItemViewController *inserter = [InsertItemViewController new];
        inserter.editorVC = weakSelf.editor;
        [weakSelf.editor presentViewController:inserter animated:YES completion:nil];
    };
    add.color = specialColor;
    [items addObject:add];
    
    IconBarModel *props = [IconBarModel new];
    props.image = [UIImage imageNamed:@"Controls"];
    props.action = ^{
        [weakSelf.editor showPropertyEditors];
    };
    props.disableWhenNoSelection = YES;
    [items addObject:props];
    
    IconBarModel *delete = [IconBarModel new];
    delete.image = [UIImage imageNamed:@"Delete"];
    delete.action = ^{
        [weakSelf.editor.canvas deleteSelection];
    };
    delete.disableWhenNoSelection = YES;
    [items addObject:delete];
    
    self.models = items;
}

- (void)setModels:(NSArray *)models {
    _models = models;
    [self.collectionView reloadData];
}

- (void)setIsModalEditing:(BOOL)isModalEditing {
    _isModalEditing = isModalEditing;
    [self updateIconModels];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UICollectionViewFlowLayout *flow = (id)self.collectionView.collectionViewLayout;
    CGFloat maxDx = flow.itemSize.width / 2 + 30;
    
    CGFloat bestDx = MAXFLOAT;
    UIView *bestHit = nil;
    for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
        CGFloat dx = fabs([cell convertPoint:CGPointMake(cell.bounds.size.width/2, 0) toView:self].x - point.x);
        if (dx < bestDx) {
            bestDx = dx;
            bestHit = cell;
        }
    }
    
    if (bestDx <= maxDx) {
        return bestHit;
    } else {
        return self;
    }
}

- (void)setHasSelection:(BOOL)hasSelection {
    _hasSelection = hasSelection;
    NSArray *indexPathsToReload = [self.collectionView.indexPathsForVisibleItems map:^id(id obj) {
        NSIndexPath *path = obj;
        IconBarModel *model = self.models[path.item];
        return model.disableWhenNoSelection ? path : nil;
    }];
    [self.collectionView reloadItemsAtIndexPaths:indexPathsToReload];
}

@end

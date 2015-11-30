//
//  IconBar.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "IconBar.h"
#import "CanvasEditor.h"
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
        
        [self updateIconModels];
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

- (void)updateIconModels {
    __weak IconBar *weakSelf = self;
    IconBarModel *undo = [IconBarModel new];
    undo.image = [UIImage imageNamed:@"Undo"];
    IconBarModel *addText = [IconBarModel new];
    addText.image = [UIImage imageNamed:@"Text"];
    addText.action = ^{
        TextDrawable *d = [TextDrawable new];
        d.bounds = CGRectMake(0, 0, 250, 250);
        // [weakSelf.editor.canvas insertDrawable:d];
    };
    IconBarModel *time = [IconBarModel new];
    time.image = [UIImage imageNamed:@"Time"];
    time.action = ^{
        weakSelf.editor.mode = EditorModeTimeline;
    };
    IconBarModel *scroll = [IconBarModel new];
    scroll.image = [UIImage imageNamed:@"Scroll"];
    scroll.action = ^{
        weakSelf.editor.mode = EditorModeScroll;
    };
    
    NSArray *leftItems = nil;
    if (self.isModalEditing) {
        IconBarModel *done = [IconBarModel new];
        done.image = [UIImage imageNamed:@"BackDown"];
        done.action = ^{
            weakSelf.onDoneButtonPressed();
        };
        
        leftItems = @[done];
    } else {
        IconBarModel *done = [IconBarModel new];
        done.image = [UIImage imageNamed:@"Grid"];
        done.action = ^{
            weakSelf.onDoneButtonPressed();
        };
        
        IconBarModel *share = [IconBarModel new];
        share.image = [UIImage imageNamed:@"Share"];
        share.action = ^{
            [weakSelf.editor beginExportFlow];
        };
        leftItems = @[done, share];
    }
    
    IconBarModel *add = [IconBarModel new];
    add.image = [UIImage imageNamed:@"Add"];
    add.action = ^{
        InsertItemViewController *inserter = [InsertItemViewController new];
        inserter.editorVC = weakSelf.editor;
        [weakSelf.editor presentViewController:inserter animated:YES completion:nil];
    };
    /*IconBarModel *options = [IconBarModel new];
    options.image = [UIImage imageNamed:@"Controls"];
    options.action = ^{
        [weakSelf.editor showOptions];
    };*/
    
    IconBarModel *enterSelectionMode = [IconBarModel new];
    enterSelectionMode.image = [UIImage imageNamed:@"Grid"]; // TODO: find an icon
    enterSelectionMode.action = ^{
        [weakSelf.editor enterSelectionMode];
    };
    
    // IconBarModel *divider = [IconBarModel new];
    NSArray *rightItems = @[scroll, time, enterSelectionMode, add];
    self.models = [leftItems arrayByAddingObjectsFromArray:rightItems];
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

@end

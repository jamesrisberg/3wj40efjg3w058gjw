//
//  DrawablePickerCollectionViewController.m
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "DrawablePickerCollectionViewController.h"
#import "ConvenienceCategories.h"

@interface _DrawablePickerCollectionViewCell : UICollectionViewCell

@property (nonatomic) UIView *snapshot;

@end

@implementation _DrawablePickerCollectionViewCell

- (void)setSnapshot:(UIView *)snapshot {
    [_snapshot removeFromSuperview];
    _snapshot = snapshot;
    [self addSubview:snapshot];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat scale = MIN(self.bounds.size.width / self.snapshot.bounds.size.width, self.bounds.size.height / self.snapshot.bounds.size.height) * 0.8;
    self.snapshot.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.snapshot.transform = CGAffineTransformMakeScale(scale, scale);
}

@end



@interface DrawablePickerCollectionViewController () {
    void (^_callback)(CMDrawable *drawableOrNil);
}

@property (nonatomic) NSArray<CMDrawable*> *drawables;
@property (nonatomic) NSArray<UIView*> *snapshots;

@end

@implementation DrawablePickerCollectionViewController

- (instancetype)initWithDrawables:(NSArray<CMDrawable*>*)drawables snapshotViews:(NSArray<UIView*>*)snapshots callback:(void(^)(CMDrawable *drawableOrNil))callback {
    self = [self initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
    self.drawables = drawables;
    self.snapshots = snapshots;
    _callback = callback;
    [self.collectionView registerClass:[_DrawablePickerCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.drawables.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _DrawablePickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    if (indexPath.item == 0) {
        UILabel *none = [UILabel new];
        none.text = NSLocalizedString(@"None", @"").uppercaseString;
        none.font = [UIFont boldSystemFontOfSize:40];
        none.alpha = 0.7;
        none.textAlignment = NSTextAlignmentCenter;
        [none sizeToFit];
        cell.snapshot = none;
    } else {
        cell.snapshot = self.snapshots[indexPath.item-1];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    CMDrawable *drawable = nil;
    if (indexPath.item > 0) {
        drawable = self.drawables[indexPath.item-1];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    _callback(drawable);
}

@end

//
//  PropertiesModal.m
//  computer
//
//  Created by Nate Parrott on 11/11/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "PropertiesModal.h"
#import "OptionsCollectionViewCell.h"
#import "InlineViewControllerCollectionViewCell.h"

#define RAND_FLOAT ((rand() % 10000) / 10000.0)


@interface _PropertiesModalSection : NSObject

@property (nonatomic) NSArray *models;
@property (nonatomic) NSString *sectionId;
@property (nonatomic) Class cellClass;
@property (nonatomic,copy) void (^onConfigure)(id model, id cell);
@property (nonatomic,copy) CGSize (^sizeBlock)(id model);
@property (nonatomic,copy) void (^onSelect)(id model);

@end

@implementation _PropertiesModalSection

@end




@interface PropertiesModal () <UICollectionViewDataSource, UICollectionViewDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSArray<__kindof _PropertiesModalSection*> *sections;

@end

@implementation PropertiesModal

#pragma mark Lifecycle

- (instancetype)init {
    self = [super init];
    self.transitioningDelegate = self;
    self.modalPresentationStyle = UIModalPresentationCustom;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *flow = [UICollectionViewFlowLayout new];
    flow.itemSize = CGSizeMake(90, 44);
    CGFloat margin = 20;
    flow.minimumInteritemSpacing = margin;
    flow.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flow];
    [self.view addSubview:self.collectionView];
    [self.collectionView registerClass:[InlineViewControllerCollectionViewCell class] forCellWithReuseIdentifier:@"InlineVC"];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Action"];
    [self.collectionView registerClass:[OptionsCollectionViewCell class] forCellWithReuseIdentifier:@"Option"];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    UIView *bgView = [UIView new];
    bgView.backgroundColor = [UIColor clearColor];
    self.collectionView.backgroundView = bgView;
    [bgView addGestureRecognizer:tapRec];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadSections];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Models

- (void)reloadSections {
    __weak PropertiesModal *weakSelf = self;
    NSMutableArray *sections = [NSMutableArray new];
    
    if (self.inlineViewController) {
        _PropertiesModalSection *inlineVC = [_PropertiesModalSection new];
        inlineVC.cellClass = [InlineViewControllerCollectionViewCell class];
        inlineVC.models = @[self.inlineViewController];
        inlineVC.sectionId = @"InlineVC";
        inlineVC.onConfigure = ^(id model, id cell) {
            [cell setViewController:model parentViewController:weakSelf];
        };
        inlineVC.sizeBlock = ^CGSize(id model) {
            return CGSizeMake([weakSelf maxCellWidth], 120);
        };
        [sections addObject:inlineVC];
    }
    
    if (self.items.count || self.mainAction) {
        _PropertiesModalSection *items = [_PropertiesModalSection new];
        items.sectionId = @"Actions";
        items.cellClass = [UICollectionViewCell class];
        items.models = self.items ? : [NSArray new];
        if (self.mainAction) {
            items.models = [@[self.mainAction] arrayByAddingObjectsFromArray:items.models];
        }
        items.sizeBlock = ^CGSize(id model) {
            if (model == weakSelf.mainAction) {
                return CGSizeMake([weakSelf maxCellWidth], 44);
            } else {
                return [weakSelf itemSize];
            }
        };
        items.onConfigure = ^(id theModel, id theCell) {
            QuickCollectionItem *model = theModel;
            UICollectionViewCell *cell = theCell;
            if (model.icon) {
                UIImageView *imageView = [[UIImageView alloc] initWithImage:model.icon];
                imageView.contentMode = UIViewContentModeCenter;
                cell.backgroundView = imageView;
            } else if (model.label) {
                UILabel *label = [UILabel new];
                label.font = [UIFont boldSystemFontOfSize:12];
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = [UIColor whiteColor];
                label.text = model.label;
                cell.backgroundView = label;
            }
            cell.backgroundView.backgroundColor = model.color;
            cell.backgroundView.layer.cornerRadius = 5;
            cell.backgroundView.clipsToBounds = YES;
        };
        items.onSelect = ^(id theModel) {
            [weakSelf dismiss];
            QuickCollectionItem *model = theModel;
            if (model.action) model.action();
        };
        [sections addObject:items];
    }
    
    if (self.optionsCellModels.count) {
        _PropertiesModalSection *options = [_PropertiesModalSection new];
        options.sectionId = @"Options";
        options.cellClass = [OptionsCollectionViewCell class];
        options.models = self.optionsCellModels;
        options.onConfigure = ^(id theModel, id theCell) {
            OptionsViewCellModel *model = theModel;
            OptionsCollectionViewCell *cell = theCell;
            
            OptionsCell *optionCell = [model.cellClass new];
            
            if (model.onCreate) model.onCreate(optionCell);
            
            cell.title = model.title;
            cell.cell = optionCell;
        };
        options.sizeBlock = ^CGSize(id model) {
            return CGSizeMake([weakSelf maxCellWidth], 64);
        };
        [sections addObject:options];
    }
    
    self.sections = sections;
}

- (void)setSections:(NSArray *)sections {
    _sections = sections;
    for (_PropertiesModalSection *section in sections) {
        [self.collectionView registerClass:[section cellClass] forCellWithReuseIdentifier:[section sectionId]];
    }
    [self.collectionView reloadData];
}

- (void)setItems:(NSArray<__kindof QuickCollectionItem *> *)items {
    _items = items;
    CGFloat hue = 0;
    for (QuickCollectionItem *model in self.items) {
        model.color = [UIColor colorWithHue:fmod(hue, 1) saturation:0.8 brightness:0.8 alpha:1];
        hue += 0.3;
    }
}

- (void)setOptionsCellModels:(NSArray *)optionsCellModels {
    _optionsCellModels = optionsCellModels;
}

#pragma mark CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.sections[section].models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _PropertiesModalSection *section = self.sections[indexPath.section];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:section.sectionId forIndexPath:indexPath];
    if (section.onConfigure) {
        section.onConfigure(section.models[indexPath.item], cell);
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _PropertiesModalSection *section = self.sections[indexPath.section];
    if (section.onSelect) {
        section.onSelect(section.models[indexPath.item]);
    }
}

#pragma mark Layout

- (CGFloat)maxCellWidth {
    UICollectionViewFlowLayout *flow = (id)self.collectionView.collectionViewLayout;
    CGFloat maxWidth = self.collectionView.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right - flow.sectionInset.left - flow.sectionInset.right;
    return maxWidth;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
    UICollectionViewFlowLayout *flow = (id)self.collectionView.collectionViewLayout;
    CGFloat margin = 20;
    CGFloat itemSize = flow.itemSize.width;
    // width = itemSize * cellsWide + (cellsWide + 1) * margin
    CGFloat width = self.collectionView.bounds.size.width;
    CGFloat cellsWide = floor((-width + margin)/(-itemSize - margin));
    margin = (-width + itemSize*cellsWide)/(-cellsWide - 1);
    margin = floor(margin-0.5);
    flow.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
    flow.minimumInteritemSpacing = margin;
    flow.minimumLineSpacing = margin;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    _PropertiesModalSection *section = self.sections[indexPath.section];
    if (section.sizeBlock) {
        return section.sizeBlock(section.models[indexPath.item]);
    }
    return [self itemSize];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark Transitioning

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.4;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.interactivePresentation;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    BOOL isPresenting = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey] == self;
    UIView *container = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    if (isPresenting) {
        [container addSubview:self.view];
        self.view.frame = [transitionContext finalFrameForViewController:self];
        self.view.backgroundColor = [UIColor clearColor];
        [self makeIconsFlyIn:YES withDuration:duration];
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        } completion:^(BOOL finished) {
            
        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration/2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [transitionContext completeTransition:YES];
        });
    } else {
        [self makeIconsFlyIn:NO withDuration:duration];
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.view.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [self.view removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}

- (void)makeIconsFlyIn:(BOOL)flyIn withDuration:(NSTimeInterval)duration {
    [self.view layoutIfNeeded];
    NSArray *cells = self.collectionView.visibleCells;
    CGFloat flight = 0.3;
    for (UICollectionViewCell *cell in cells.reverseObjectEnumerator) {
        if (flyIn) {
            cell.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height * flight);
            cell.alpha = 0;
        }
        CGFloat maxDelay = duration * 0.3;
        NSTimeInterval delay = maxDelay * RAND_FLOAT;
        CGFloat initialVelocity = flyIn ? 0.1 : 0;
        [UIView animateWithDuration:duration - maxDelay delay:delay usingSpringWithDamping:0.8 initialSpringVelocity:initialVelocity options:UIViewAnimationOptionAllowUserInteraction animations:^{
            if (flyIn) {
                cell.transform = CGAffineTransformIdentity;
            } else {
                cell.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height * flight);
            }
            cell.alpha = flyIn ? 1 : 0;
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (CGSize)itemSize {
    [self view];
    return [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout itemSize];
}

- (void)setItemSize:(CGSize)itemSize {
    [self view];
    [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout setItemSize:itemSize];
}

@end

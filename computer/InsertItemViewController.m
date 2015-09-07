//
//  InsertItemViewController.m
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "InsertItemViewController.h"
#import "EditorViewController.h"
#import "PhotoDrawable.h"
#import "Canvas.h"
#import "TextDrawable.h"
#import "ShapeDrawable.h"
#import "SKColorFill.h"

#define RAND_FLOAT ((rand() % 10000) / 10000.0)

@interface InsertableItem : NSObject

@property (nonatomic) UIImage *icon;
@property (nonatomic,copy) void (^action)();
@property (nonatomic) UIColor *color;

@end

@implementation InsertableItem

@end


@interface InsertItemViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate>

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSArray *models;

@end

@implementation InsertItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *flow = [UICollectionViewFlowLayout new];
    flow.itemSize = CGSizeMake(70, 70);
    CGFloat margin = 20;
    flow.minimumInteritemSpacing = margin;
    flow.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flow];
    [self.view addSubview:self.collectionView];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    __weak InsertItemViewController *weakSelf = self;
    PhotoDrawable* (^addPhoto)() = ^{
        PhotoDrawable *d = [PhotoDrawable new];
        d.bounds = CGRectMake(0, 0, 250, 250);
        [weakSelf.editorVC.canvas insertDrawable:d];
        return d;
    };
    
    InsertableItem *camera = [InsertableItem new];
    camera.icon = [UIImage imageNamed:@"Camera"];
    camera.action = ^{
        PhotoDrawable *d = addPhoto();
        [d promptToPickPhotoWithSource:UIImagePickerControllerSourceTypeCamera];
    };
    InsertableItem *photos = [InsertableItem new];
    photos.icon = [UIImage imageNamed:@"Pictures"];
    photos.action = ^{
        PhotoDrawable *d = addPhoto();
        [d promptToPickPhotoWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
    };
    InsertableItem *video = [InsertableItem new];
    video.icon = [UIImage imageNamed:@"Video"];
    InsertableItem *text = [InsertableItem new];
    text.icon = [UIImage imageNamed:@"Text"];
    text.action = ^{
        TextDrawable *d = [TextDrawable new];
        d.bounds = CGRectMake(0, 0, 250, 250);
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    InsertableItem *pen = [InsertableItem new];
    pen.icon = [UIImage imageNamed:@"Pen"];
    InsertableItem *circle = [InsertableItem new];
    circle.icon = [UIImage imageNamed:@"Circle"];
    circle.action = ^{
        ShapeDrawable *d = [ShapeDrawable new];
        d.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 200, 200)];
        d.fill = [[SKColorFill alloc] initWithColor:[UIColor greenColor]];
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    
    InsertableItem *square = [InsertableItem new];
    square.icon = [UIImage imageNamed:@"Square"];
    square.action = ^{
        ShapeDrawable *d = [ShapeDrawable new];
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    
    self.models = @[camera, photos, video, text, pen, circle, square];
    CGFloat hue = 0;
    for (InsertableItem *model in self.models) {
        model.color = [UIColor colorWithHue:fmod(hue, 1) saturation:0.8 brightness:0.8 alpha:1];
        hue += 0.3;
    }
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    UIView *bgView = [UIView new];
    bgView.backgroundColor = [UIColor clearColor];
    self.collectionView.backgroundView = bgView;
    [bgView addGestureRecognizer:tapRec];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    InsertableItem *model = self.models[indexPath.item];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:model.icon];
    imageView.clipsToBounds = YES;
    imageView.backgroundColor = model.color;
    imageView.contentMode = UIViewContentModeCenter;
    imageView.layer.cornerRadius = 5;
    cell.backgroundView = imageView;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    InsertableItem *model = self.models[indexPath.item];
    [self dismissViewControllerAnimated:YES completion:nil];
    if (model.action) model.action();
}

- (void)present {
    self.transitioningDelegate = self;
    self.modalPresentationStyle = UIModalPresentationCustom;
    [self.editorVC showViewController:self sender:nil];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    for (UICollectionViewCell *cell in cells) {
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

@end

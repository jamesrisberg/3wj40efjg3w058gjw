//
//  StaticAnimationPicker.m
//  computer
//
//  Created by Nate Parrott on 10/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "StaticAnimationPicker.h"
#import "StaticAnimation.h"
#import "Drawable.h"
#import "ShapeDrawable.h"
#import "SKColorFill.h"
#import "VideoConstants.h"
#import "computer-Swift.h"
#import "CanvasViewerLite.h"
#import "CMShapeDrawable.h"
#import "CMCanvas.h"

@interface StaticAnimationPreview : UICollectionViewCell

@property (nonatomic) NSDictionary *animationDict;
@property (nonatomic) BOOL displayAsSelected;
@property (nonatomic) CanvasViewerLite *preview;
@property (nonatomic) CMShapeDrawable *shape;

@end

@implementation StaticAnimationPreview

- (void)setAnimationDict:(NSDictionary *)animationDict {
    _animationDict = animationDict;
    if (!self.preview) {
        // do some setup:
        self.shape = [CMShapeDrawable new];
        self.shape.boundsDiagonal = 30;
        UIBezierPath *p = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 10, 10)];
        self.shape.path = p;
        self.shape.pattern = [Pattern solidColor:[UIColor redColor]];
        
        self.backgroundColor = [UIColor whiteColor];
        self.preview = [[CanvasViewerLite alloc] initWithFrame:self.bounds];
        [self.preview.canvas.contents addObject:self.shape];
        [self.contentView addSubview:self.preview];
        
        self.layer.borderWidth = 3;
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.cornerRadius = 5;
    }
    StaticAnimation *anim = [StaticAnimation new];
    [anim addAnimationDict:animationDict];
    
    CMShapeDrawableKeyframe *kf = [self.shape.keyframeStore createKeyframeAtTimeIfNeeded:[[FrameTime alloc] initWithFrame:0 atFPS:1]];
    kf.rotation = M_PI/4;
    kf.staticAnimation = anim;
    [self.shape.keyframeStore storeKeyframe:kf];
}

- (void)setDisplayAsSelected:(BOOL)displayAsSelected {
    _displayAsSelected = displayAsSelected;
    self.layer.borderColor = (displayAsSelected ? self.tintColor : [UIColor clearColor]).CGColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.preview.frame = self.bounds;
    CMShapeDrawableKeyframe *kf = [self.shape.keyframeStore interpolatedKeyframeAtTime:[[FrameTime alloc] initWithFrame:0 atFPS:1]];
    kf.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    [self.shape.keyframeStore storeKeyframe:kf];
}

@end



@interface StaticAnimationPicker () <UICollectionViewDataSource, UICollectionViewDelegate> {
    BOOL _setupYet;
    NSArray<__kindof NSArray<__kindof NSDictionary*>*> *_sections;
}

@property (nonatomic) UICollectionView *collectionView;

@end

@implementation StaticAnimationPicker

- (void)setup {
    NSDictionary *slowBlink = @{@"blinkRate": @(VC_FASTEST_STATIC_BLINK / 3.0), @"blinkMagnitude": @1};
    NSDictionary *mediumBlink = @{@"blinkRate": @(VC_FASTEST_STATIC_BLINK / 2.0), @"blinkMagnitude": @1};
    NSDictionary *fastBlink = @{@"blinkRate": @(VC_FASTEST_STATIC_BLINK), @"blinkMagnitude": @1};
    NSArray *blinkSection = @[slowBlink, mediumBlink, fastBlink];
    
    NSDictionary *slowJitter = @{@"jitterXMagnitude": @10, @"jitterYMagnitude": @10, @"jitterRate": @5};
    NSDictionary *fastJitter = @{@"jitterXMagnitude": @10, @"jitterYMagnitude": @10, @"jitterRate": @11};
    NSDictionary *slowXJitter = @{@"jitterXMagnitude": @10, @"jitterYMagnitude": @0, @"jitterRate": @5};
    NSDictionary *fastXJitter = @{@"jitterXMagnitude": @10, @"jitterYMagnitude": @0, @"jitterRate": @11};
    NSArray *jitterSection = @[slowJitter, fastJitter, slowXJitter, fastXJitter];
    
    NSDictionary *slowPulse = @{@"pulseMagnitude": @0.1, @"pulseRate": @0.3};
    NSDictionary *mediumPulse = @{@"pulseMagnitude": @0.2, @"pulseRate": @0.8};
    NSDictionary *strongPulse = @{@"pulseMagnitude": @0.5, @"pulseRate": @1.1};
    NSArray *pulseSection = @[slowPulse, mediumPulse, strongPulse];
    
    NSDictionary *slowRotate = @{@"rotationMagnitude": @1, @"rotationRate": @0.3};
    NSDictionary *mediumRotate = @{@"rotationMagnitude": @1, @"rotationRate": @0.7};
    NSDictionary *fastRotate = @{@"rotationMagnitude": @1, @"rotationRate": @1.5};
    NSArray *rotateSection = @[slowRotate, mediumRotate, fastRotate];
    
    _sections = @[blinkSection, jitterSection, pulseSection, rotateSection];
    
    UICollectionViewFlowLayout *flow = [UICollectionViewFlowLayout new];
    flow.itemSize = CGSizeMake(50, 50);
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flow];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    flow.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.collectionView registerClass:[StaticAnimationPreview class] forCellWithReuseIdentifier:@"Cell"];
    [self addSubview:self.collectionView];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    _setupYet = YES;
}

- (void)setAnimation:(StaticAnimation *)animation {
    _animation = animation;
    if (!_setupYet) [self setup];
}

#pragma mark Layout
- (void)layoutSubviews {
    [super layoutSubviews];
    self.collectionView.frame = self.bounds;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, [UIScreen mainScreen].bounds.size.height * 0.3);
}

#pragma mark CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_sections[section] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *section = _sections[indexPath.section];
    NSDictionary *animationDict = section[indexPath.item];
    
    StaticAnimationPreview *cell = (StaticAnimationPreview *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.animationDict = animationDict;
    cell.displayAsSelected = [self.animation matchesAnimationDict:animationDict];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *section = _sections[indexPath.section];
    NSDictionary *animationDict = section[indexPath.item];
    
    StaticAnimationPreview *cell = (StaticAnimationPreview *)[collectionView cellForItemAtIndexPath:indexPath];
    BOOL enable = !cell.displayAsSelected;
    StaticAnimation *newAnimationDict = self.animation.copy;
    if (enable) {
        [newAnimationDict addAnimationDict:animationDict];
    } else {
        [newAnimationDict removeAnimationDict:animationDict];
    }
    self.animation = newAnimationDict;
    [self updateAnimationCellSelections];
    self.animationDidChange();
}

- (void)updateAnimationCellSelections {
    for (StaticAnimationPreview *cell in [self.collectionView visibleCells]) {
        cell.displayAsSelected = [self.animation matchesAnimationDict:cell.animationDict];
    }
}

@end

//
//  StaticAnimationPicker.m
//  computer
//
//  Created by Nate Parrott on 10/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "StaticAnimationPicker.h"
#import "StaticAnimation.h"
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
@property (nonatomic,copy) void(^onTap)();

@end

@implementation StaticAnimationPreview

- (void)setAnimationDict:(NSDictionary *)animationDict {
    _animationDict = animationDict;
    if (!self.preview) {
        // do some setup:
        self.shape = [CMShapeDrawable new];
        self.shape.boundsDiagonal = 30;
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(5, 0)];
        [p addLineToPoint:CGPointMake(10, 5)];
        [p addLineToPoint:CGPointMake(5, 10)];
        [p addLineToPoint:CGPointMake(0, 5)];
        [p closePath];
        self.shape.path = p;
        self.shape.aspectRatio = 1;
        self.shape.pattern = [Pattern solidColor:[UIColor redColor]];
        
        self.backgroundColor = [UIColor whiteColor];
        self.preview = [[CanvasViewerLite alloc] initWithFrame:self.bounds];
        [self.preview.canvas.contents addObject:self.shape];
        [self.contentView addSubview:self.preview];
        
        self.layer.borderWidth = 3;
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.cornerRadius = 5;
        
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
    }
    StaticAnimation *anim = [StaticAnimation new];
    [anim addAnimationDict:animationDict];
    
    CMShapeDrawableKeyframe *kf = [self.shape.keyframeStore createKeyframeAtTimeIfNeeded:[[FrameTime alloc] initWithFrame:0 atFPS:1]];
    // kf.rotation = M_PI/4;
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

- (void)tapped:(UITapGestureRecognizer *)sender {
    self.onTap();
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
    NSDictionary *slowBlink = @{@"blinkRate": @(VC_LONGEST_STATIC_ANIMATION_PERIOD / 2), @"blinkMagnitude": @1}; // rate: 2/2 sec
    NSDictionary *mediumBlink = @{@"blinkRate": @(VC_LONGEST_STATIC_ANIMATION_PERIOD), @"blinkMagnitude": @1}; // rate: 2/4 sec
    NSDictionary *fastBlink = @{@"blinkRate": @(VC_LONGEST_STATIC_ANIMATION_PERIOD * 2), @"blinkMagnitude": @1}; // rate: 2/8 sec
    NSArray *blinkSection = @[slowBlink, mediumBlink, fastBlink];
    
    NSDictionary *slowJitter = @{@"jitterXMagnitude": @10, @"jitterYMagnitude": @10, @"jitterRate": @25};
    NSDictionary *fastJitter = @{@"jitterXMagnitude": @10, @"jitterYMagnitude": @10, @"jitterRate": @50};
    NSDictionary *slowXJitter = @{@"jitterXMagnitude": @10, @"jitterYMagnitude": @0, @"jitterRate": @25};
    NSDictionary *fastXJitter = @{@"jitterXMagnitude": @10, @"jitterYMagnitude": @0, @"jitterRate": @50};
    NSDictionary *verySlowJitter = @{@"jitterXMagnitude": @30, @"jitterYMagnitude": @15, @"jitterRate": @5};
    NSArray *jitterSection = @[slowJitter, fastJitter, slowXJitter, fastXJitter, verySlowJitter];
    
    NSDictionary *slowWobble = @{@"wobbleMagnitude": @0.15, @"wobbleRate": @0.5};
    NSDictionary *mediumWobble = @{@"wobbleMagnitude": @0.5, @"wobbleRate": @1};
    NSDictionary *fastWobble = @{@"wobbleMagnitude": @0.33, @"wobbleRate": @4};
    NSArray *wobbleSection = @[slowWobble, mediumWobble, fastWobble];
    
    NSDictionary *pulse1 = @{@"pulseMagnitude": @0.1, @"pulseRate": @(VC_LONGEST_STATIC_ANIMATION_PERIOD / 4)};
    NSDictionary *pulse2 = @{@"pulseMagnitude": @0.2, @"pulseRate": @(VC_LONGEST_STATIC_ANIMATION_PERIOD / 2)};
    NSDictionary *pulse3 = @{@"pulseMagnitude": @0.5, @"pulseRate": @((VC_LONGEST_STATIC_ANIMATION_PERIOD))};
    NSArray *pulseSection = @[pulse1, pulse2, pulse3];
    
    NSDictionary *slowRotate = @{@"rotationMagnitude": @1, @"rotationRate": @(1.0 / VC_LONGEST_STATIC_ANIMATION_PERIOD)};
    NSDictionary *mediumRotate = @{@"rotationMagnitude": @1, @"rotationRate": @(2.0 / VC_LONGEST_STATIC_ANIMATION_PERIOD)};
    NSDictionary *fastRotate = @{@"rotationMagnitude": @1, @"rotationRate": @(4.0 / VC_LONGEST_STATIC_ANIMATION_PERIOD)};
    NSArray *rotateSection = @[slowRotate, mediumRotate, fastRotate];
    
    _sections = @[blinkSection, jitterSection, pulseSection, rotateSection, wobbleSection];
    
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
    [self updateAnimationCellSelections];
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
    __weak StaticAnimationPicker *weakSelf = self;
    cell.onTap = ^{
        [weakSelf toggleAnimationDict:animationDict];
    };
    return cell;
}

- (void)toggleAnimationDict:(NSDictionary *)animationDict {
    StaticAnimation *newAnimation = self.animation.copy;
    BOOL wasEnabled = [self.animation matchesAnimationDict:animationDict];
    BOOL enable = !wasEnabled;
    if (enable) {
        [newAnimation addAnimationDict:animationDict];
    } else {
        [newAnimation removeAnimationDict:animationDict];
    }
    self.animation = newAnimation;
    self.animationDidChange();
}

- (void)updateAnimationCellSelections {
    for (StaticAnimationPreview *cell in [self.collectionView visibleCells]) {
        cell.displayAsSelected = [self.animation matchesAnimationDict:cell.animationDict];
    }
}

@end

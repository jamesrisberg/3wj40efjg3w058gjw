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

@interface StaticAnimationPreview : UICollectionViewCell

@property (nonatomic) NSDictionary *animationDict;
@property (nonatomic) BOOL displayAsSelected;
@property (nonatomic) ShapeDrawable *preview;

@end

@implementation StaticAnimationPreview

- (void)setAnimationDict:(NSDictionary *)animationDict {
    _animationDict = animationDict;
    if (!self.preview) {
        // do some setup:
        self.backgroundColor = [UIColor whiteColor];
        self.preview = [ShapeDrawable new];
        [self.preview setInternalSize:CGSizeMake(30, 30)];
        self.preview.rotation = M_PI / 4;
        self.preview.fill = [[SKColorFill alloc] initWithColor:[UIColor redColor]];
        [self addSubview:self.preview];
        
        self.layer.borderWidth = 3;
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.cornerRadius = 5;
    }
    StaticAnimation *anim = [StaticAnimation new];
    [anim addAnimationDict:animationDict];
    self.preview.staticAnimation = anim;
    [self.preview updatedKeyframeProperties];
}

- (void)setDisplayAsSelected:(BOOL)displayAsSelected {
    _displayAsSelected = displayAsSelected;
    self.layer.borderColor = (displayAsSelected ? self.tintColor : [UIColor clearColor]).CGColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.preview.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
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
    NSDictionary *slowBlink = @{@"blinkRate": @1, @"blinkMagnitude": @1};
    NSDictionary *mediumBlink = @{@"blinkRate": @4, @"blinkMagnitude": @1};
    NSDictionary *fastBlink = @{@"blinkRate": @10, @"blinkMagnitude": @1};
    NSArray *blinkSection = @[slowBlink, mediumBlink, fastBlink];
    _sections = @[blinkSection];
    
    UICollectionViewFlowLayout *flow = [UICollectionViewFlowLayout new];
    flow.itemSize = CGSizeMake(50, 50);
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flow];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.collectionView registerClass:[StaticAnimationPreview class] forCellWithReuseIdentifier:@"Cell"];
    [self addSubview:self.collectionView];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    _setupYet = YES;
}

- (void)setDrawable:(Drawable *)drawable {
    _drawable = drawable;
    if (!_setupYet) {
        [self setup];
    }
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
    cell.displayAsSelected = [self.drawable.staticAnimation matchesAnimationDict:animationDict];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *section = _sections[indexPath.section];
    NSDictionary *animationDict = section[indexPath.item];
    
    StaticAnimationPreview *cell = (StaticAnimationPreview *)[collectionView cellForItemAtIndexPath:indexPath];
    BOOL enable = !cell.displayAsSelected;
    StaticAnimation *newAnimationDict = self.drawable.staticAnimation.copy;
    if (enable) {
        [newAnimationDict addAnimationDict:animationDict];
    } else {
        [newAnimationDict removeAnimationDict:animationDict];
    }
    self.drawable.staticAnimation = newAnimationDict;
    [self.drawable updatedKeyframeProperties];
    [self updateAnimationCellSelections];
}

- (void)updateAnimationCellSelections {
    for (StaticAnimationPreview *cell in [self.collectionView visibleCells]) {
        cell.displayAsSelected = [self.drawable.staticAnimation matchesAnimationDict:cell.animationDict];
    }
}

@end
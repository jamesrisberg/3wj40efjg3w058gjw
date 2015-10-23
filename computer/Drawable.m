//
//  Drawable.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"
#import "QuickCollectionModal.h"
#import "Canvas.h"
#import "computer-Swift.h"
#import "OptionsView.h"
#import "SliderTableViewCell.h"
#import "StaticAnimationPicker.h"

@interface Drawable ()

@property (nonatomic) KeyframeStore *keyframeStore;
@property (nonatomic) CADisplayLink *displayLink;

@end



@implementation Drawable

- (instancetype)init {
    self = [super init];
    [self setup];
    return self;
}

- (void)primaryEditAction {
    
}

- (void)setup {
    _rotation = 0;
    _scale = 1;
    _itemOpacity = 1;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    BOOL shouldHaveDisplayLink = !!newWindow;
    BOOL hasDisplayLink = !!self.displayLink;
    if (hasDisplayLink != shouldHaveDisplayLink) {
        if (shouldHaveDisplayLink) {
            self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAppearance)];
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        } else {
            [self.displayLink invalidate];
            self.displayLink = nil;
        }
    }
}

- (void)dealloc {
    if (self.displayLink) [self.displayLink invalidate];
}

#pragma mark Appearances

- (void)setRotation:(CGFloat)rotation {
    _rotation = rotation;
    [self updateAppearance];
}

- (void)setScale:(CGFloat)scale {
    _scale = scale;
    [self updateAppearance];
}

- (void)setItemOpacity:(CGFloat)itemOpacity {
    _itemOpacity = itemOpacity;
    [self updateAppearance];
}

- (void)updateAppearance {
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeScale(_scale, _scale), _rotation);
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate]; // TODO: don't use the real date
    transform = [self.staticAnimation adjustTransform:transform time:time];
    CGFloat alpha = _itemOpacity;
    alpha = [self.staticAnimation adjustAlpha:alpha time:time];
    if (_dimmed) alpha *= 0.4;
    
    self.alpha = alpha;
    self.transform = transform;
}

#pragma mark Util

- (UIViewController *)vcForPresentingModals {
    return [NPSoftModalPresentationController getViewControllerForPresentationInWindow:self.window];
}

- (Canvas *)canvas {
    return (Canvas *)self.superview;
}

#pragma mark Options

- (NSArray <__kindof QuickCollectionItem*> *)optionsItems {
    __weak Drawable *weakSelf = self;
    QuickCollectionItem *delete = [QuickCollectionItem new];
    delete.label = NSLocalizedString(@"Delete", @"");
    delete.action = ^{
        [weakSelf delete:nil];
    };
    QuickCollectionItem *duplicate = [QuickCollectionItem new];
    duplicate.label = NSLocalizedString(@"Duplicate", @"");
    duplicate.action = ^{
        [weakSelf duplicate:nil];
    };
    QuickCollectionItem *options = [QuickCollectionItem new];
    options.label = NSLocalizedString(@"Options…", @"");
    options.action = ^{
        [weakSelf showOptions];
    };
    QuickCollectionItem *animations = [QuickCollectionItem new];
    animations.label = NSLocalizedString(@"Animations…", @"");
    animations.action = ^{
        [weakSelf showStaticAnimationPicker];
    };
    return @[delete, duplicate, options, animations];
}

#pragma mark Actions
- (void)delete:(id)sender {
    if (self.canvas.selection == self) self.canvas.selection = nil;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.scale /= 100;
        self.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.canvas.selection == self) self.canvas.selection = nil;
        [self removeFromSuperview];
    }];
}

- (void)duplicate:(id)sender {
    Drawable *dupe = [self copy];
    [self.canvas _addDrawableToCanvas:dupe aboveDrawable:self];
    dupe.center = CGPointMake(dupe.center.x + 20, dupe.center.y + 20);
    [dupe updatedKeyframeProperties];
}

- (void)showOptions {
    OptionsView *v = [OptionsView new];
    __weak Drawable *weakSelf = self;
    
    OptionsViewCellModel *alpha = [OptionsViewCellModel new];
    alpha.title = NSLocalizedString(@"Opacity", @"");
    alpha.cellClass = [SliderTableViewCell class];
    alpha.onCreate = ^(OptionsTableViewCell *cell){
        SliderTableViewCell *sliderCell = (SliderTableViewCell *)cell;
        sliderCell.value = weakSelf.itemOpacity;
        sliderCell.onValueChange = ^(CGFloat val) {
            weakSelf.itemOpacity = val;
            [weakSelf updatedKeyframeProperties];
        };
    };
    
    v.models = @[alpha];
    
    [self.canvas.delegate canvas:self.canvas shouldShowEditingPanel:v];
}

- (void)showStaticAnimationPicker {
    StaticAnimationPicker *picker = [StaticAnimationPicker new];
    picker.drawable = self;
    [self.canvas.delegate canvas:self.canvas shouldShowEditingPanel:picker];
}

#pragma mark Resize

- (void)setInternalSize:(CGSize)size {
    self.bounds = CGRectMake(0, 0, size.width, size.height);
}

- (void)adjustAspectRatioWithOld:(CGFloat)oldAspectRatio new:(CGFloat)aspectRatio {
    if (oldAspectRatio == 0) oldAspectRatio = 1;
    if (aspectRatio == 0) aspectRatio = 1;
    CGSize size = self.bounds.size;
    if (aspectRatio > oldAspectRatio) {
        // we're wider, so shorten the height:
        size.height = size.width / aspectRatio;
    } else {
        // we're thinner, so shorten the width:
        size.width = size.height * aspectRatio;
    }
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    
    if (self.onShapeUpdate) self.onShapeUpdate();
}


#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    // deliberately DON'T call super
    [aCoder encodeObject:[self currentKeyframeProperties] forKey:@"currentKeyframeProperties"];
    [aCoder encodeObject:self.keyframeStore forKey:@"keyframeStore"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init]; // deliberately DON'T call super
    [self setCurrentKeyframeProperties:[aDecoder decodeObjectForKey:@"currentKeyframeProperties"]];
    self.keyframeStore = [aDecoder decodeObjectForKey:@"keyframeStore"];
    return self;
}

#pragma mark Copying

- (id)copy {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

#pragma mark Keyframes

- (KeyframeStore *)keyframeStore {
    if (!_keyframeStore) {
        _keyframeStore = [KeyframeStore new];
    }
    return _keyframeStore;
}

- (NSDictionary<__kindof NSString*, id>*)currentKeyframeProperties {
    return @{
             @"bounds": [NSValue valueWithCGRect:self.bounds],
             @"center": [NSValue valueWithCGPoint:self.center],
             @"scale": @(self.scale),
             @"rotation": @(self.rotation),
             @"itemOpacity": @(self.itemOpacity),
             @"staticAnimation": self.staticAnimation
             };
}

- (void)setCurrentKeyframeProperties:(NSDictionary<__kindof NSString *, id>*)props {
    if (props[@"bounds"]) {
        self.bounds = [props[@"bounds"] CGRectValue];
    }
    if (props[@"center"]) {
        self.center = [props[@"center"] CGPointValue];
    }
    if (props[@"scale"]) {
        self.scale = [props[@"scale"] doubleValue];
    }
    if (props[@"rotation"]) {
        self.rotation = [props[@"rotation"] doubleValue];
    }
    if (props[@"itemOpacity"]) {
        self.itemOpacity = [props[@"itemOpacity"] doubleValue];
    }
    if (props[@"staticAnimation"]) {
        self.staticAnimation = props[@"staticAnimation"];
    }
}

- (void)keyframePropertiesChangedAtTime:(FrameTime *)time {
    Keyframe *keyframe = [Keyframe new];
    keyframe.frameTime = time;
    [keyframe.properties addEntriesFromDictionary:[self currentKeyframeProperties]];
    [self.keyframeStore storeKeyframe:keyframe];
}

- (void)updatedKeyframeProperties {
    if (self.onKeyframePropertiesUpdated) self.onKeyframePropertiesUpdated();
}

- (void)setDimmed:(BOOL)dimmed {
    _dimmed = dimmed;
    [self updateAppearance];
}

#pragma mark Static Animations
- (StaticAnimation *)staticAnimation {
    if (!_staticAnimation) {
        _staticAnimation = [StaticAnimation new];
    }
    return _staticAnimation;
}

@end

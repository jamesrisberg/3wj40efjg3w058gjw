//
//  ProgressBarWindow.m
//  computer
//
//  Created by Nate Parrott on 11/27/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ProgressBarWindow.h"
#import <ReactiveCocoa.h>

@interface ProgressBarWindowItem ()

@end

@implementation ProgressBarWindowItem

- (instancetype)init {
    self = [super init];
    self.minDisplayTime = 2;
    return self;
}

@end

@interface ProgressBarWindow ()

@end



@interface _ProgressBarWindowItemView : UIView

@property (nonatomic) ProgressBarWindowItem *item;
@property (nonatomic) UILabel *lowerLabel, *upperLabel;
@property (nonatomic) UIView *bar, *barMask;
@property (nonatomic) CGFloat progress;
@property (nonatomic) BOOL brighter;
@property (nonatomic) CFAbsoluteTime _presentedTime;

@end



@implementation _ProgressBarWindowItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.lowerLabel = [UILabel new];
    [self addSubview:self.lowerLabel];
    
    self.bar = [[UIView alloc] init];
    [self addSubview:self.bar];
    
    self.upperLabel = [UILabel new];
    [self.bar addSubview:self.upperLabel];
    
    self.barMask = [UIView new];
    self.bar.maskView = self.barMask;
    
    for (UILabel *label in @[self.upperLabel, self.lowerLabel]) {
        label.font = [UIFont boldSystemFontOfSize:8];
        label.textAlignment = NSTextAlignmentCenter;
    }
    
    self.brighter = NO;
    
    [self layoutIfNeeded];
    
    return self;
}

- (void)setBrighter:(BOOL)brighter {
    _brighter = brighter;
    
    UIColor *white = [UIColor colorWithWhite:brighter ? 1 : 0.9 alpha:1];
    UIColor *black = [UIColor colorWithWhite:brighter ? 0.2 : 0.1 alpha:1];
    
    self.barMask.backgroundColor = black;
    self.upperLabel.textColor = black;
    self.bar.backgroundColor = white;
    self.lowerLabel.textColor = white;
    self.backgroundColor = black;
    
}

- (void)setItem:(ProgressBarWindowItem *)item {
    _item = item;
    RAC(self.lowerLabel, text) = [RACObserve(item, title) map:^id(id value) {
        return [value uppercaseString];
    }];
    RAC(self.upperLabel, text) = [RACObserve(item, title) map:^id(id value) {
        return [value uppercaseString];
    }];
    [UIView performWithoutAnimation:^{
        RAC(self, progress) = RACObserve(item, progress);
    }];
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self setNeedsLayout];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat padding = (self.bounds.size.height - self.upperLabel.font.pointSize) / 2;
    self.bar.frame = self.bounds;
    self.barMask.frame = CGRectMake(0, 0, self.bounds.size.width * self.progress, self.bounds.size.height);
    self.upperLabel.frame = CGRectMake(padding, 0, self.bounds.size.width - padding*2, self.bounds.size.height);
    self.lowerLabel.frame = self.upperLabel.frame;
}

@end



@interface _ProgressBarWindowVC : UIViewController

@end

@implementation _ProgressBarWindowVC

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end



@interface ProgressBarWindow () {
}

@property (nonatomic) ProgressBarWindowItem *currentItem;
@property (nonatomic) _ProgressBarWindowItemView *currentItemView;
@property (nonatomic) NSArray<ProgressBarWindowItem*> *itemQueue;
@property (nonatomic) CGFloat currentItemProgress;
@property (nonatomic) BOOL currentlyTransitioning;

@end

@implementation ProgressBarWindow

#pragma mark API

+ (instancetype)shared {
    static ProgressBarWindow *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ProgressBarWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
    });
    return shared;
}

- (void)addItems:(NSArray<ProgressBarWindowItem *> *)items {
    self.itemQueue = [items arrayByAddingObjectsFromArray:self.itemQueue];
}

- (void)removeItem:(ProgressBarWindowItem *)item {
    NSMutableArray *a = self.itemQueue.mutableCopy;
    [a removeObject:item];
    self.itemQueue = a;
}

#pragma mark Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.rootViewController = [_ProgressBarWindowVC new];
    self.windowLevel = UIWindowLevelStatusBar + 1;
    self.hidden = NO;
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.itemQueue = @[];
    
    RAC(self, hidden) = [RACSignal combineLatest:@[RACObserve(self, currentItemView), RACObserve(self, currentlyTransitioning)] reduce:^id(id currentItemView, id currentlyTransitioning){
        return @(currentItemView == nil && ![currentlyTransitioning boolValue]);
    }];
    
    RAC(self, currentItem) = [RACObserve(self, itemQueue) map:^id(id value) {
        NSLog(@"queue: %@; item: %@", value, [value firstObject]);
        return [value firstObject];
    }];
    @weakify(self);
    RAC(self, currentItemView) = [RACObserve(self, currentItem) map:^id(id value) {
        if (value) {
            _ProgressBarWindowItemView *view = [[_ProgressBarWindowItemView alloc] initWithFrame:self_weak_.bounds];
            view.item = value;
            return view;
        } else {
            return nil;
        }
    }];
    
    RAC(self, currentItemProgress) = [[RACObserve(self, currentItem) map:^id(ProgressBarWindowItem *value) {
        return RACObserve(value, progress);
    }] switchToLatest];
    
    return self;
}

- (void)setCurrentItemProgress:(CGFloat)currentItemProgress {
    _currentItemProgress = currentItemProgress;
    NSLog(@"progress: %f", currentItemProgress);
    if (currentItemProgress >= 1) {
        [self checkDismiss];
    }
}

- (void)checkDismiss {
    NSLog(@"Dt: %f", CFAbsoluteTimeGetCurrent() - self.currentItemView._presentedTime);
    if (self.currentItem == self.currentItemView.item && self.currentItemView._presentedTime && self.currentItem.progress >= 1 && CFAbsoluteTimeGetCurrent() - self.currentItemView._presentedTime >= self.currentItem.minDisplayTime) {
        [self removeItem:self.currentItem];
    }
}

- (void)setCurrentItemView:(_ProgressBarWindowItemView *)currentItemView {
    _ProgressBarWindowItemView *old = _currentItemView;
    self.currentlyTransitioning = YES;
    _currentItemView = currentItemView;
    
    currentItemView._presentedTime = CFAbsoluteTimeGetCurrent();
    currentItemView.brighter = !old.brighter;
    
    if (currentItemView) {
        // slide new view above old:
        [self addSubview:currentItemView];
        currentItemView.frame = self.bounds;
        currentItemView.transform = CGAffineTransformMakeTranslation(0, -self.bounds.size.height);
        [currentItemView layoutIfNeeded];
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction animations:^{
            currentItemView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (old != self.currentItemView) {
                [old removeFromSuperview];
            }
            self.currentlyTransitioning = NO;
        }];
    } else {
        // slide old up:
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionAllowUserInteraction animations:^{
            old.transform = CGAffineTransformMakeTranslation(0, -self.bounds.size.height);
        } completion:^(BOOL finished) {
            if (old != self.currentItemView) {
                [old removeFromSuperview];
            }
            self.currentlyTransitioning = NO;
        }];
    }
    
    if (currentItemView.item.minDisplayTime) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(currentItemView.item.minDisplayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self checkDismiss];
        });
    } else {
        [self checkDismiss];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.currentItemView.frame = self.bounds;
}

@end

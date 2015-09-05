//
//  EditorViewController.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EditorViewController.h"
#import "Canvas.h"
#import "IconBar.h"
#import "Drawable.h"
#import <ReactiveCocoa.h>
#import "OptionsView.h"
#import "ShapeStackList.h"
#import "CGPointExtras.h"

@interface EditorViewController () <UIScrollViewDelegate> {
    CGPoint _scrollViewPreviousContentOffset;
    CGFloat _scrollViewPreviousZoomScale;
    UIView *_dummyScrollViewZoomingView;
}

@property (nonatomic) UIVisualEffectView *toolbar;
@property (nonatomic) UIView *toolbarView;
@property (nonatomic) IconBar *iconBar;
@property (nonatomic) UIView *selectionRect;
@property (nonatomic) OptionsView *optionsView;
@property (nonatomic) CGFloat toolbarHeight;
@property (nonatomic) Canvas *canvas;
@property (nonatomic) ShapeStackList *shapeStackList;
@property (nonatomic) UIScrollView *dummyScrollView;

@end

@implementation EditorViewController

#pragma mark Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    self.canvas = [Canvas new];
    [self.view addSubview:self.canvas];
    self.toolbar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    [self.view addSubview:self.toolbar];
    self.iconBar = [IconBar new];
    self.iconBar.editor = self;
    
    __weak EditorViewController *weakSelf = self;
    self.canvas.selectionRectNeedUpdate = ^{
        [weakSelf updateSelectionRect];
    };
    
    self.optionsView = [OptionsView new];
    self.optionsView.tableView.separatorInset = UIEdgeInsetsZero;
    self.optionsView.underlyingBlurEffect = (UIBlurEffect *)self.toolbar.effect;
    [self rac_liftSelector:@selector(selectionChanged:) withSignals:RACObserve(self.canvas, selection), nil];
    self.optionsView.onDismiss = ^{
        weakSelf.toolbarView = weakSelf.iconBar;
    };
    RAC(self.optionsView, drawable) = RACObserve(self.canvas, selection);
    
    [UIView performWithoutAnimation:^{
        self.toolbarView = self.iconBar;
    }];
    
    self.shapeStackList = [[ShapeStackList alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.shapeStackList];
    self.shapeStackList.hidden = YES;
    self.shapeStackList.onDrawableSelected = ^(Drawable *drawable){
        weakSelf.canvas.selection = drawable;
    };
    self.canvas.editorShapeStackList = self.shapeStackList;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.canvas.frame = self.view.bounds;
    self.toolbar.frame = CGRectMake(0, self.view.bounds.size.height-self.toolbarHeight, self.view.bounds.size.width, self.toolbarHeight);
    self.toolbarView.frame = self.toolbar.bounds;
    self.toolbarView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin; // set the autoresizing mask so that this view is positioned currently during the transition to a NEW toolbarView; when the toolbar's height changes, the old toolbar view should stay in the middle
    self.dummyScrollView.frame = self.view.bounds;
}

- (void)updateSelectionRect {
    if (!self.selectionRect) {
        self.selectionRect = [UIView new];
        self.selectionRect.userInteractionEnabled = NO;
        self.selectionRect.layer.borderColor = [UIColor colorWithRed:1 green:0.1 blue:0.1 alpha:0.5].CGColor;
        self.selectionRect.layer.borderWidth = 1;
        [self.view insertSubview:self.selectionRect aboveSubview:self.canvas];
    }
    self.selectionRect.hidden = (self.canvas.selection == nil);
    if (self.canvas.selection) {
        Drawable *selection = self.canvas.selection;
        self.selectionRect.bounds = CGRectMake(0, 0, selection.bounds.size.width * selection.scale, selection.bounds.size.height * selection.scale);
        self.selectionRect.center = [self.view convertPoint:selection.center fromView:selection.superview];
        self.selectionRect.transform = CGAffineTransformMakeRotation(selection.rotation);
    }
}

#pragma mark Selection
- (void)selectionChanged:(Drawable *)selection {
    if (self.toolbarView == self.optionsView) {
        self.toolbarView = self.iconBar;
    }
}

#pragma mark Toolbar
- (void)showOptions {
    if (self.canvas.selection) {
        self.toolbarView = self.optionsView;
    }
}

- (void)setToolbarView:(UIView *)toolbarView {
    if (toolbarView != _toolbarView) {
        UIView *oldToolbarView = _toolbarView;
        _toolbarView = toolbarView;
        
        [self.toolbar addSubview:toolbarView];
        CGFloat newToolbarHeight = 44;
        if (toolbarView == self.optionsView) {
            newToolbarHeight = 120;
        }
        self.toolbarHeight = newToolbarHeight;
        toolbarView.frame = CGRectMake(0, 0, self.toolbar.bounds.size.width, newToolbarHeight);
        toolbarView.alpha = 0;
        [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
            oldToolbarView.alpha = 0;
            toolbarView.alpha = 1;
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            oldToolbarView.alpha = 1;
            [oldToolbarView removeFromSuperview];
        }];
    }
}

#pragma mark Scrolling
- (void)setScrollModeActive:(BOOL)scrollModeActive {
    if (scrollModeActive != _scrollModeActive) {
        _scrollModeActive = scrollModeActive;
        if (scrollModeActive) {
            UIButton *done = [UIButton buttonWithType:UIButtonTypeCustom];
            done.titleLabel.font = [UIFont boldSystemFontOfSize:done.titleLabel.font.pointSize];
            [done setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
            [done addTarget:self action:@selector(exitScrollMode) forControlEvents:UIControlEventTouchUpInside];
            self.toolbarView = done;
            
            self.dummyScrollView = [UIScrollView new];
            [self.view insertSubview:self.dummyScrollView aboveSubview:self.canvas];
            self.dummyScrollView.delegate = self;
            self.dummyScrollView.showsHorizontalScrollIndicator = self.dummyScrollView.showsVerticalScrollIndicator = NO;
            self.dummyScrollView.directionalLockEnabled = NO;
            CGFloat aBigNumber = 20 * 1000 * 1000;
            self.dummyScrollView.contentSize = CGSizeMake(aBigNumber, aBigNumber);
            _dummyScrollViewZoomingView = [UIView new];
            _dummyScrollViewZoomingView.frame = CGRectMake(0, 0, aBigNumber, aBigNumber);
            [self.dummyScrollView addSubview:_dummyScrollViewZoomingView];
            [self _resetDummyScrollViewPositioning];
            self.dummyScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
            
            self.canvas.selection = nil;
        } else {
            self.toolbarView = self.iconBar;
            [self.dummyScrollView removeFromSuperview];
            self.dummyScrollView = nil;
        }
    }
}

- (void)exitScrollMode {
    self.scrollModeActive = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.isZooming || scrollView.isZoomBouncing || scrollView.dragging || scrollView.isDecelerating) {
        
        CGPoint correctedOffset = CGPointMake(scrollView.contentOffset.x / scrollView.zoomScale, scrollView.contentOffset.y / scrollView.zoomScale);
        CGPoint translation = CGPointZero;
        if (!scrollView.isZooming) {
            translation = CGPointMake(correctedOffset.x - _scrollViewPreviousContentOffset.x, correctedOffset.y - _scrollViewPreviousContentOffset.y);
        }
        _scrollViewPreviousContentOffset = correctedOffset;
        CGFloat zoom = scrollView.zoomScale / _scrollViewPreviousZoomScale;
        _scrollViewPreviousZoomScale = scrollView.zoomScale;
        
        CGPoint zoomCenter = [scrollView.pinchGestureRecognizer locationInView:self.canvas];
        
        for (Drawable *d in self.canvas.subviews) {
            CGPoint offsetFromPinch = CGPointMake(d.center.x - zoomCenter.x, d.center.y - zoomCenter.y);
            CGPoint newOffsetFromPinch = CGPointMake(offsetFromPinch.x * zoom, offsetFromPinch.y * zoom);
            d.center = CGPointMake(d.center.x - translation.x + newOffsetFromPinch.x - offsetFromPinch.x, d.center.y - translation.y + newOffsetFromPinch.y - offsetFromPinch.y);
            d.scale *= zoom;
        }
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [self _resetDummyScrollViewPositioning];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self _resetDummyScrollViewPositioning];
}

- (void)_resetDummyScrollViewPositioning {
    _scrollViewPreviousZoomScale = 1;
    self.dummyScrollView.zoomScale = 1;
    _scrollViewPreviousContentOffset = CGPointMake(self.dummyScrollView.contentSize.width/2, self.dummyScrollView.contentSize.height/2);
    self.dummyScrollView.contentOffset = _scrollViewPreviousContentOffset;
    self.dummyScrollView.minimumZoomScale = 0.01;
    self.dummyScrollView.maximumZoomScale = 100;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _dummyScrollViewZoomingView;
}

@end

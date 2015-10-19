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
#import "ShapeStackList.h"
#import "CGPointExtras.h"
#import "ShapeDrawable.h"
#import "FreehandInputView.h"
#import "QuickCollectionModal.h"

@interface EditorViewController () <UIScrollViewDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate> {
    CGPoint _scrollViewPreviousContentOffset;
    CGFloat _scrollViewPreviousZoomScale;
    UIView *_dummyScrollViewZoomingView;
}

@property (nonatomic) UIVisualEffectView *toolbar;
@property (nonatomic) UIView *toolbarView;
@property (nonatomic) IconBar *iconBar;
@property (nonatomic) UIView *selectionRect;
@property (nonatomic) CGFloat toolbarHeight;
@property (nonatomic) Canvas *canvas;
@property (nonatomic) ShapeStackList *shapeStackList;
@property (nonatomic) UIScrollView *dummyScrollView;

@property (nonatomic,copy) void (^modalEditingCallback)(Canvas *canvas);

@property (nonatomic) UIView *transientOverlayView;

@property (nonatomic) UIImageView *presentedFromImageView;

@end

@implementation EditorViewController

+ (EditorViewController *)editor {
    return (EditorViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Editor"];
}

#pragma mark Setup

- (void)viewDidLoad {
    __weak EditorViewController *weakSelf = self;
    
    [super viewDidLoad];
    self.toolbar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    [self.view addSubview:self.toolbar];
    self.iconBar = [IconBar new];
    self.iconBar.editor = self;
    self.iconBar.onDoneButtonPressed = ^{
        [weakSelf doneButtonPressed];
    };
    
    RACSignal *selection = [[RACObserve(self, canvas) map:^id(Canvas *canvas) {
        return RACObserve(canvas, selection);
    }] switchToLatest];
    [self rac_liftSelector:@selector(selectionChanged:) withSignals:selection, nil];
    
    [UIView performWithoutAnimation:^{
        self.toolbarView = self.iconBar;
    }];
    
    self.shapeStackList = [[ShapeStackList alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.shapeStackList];
    self.shapeStackList.hidden = YES;
    self.shapeStackList.onDrawableSelected = ^(Drawable *drawable){
        weakSelf.canvas.selection = drawable;
    };
    
    [self reinitializeWithCanvas:[Canvas new]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setModalEditingCallback:(void (^)(Canvas *))modalEditingCallback {
    _modalEditingCallback = modalEditingCallback;
    self.iconBar.isModalEditing = modalEditingCallback != nil;
}

- (void)reinitializeWithCanvas:(Canvas *)canvas {
    BOOL canvasWasHidden = self.canvas && self.canvas.hidden;
    
    __weak EditorViewController *weakSelf = self;
    // clean up old canvas:
    [self.canvas removeFromSuperview];
    self.canvas.editorShapeStackList = nil;
    self.canvas.selectionRectNeedUpdate = nil;
    // set up new canvas:
    self.canvas = canvas;
    self.canvas.editorShapeStackList = self.shapeStackList;
    self.canvas.selectionRectNeedUpdate = ^{
        [weakSelf updateSelectionRect];
    };
    self.canvas.hidden = canvasWasHidden;
    [self.view insertSubview:self.canvas atIndex:0];
}

#pragma mark Document

- (void)setDocument:(CMDocument *)document {
    void (^update)() = ^(CMDocument *doc) {
        _document.delegate = nil;
        
        _document = document;
        document.delegate = self;
        [document openWithCompletionHandler:^(BOOL success) {
            
        }];
    };
    if (_document) {
        [self saveAndClose:YES callback:update];
    } else {
        update();
    }
}

- (void)save {
    [self saveAndClose:NO callback:^{
        
    }];
}

- (void)saveAndClose:(BOOL)close callback:(void(^)())callback {
    if (close) {
        [self saveAndClose:NO callback:^{
            [self.document closeWithCompletionHandler:^(BOOL success) {
                callback();
            }];
        }];
    } else {
        [self.document saveToURL:self.document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            callback();
        }];
    }
}

#pragma mark Document delegate
- (Canvas *)canvasForDocument:(CMDocument *)document {
    return self.canvas;
}

- (void)document:(CMDocument *)document loadedCanvas:(Canvas *)canvas {
    [self reinitializeWithCanvas:canvas];
}

- (UIImage *)canvasSnapshotForDocument:(CMDocument *)document {
    UIGraphicsBeginImageContext(self.canvas.bounds.size);
    [self.canvas drawViewHierarchyInRect:self.canvas.bounds afterScreenUpdates:NO];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshot;
}

#pragma mark Layout

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.canvas.frame = self.view.bounds;
    self.toolbar.frame = CGRectMake(0, self.view.bounds.size.height-self.toolbarHeight, self.view.bounds.size.width, self.toolbarHeight);
    self.toolbarView.frame = self.toolbar.bounds;
    self.toolbarView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin; // set the autoresizing mask so that this view is positioned currently during the transition to a NEW toolbarView; when the toolbar's height changes, the old toolbar view should stay in the middle
    self.transientOverlayView.frame = self.view.bounds;
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
    
}

#pragma mark Overlays

- (void)setTransientOverlayView:(UIView *)transientOverlayView {
    [_transientOverlayView removeFromSuperview];
    _transientOverlayView = transientOverlayView;
    [self.view insertSubview:_transientOverlayView belowSubview:self.toolbar];
}

#pragma mark Toolbar
- (void)showOptions {
    if (self.canvas.selection) {
        QuickCollectionModal *modal = [QuickCollectionModal new];
        modal.itemSize = CGSizeMake(90, 44);
        modal.items = self.canvas.selection.optionsItems;
        [self presentViewController:modal animated:YES completion:nil];
    }
}

- (void)setToolbarView:(UIView *)toolbarView {
    if (toolbarView != _toolbarView) {
        UIView *oldToolbarView = _toolbarView;
        _toolbarView = toolbarView;
        
        [self.toolbar addSubview:toolbarView];
        CGFloat newToolbarHeight = 44;
        self.toolbarHeight = newToolbarHeight;
        toolbarView.frame = CGRectMake(0, 0, self.toolbar.bounds.size.width, newToolbarHeight);
        toolbarView.alpha = 0;
        [toolbarView layoutIfNeeded];
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
            self.transientOverlayView = self.dummyScrollView;
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
            if (self.transientOverlayView == self.dummyScrollView) {
                self.transientOverlayView = nil;
            }
        }
    }
}

- (void)exitScrollMode {
    self.scrollModeActive = NO;
}

- (BOOL)isScrollViewMoving:(UIScrollView *)scrollView {
    return scrollView.isZooming || scrollView.isZoomBouncing || scrollView.dragging || scrollView.isDecelerating;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self isScrollViewMoving:scrollView]) {
        
        CGPoint correctedOffset = CGPointMake(scrollView.contentOffset.x / scrollView.zoomScale, scrollView.contentOffset.y / scrollView.zoomScale);
        CGPoint translation = CGPointMake(correctedOffset.x - _scrollViewPreviousContentOffset.x, correctedOffset.y - _scrollViewPreviousContentOffset.y);
        _scrollViewPreviousContentOffset = correctedOffset;
        CGFloat zoom = scrollView.zoomScale / _scrollViewPreviousZoomScale;
        _scrollViewPreviousZoomScale = scrollView.zoomScale;
        
        CGPoint zoomCenter = [scrollView.pinchGestureRecognizer locationInView:self.canvas];
        
        CGPoint originOffsetFromPinch = CGPointMake(-zoomCenter.x, -zoomCenter.y);
        CGPoint newOriginOffsetFromPinch = CGPointMake(-zoomCenter.x * zoom, -zoomCenter.y * zoom);
        CGPoint translationCorrection = CGPointMake(newOriginOffsetFromPinch.x - originOffsetFromPinch.x, newOriginOffsetFromPinch.y - originOffsetFromPinch.y);
        translationCorrection = CGPointScale(translationCorrection, 1.0 / scrollView.zoomScale);
        
        for (Drawable *d in self.canvas.subviews) {
            CGPoint offsetFromPinch = CGPointMake(d.center.x - zoomCenter.x, d.center.y - zoomCenter.y);
            CGPoint newOffsetFromPinch = CGPointMake(offsetFromPinch.x * zoom, offsetFromPinch.y * zoom);
            d.center = CGPointMake(d.center.x - translation.x + newOffsetFromPinch.x - offsetFromPinch.x - translationCorrection.x, d.center.y - translation.y + newOffsetFromPinch.y - offsetFromPinch.y - translationCorrection.y);
            d.scale *= zoom;
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (![self isScrollViewMoving:scrollView]) {
        [self _resetDummyScrollViewPositioning];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (![self isScrollViewMoving:scrollView]) {
        [self _resetDummyScrollViewPositioning];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if (![self isScrollViewMoving:scrollView]) {
        [self _resetDummyScrollViewPositioning];
    }
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

#pragma mark Freehand Drawing

- (void)startFreehandDrawingToShape:(ShapeDrawable *)shape {
    UIButton *done = [UIButton buttonWithType:UIButtonTypeCustom];
    done.titleLabel.font = [UIFont boldSystemFontOfSize:done.titleLabel.font.pointSize];
    [done setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
    [done addTarget:self action:@selector(endFreehandDrawing) forControlEvents:UIControlEventTouchUpInside];
    self.toolbarView = done;
    
    FreehandInputView *inputView = [FreehandInputView new];
    inputView.shape = shape;
    self.transientOverlayView = inputView;
}

- (void)endFreehandDrawing {
    self.toolbarView = self.iconBar;
    if ([self.transientOverlayView isKindOfClass:[FreehandInputView class]]) {
        self.transientOverlayView = nil;
    }
}

#pragma mark Modal editing

+ (EditorViewController *)modalEditorForCanvas:(Canvas *)canvas callback:(void(^)(Canvas *edited))callback {
    EditorViewController *vc = [self editor];
    [vc reinitializeWithCanvas:[canvas copy]];
    vc.modalEditingCallback = callback;
    return vc;
}

- (void)doneButtonPressed {
    [self saveAndClose:YES callback:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

#pragma mark Transitions

- (void)presentFromSnapshot:(UIImageView *)snapshot inViewController:(UIViewController *)vc {
    self.transitioningDelegate = self;
    self.presentedFromImageView = snapshot;
    [vc presentViewController:self animated:YES completion:nil];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *root = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    if (toVC == self) {
        // presenting:
        [root addSubview:toVC.view];
        toVC.view.frame = [transitionContext finalFrameForViewController:toVC];
        
        UIImageView *snapshotView = [UIImageView new];
        [root insertSubview:snapshotView belowSubview:self.view];
        snapshotView.frame = [root convertRect:self.presentedFromImageView.bounds fromView:self.presentedFromImageView];
        snapshotView.image = self.presentedFromImageView.image;
        snapshotView.contentMode = self.presentedFromImageView.contentMode;
        snapshotView.backgroundColor = [UIColor whiteColor];
        snapshotView.clipsToBounds = YES;
        self.presentedFromImageView.hidden = YES;
        self.canvas.hidden = YES;
        
        self.view.backgroundColor = [UIColor clearColor];
        self.toolbar.transform = CGAffineTransformMakeTranslation(0, self.iconBar.bounds.size.height);
        
        [UIView animateWithDuration:duration animations:^{
            snapshotView.frame = [root convertRect:self.view.bounds fromView:self.view];
            self.toolbar.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            toVC.view.backgroundColor = [UIColor whiteColor];
            self.presentedFromImageView.hidden = NO;
            self.canvas.hidden = NO;
            [snapshotView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    } else {
        // dismissing:
        [root insertSubview:toVC.view atIndex:0];
        self.view.clipsToBounds = YES;
        toVC.view.frame = [transitionContext finalFrameForViewController:toVC];
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            fromVC.view.transform = CGAffineTransformMakeTranslation(0, fromVC.view.bounds.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end

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
#import "TimelineView.h"
#import "OptionsView.h"
#import "Exporter.h"
#import "PhotoExporter.h"
#import "VideoExporter.h"
#import "GifExporter.h"
#import "CropView.h"
#import "PropertiesModal.h"
#import "StrokePickerViewController.h"
#import "computer-Swift.h"
#import "UIBarButtonItem+BorderedButton.h"
#import "RepetitionPicker.h"
#import "VideoConstants.h"

typedef NS_ENUM(NSInteger, FloatingButtonPosition) {
    FloatingButtonPositionBottomRight,
    FloatingButtonPositionTopLeft,
    FloatingButtonPositionTopRight,
    _FloatingButtonPositionMax
};

@interface EditorViewController () <UIScrollViewDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, TimelineViewDelegate, ExporterDelegate> {
    CGPoint _scrollViewPreviousContentOffset;
    CGFloat _scrollViewPreviousZoomScale;
    UIView *_dummyScrollViewZoomingView;
    NSMutableArray<__kindof UIView*> *_selectionRects;
    NSMutableDictionary<__kindof NSNumber*, UIView*> *_floatingButtons;
}

@property (nonatomic) UIView *toolbar;
@property (nonatomic) UIView *toolbarView;
@property (nonatomic) IconBar *iconBar;
@property (nonatomic) CGFloat toolbarHeight;
@property (nonatomic) Canvas *canvas;
@property (nonatomic) ShapeStackList *shapeStackList;
@property (nonatomic) UIScrollView *dummyScrollView;
@property (nonatomic) TimelineView *timeline;
@property (nonatomic) UIView *panelView;

@property (nonatomic) BOOL hideSelectionRects;

@property (nonatomic,copy) void (^modalEditingCallback)(Canvas *canvas);

@property (nonatomic) UIView *transientOverlayView;

@property (nonatomic) UIImageView *presentedFromImageView;

- (void)setFloatingButton:(UIView *)buttonOrNil forPosition:(FloatingButtonPosition)pos;

@property (nonatomic) Exporter *currentExporter;
@property (nonatomic,weak) CropView *cropView;

// mode=cropping preview playback:
@property (nonatomic) BOOL playingPreviewNow;
@property (nonatomic) UIButton *playButton;
@property (nonatomic) RepetitionPicker *repetitionPicker;
@property (nonatomic) CADisplayLink *previewPlaybackDisplayLink;
@property (nonatomic) NSTimeInterval durationCache; // set when entering playback mode

@end

@implementation EditorViewController

+ (EditorViewController *)editor {
    return (EditorViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Editor"];
}

#pragma mark Setup

- (void)viewDidLoad {
    __weak EditorViewController *weakSelf = self;
    
    [super viewDidLoad];
    self.toolbar = [UIView new]; //[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.toolbar.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.toolbar];
    self.iconBar = [IconBar new];
    self.iconBar.editor = self;
    self.iconBar.onDoneButtonPressed = ^{
        [weakSelf doneButtonPressed];
    };
    self.iconBar.isModalEditing = !!self.modalEditingCallback;
    
    /*RACSignal *selection = [[RACObserve(self, canvas) map:^id(Canvas *canvas) {
        return RACObserve(canvas, selection);
    }] switchToLatest];*/
    
    [UIView performWithoutAnimation:^{
        self.toolbarView = self.iconBar;
    }];
    
    self.shapeStackList = [[ShapeStackList alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.shapeStackList];
    self.shapeStackList.hidden = YES;
    self.shapeStackList.onDrawableSelected = ^(Drawable *drawable){
        [weakSelf.canvas userGesturedToSelectDrawable:drawable];
    };
    
    [self reinitializeWithCanvas:self.canvas ? : [Canvas new]];
    
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
    
    // __weak EditorViewController *weakSelf = self;
    // clean up old canvas:
    [self.canvas removeFromSuperview];
    self.canvas.editorShapeStackList = nil;
    self.canvas.delegate = nil;
    // set up new canvas:
    self.canvas = canvas;
    self.canvas.editorShapeStackList = self.shapeStackList;
    self.canvas.delegate = self;
    self.canvas.hidden = canvasWasHidden;
    [self.view insertSubview:self.canvas atIndex:0];
    [self setMode:self.mode];
}

#pragma mark Document

- (void)setDocument:(CMDocument *)document {
    void (^update)() = ^(CMDocument *doc) {
        _document.delegate = nil;
        
        _document = document;
        document.delegate = self;
        [[UIApplication sharedApplication].windows.firstObject.rootViewController.view setUserInteractionEnabled:NO];
        [document openWithCompletionHandler:^(BOOL success) {
            [[UIApplication sharedApplication].windows.firstObject.rootViewController.view setUserInteractionEnabled:YES];
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
    self.view.window.userInteractionEnabled = NO;
    if (close) {
        [self saveAndClose:NO callback:^{
            [self.document closeWithCompletionHandler:^(BOOL success) {
                self.view.window.userInteractionEnabled = YES;
                callback();
            }];
        }];
    } else {
        [self.document saveToURL:self.document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            self.view.window.userInteractionEnabled = YES;
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
    if (!self.view.window) {
        return nil;
    }
    UIGraphicsBeginImageContext(self.canvas.bounds.size);
    [self.canvas drawViewHierarchyInRect:self.canvas.bounds afterScreenUpdates:YES];
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
    
    UIView *bottomRight = _floatingButtons[@(FloatingButtonPositionBottomRight)];
    bottomRight.frame = CGRectMake(self.view.bounds.size.width - bottomRight.frame.size.width - 15, self.toolbar.frame.origin.y - bottomRight.frame.size.height - 15, bottomRight.frame.size.width, bottomRight.frame.size.height);
    
    UIView *topLeft = _floatingButtons[@(FloatingButtonPositionTopLeft)];
    topLeft.frame = CGRectMake(15, [[self topLayoutGuide] length] + 15, topLeft.frame.size.width, topLeft.frame.size.height);
    
    UIView *topRight = _floatingButtons[@(FloatingButtonPositionTopRight)];
    topRight.frame = CGRectMake(self.view.bounds.size.width - topRight.frame.size.width - 15, [[self topLayoutGuide] length] + 15, topRight.frame.size.width, topRight.frame.size.height);
}

- (void)setFloatingButton:(UIView *)buttonOrNil forPosition:(FloatingButtonPosition)pos {
    if (!_floatingButtons) _floatingButtons = [NSMutableDictionary new];
    UIView *old = _floatingButtons[@(pos)];
    [_floatingButtons removeObjectForKey:@(pos)];
    
    if (old) {
        [UIView animateWithDuration:0.3 animations:^{
            old.alpha = 0;
            old.transform = CGAffineTransformMakeScale(0.5, 0.5);
        } completion:^(BOOL finished) {
            if (![[_floatingButtons allValues] containsObject:old]) {
                [old removeFromSuperview];
            }
        }];
    }
    
    if (buttonOrNil) {
        _floatingButtons[@(pos)] = buttonOrNil;
        [self.view insertSubview:buttonOrNil aboveSubview:self.toolbar];
        [self viewDidLayoutSubviews];
        buttonOrNil.alpha = 0;
        if (pos == FloatingButtonPositionBottomRight) {
            buttonOrNil.transform = CGAffineTransformMakeTranslation(0, 40);
        } else if (pos == FloatingButtonPositionTopLeft || pos == FloatingButtonPositionTopRight) {
            buttonOrNil.transform = CGAffineTransformMakeTranslation(0, -40);
        }
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            buttonOrNil.transform = CGAffineTransformIdentity;
            buttonOrNil.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)clearFloatingButtons {
    for (FloatingButtonPosition i=0; i<_FloatingButtonPositionMax; i++) {
        [self setFloatingButton:nil forPosition:i];
    }
}

- (void)addAuxiliaryModeResetButton {
    [self addAuxiliaryModeResetButtonWithTitle:NSLocalizedString(@"Done", @"")];
}

- (void)addAuxiliaryModeResetButtonWithTitle:(NSString *)title {
    UIButton *done = [UIButton buttonWithType:UIButtonTypeCustom];
    [done setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [done setTitle:title forState:UIControlStateNormal];
    [self configureViewWithFloatingButtonAppearance:done];
    done.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [done sizeToFit];
    done.frame = CGRectMake(0, 0, done.frame.size.width + 40, done.frame.size.height + 14);
    [done addTarget:self action:@selector(resetMode) forControlEvents:UIControlEventTouchUpInside];
    [self setFloatingButton:done forPosition:FloatingButtonPositionBottomRight];
}

- (void)configureViewWithFloatingButtonAppearance:(UIView *)view {
    view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    view.layer.cornerRadius = 5;
    view.clipsToBounds = YES;
}

#pragma mark Canvas delegate
- (void)canvasDidChangeSelection:(Canvas *)canvas {
    // TODO: flash selection rect
    
    if (self.mode == EditorModePanelView) {
        [self resetMode];
    }
}

- (void)canvasSelectionRectNeedsUpdate:(Canvas *)canvas {
    if (!_selectionRects) _selectionRects = [NSMutableArray new];
    while (_selectionRects.count < canvas.selectedItems.count) {
        UIView *rect = [UIView new];
        rect.userInteractionEnabled = NO;
        rect.layer.borderColor = [UIColor redColor].CGColor;
        rect.layer.borderWidth = 1.5;
        rect.hidden = self.hideSelectionRects;
        [self.view insertSubview:rect aboveSubview:self.canvas];
        [_selectionRects addObject:rect];
    }
    while (_selectionRects.count > canvas.selectedItems.count) {
        [_selectionRects.lastObject removeFromSuperview];
        [_selectionRects removeLastObject];
    }
    NSInteger i = 0;
    for (Drawable *selection in canvas.selectedItems) {
        UIView *rect = _selectionRects[i++];
        rect.bounds = CGRectMake(0, 0, selection.bounds.size.width * selection.scale, selection.bounds.size.height * selection.scale);
        rect.center = [self.view convertPoint:selection.center fromView:selection.superview];
        rect.transform = CGAffineTransformMakeRotation(selection.rotation);
    }
}

- (void)canvasDidUpdateKeyframesForCurrentTime:(Canvas *)canvas {
    [self.timeline keyframeAvailabilityUpdatedForTime:canvas.time];
    [self.document maybeEdited];
}

- (void)canvas:(Canvas *)canvas shouldShowEditingPanel:(UIView *)panel {
    self.panelView = panel;
    self.mode = EditorModePanelView;
}

- (void)canvasShowShouldOptions:(Canvas *)canvas withInteractivePresenter:(UIPercentDrivenInteractiveTransition *)presenter touchPos:(CGPoint)pos {
    [self showOptionsInteractively:presenter touchPos:pos];
    [self.document maybeEdited];
}

- (void)setHideSelectionRects:(BOOL)hideSelectionRects {
    _hideSelectionRects = hideSelectionRects;
    for (UIView *rect in _selectionRects) {
        rect.hidden = hideSelectionRects;
    }
}

#pragma mark Overlays

- (void)setTransientOverlayView:(UIView *)transientOverlayView {
    [_transientOverlayView removeFromSuperview];
    _transientOverlayView = transientOverlayView;
    [self.view insertSubview:_transientOverlayView belowSubview:self.toolbar];
}

#pragma mark Toolbar

- (void)showOptions {
    [self showOptionsInteractively:nil touchPos:CGPointZero];
}

- (void)showOptionsInteractively:(UIPercentDrivenInteractiveTransition *)transition touchPos:(CGPoint)pos {
    if (self.canvas.selectedItems.count) {
        Drawable *d = self.canvas.selectedItems.anyObject;
        PropertiesModal *modal = [PropertiesModal new];
        if (!CGPointEqualToPoint(pos, CGPointZero)) modal.touchPointInWindowCoordinates = [self.view.window convertPoint:pos fromView:self.canvas];
        modal.interactivePresentation = transition;
        modal.items = [d optionsItems];
        modal.optionsCellModels = [d optionsViewCellModels];
        modal.inlineViewController = [d createInlineViewControllerForEditing];
        modal.topActionView = [d propertiesModalTopActionView];
        modal.mainAction = [d mainAction];
        [self presentViewController:modal animated:YES completion:nil];
    }
}

- (void)setToolbarView:(UIView *)toolbarView {
    if (toolbarView != _toolbarView) {
        UIView *oldToolbarView = _toolbarView;
        _toolbarView = toolbarView;
        
        [self.toolbar addSubview:toolbarView];
        
        CGFloat newToolbarHeight = toolbarView.intrinsicContentSize.height;
        if (newToolbarHeight == UIViewNoIntrinsicMetric || newToolbarHeight < 44) {
            newToolbarHeight = 44;
        }
        
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
            if (oldToolbarView != _toolbarView) {
                [oldToolbarView removeFromSuperview];
            }
        }];
    }
}

#pragma mark Scrolling

- (void)exitScrollMode {
    self.mode = EditorModeNormal;
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
            for (Keyframe *keyframe in d.keyframeStore.allKeyframes) {
                CGPoint center = [keyframe.properties[@"center"] CGPointValue];
                CGFloat scale = [keyframe.properties[@"scale"] floatValue];
                CGPoint offsetFromPinch = CGPointMake(center.x - zoomCenter.x, center.y - zoomCenter.y);
                CGPoint newOffsetFromPinch = CGPointMake(offsetFromPinch.x * zoom, offsetFromPinch.y * zoom);
                CGPoint newCenter = CGPointMake(center.x - translation.x + newOffsetFromPinch.x - offsetFromPinch.x - translationCorrection.x, center.y - translation.y + newOffsetFromPinch.y - offsetFromPinch.y - translationCorrection.y);
                CGFloat newScale = scale * zoom;
                keyframe.properties[@"center"] = [NSValue valueWithCGPoint:newCenter];
                keyframe.properties[@"scale"] = @(newScale);
            }
        }
        
        self.canvas.time = self.canvas.time; // trigger update based on keyframes
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

#pragma mark Modes
- (void)setMode:(EditorMode)mode {
    if (mode != _mode) {
        EditorMode oldMode = _mode;
        _mode = mode;
        
        self.transientOverlayView = nil;
        self.toolbarView = self.iconBar;
        
        [self clearFloatingButtons];
        self.canvas.multipleSelectionEnabled = (mode == EditorModeSelection);
        self.hideSelectionRects = (mode == EditorModeDrawing || mode == EditorModeExportCropping || mode == EditorModeExportRunning);
        self.playingPreviewNow = NO;
        
        if (oldMode == EditorModeExportCropping && self.currentExporter.defaultTime) {
            [self.timeline scrollToTime:self.currentExporter.defaultTime.time animated:NO];
            self.canvas.time = self.currentExporter.defaultTime;
        }
        // [self snapTimeToNearestKeyframe]; // not needed?
        
        if (mode == EditorModeScroll) {
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
            
            self.canvas.selectedItems = [NSSet set];
        } else if (mode == EditorModeDrawing) {
            UIToolbar *toolbar = [UIToolbar new];
            toolbar.items = @[
                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(undoFreehandStroke)],
                              [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Style…", @"") style:UIBarButtonItemStylePlain target:self action:@selector(editFreehandStrokeStyle)],
                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(resetMode)]
                              ];
            [toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            toolbar.tintColor = [UIColor whiteColor];
            self.toolbarView = toolbar;
        } else if (mode == EditorModeTimeline) {
            self.timeline = [TimelineView new];
            self.toolbarView = self.timeline;
            [self.timeline scrollToTime:self.canvas.time.time animated:NO];
            self.timeline.delegate = self;
            [self addAuxiliaryModeResetButton];
        } else if (mode == EditorModePanelView) {
            self.toolbarView = self.panelView;
            [self addAuxiliaryModeResetButton];
        } else if (mode == EditorModeExportCropping) {
            [self enterCropMode];
        } else if (mode == EditorModeExportRunning) {
            UIButton *cancel = [UIButton buttonWithType:UIButtonTypeCustom];
            cancel.titleLabel.font = [UIFont boldSystemFontOfSize:cancel.titleLabel.font.pointSize];
            [cancel setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
            [cancel addTarget:self action:@selector(cancelExport) forControlEvents:UIControlEventTouchUpInside];
            self.toolbarView = cancel;
        } else if (mode == EditorModeSelection) {
            self.toolbarView = [self createSelectionIconBar];
            [self addAuxiliaryModeResetButton];
        }
        
        if (oldMode == EditorModeTimeline) {
            self.timeline = nil;
        }
        
        self.canvas.useTimeForStaticAnimations = (mode == EditorModeTimeline || mode == EditorModeExportRunning || mode == EditorModeExportCropping);
        self.canvas.suppressTimingVisualizations = (mode == EditorModeExportCropping || mode == EditorModeExportRunning);
    }
}

- (void)resetMode {
    self.mode = EditorModeNormal;
}

- (void)setPanelView:(UIView *)panelView {
    if (_panelView && self.toolbarView == _panelView) {
        self.toolbarView = panelView;
    }
    _panelView = panelView;
}

#pragma mark Freehand Drawing

- (void)startFreehandDrawingToShape:(ShapeDrawable *)shape {
    self.mode = EditorModeDrawing;
    
    FreehandInputView *inputView = [FreehandInputView new];
    inputView.shape = shape;
    self.transientOverlayView = inputView;
}

- (void)editFreehandStrokeStyle {
    FreehandInputView *iv = (id)self.transientOverlayView;
    if ([iv isKindOfClass:[FreehandInputView class]]) {
        StrokePickerViewController *picker = [[StrokePickerViewController alloc] init];
        picker.width = iv.shape.strokeWidth;
        picker.color = iv.shape.strokeColor;
        picker.onChange = ^(CGFloat width, UIColor *color) {
            iv.shape.strokeWidth = width;
            iv.shape.strokeColor = color;
        };
        [NPSoftModalPresentationController presentViewController:picker fromViewController:self];
    }
}

- (void)undoFreehandStroke {
    FreehandInputView *iv = (id)self.transientOverlayView;
    if ([iv isKindOfClass:[FreehandInputView class]]) {
        [iv undoLastStroke];
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
    if (self.modalEditingCallback) {
        [self dismissViewControllerAnimated:YES completion:nil];
        self.modalEditingCallback([self.canvas copy]);
    } else {
        [self saveAndClose:YES callback:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
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
        //UIColor *oldRootBackgroundColor = root.backgroundColor;
        //root.backgroundColor = [UIColor blackColor];
        [root insertSubview:toVC.view atIndex:0];
        self.view.clipsToBounds = YES;
        toVC.view.frame = [transitionContext finalFrameForViewController:toVC];
        UIView *editorView = toVC.view;
        editorView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        editorView.alpha = 0.7;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            editorView.transform = CGAffineTransformIdentity;
            editorView.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            fromVC.view.transform = CGAffineTransformMakeTranslation(0, fromVC.view.bounds.size.height);
        } completion:^(BOOL finished) {
            //root.backgroundColor = oldRootBackgroundColor;
            [transitionContext completeTransition:YES];
        }];
    }
}

#pragma mark Timeline

- (void)timelineViewDidScroll:(TimelineView *)timelineView {
    self.canvas.time = [timelineView currentFrameTime];
}

- (BOOL)timelineView:(TimelineView *)timelineView shouldIndicateKeyframesExistAtTime:(FrameTime *)time {
    for (Drawable *d in [self.canvas drawables]) {
        if ([d.keyframeStore keyframeAtTime:time] != nil) {
            return YES;
        }
    }
    return NO;
}

- (void)snapTimeToNearestKeyframe {
    NSInteger frame = round(self.canvas.time.time * VC_TIMELINE_CELLS_PER_SECOND);
    FrameTime *frameTime = [[FrameTime alloc] initWithFrame:frame atFPS:VC_TIMELINE_CELLS_PER_SECOND];
    self.canvas.time = frameTime;
    [self.timeline scrollToTime:frameTime.time animated:YES];
}

#pragma mark Export

- (void)beginExportFlow {
    __weak EditorViewController *weakSelf = self;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Share as:", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Photo", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf startCroppingWithExporter:[PhotoExporter new]];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Video", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf startCroppingWithExporter:[VideoExporter new]];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"GIF", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf startCroppingWithExporter:[GifExporter new]];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)startCroppingWithExporter:(Exporter *)exporter {
    [UIView performWithoutAnimation:^{
        self.currentExporter = exporter;
        self.mode = EditorModeExportCropping;
    }];
}

- (void)startRunningExport {
    if ([self.currentExporter isKindOfClass:[AnimatedExporter class]]) {
        AnimatedExporter *exp = (id)self.currentExporter;
        exp.repeatCount = self.canvas.repeatCount;
        exp.rebound = self.canvas.reboundAnimation;
    }
    self.currentExporter.cropRect = self.cropView.cropRect;
    self.currentExporter.canvasSize = self.canvas.bounds.size;
    self.currentExporter.delegate = self;
    self.currentExporter.defaultTime = self.canvas.time;
    self.currentExporter.endTime = [self durationForExport];
    self.currentExporter.parentViewController = self;
    self.mode = EditorModeExportRunning;
    [self.currentExporter start];
}

- (FrameTime *)durationForExport {
    FrameTime *endTime = self.canvas.duration;
    if (endTime.frame == 0) {
        endTime = [[FrameTime alloc] initWithFrame:2 atFPS:1];
    }
    NSTimeInterval extraDuration = (self.canvas.reboundAnimation || self.canvas.repeatCount > 1) ? 0 : 2;
    endTime = [[FrameTime alloc] initWithFrame:endTime.frame + endTime.fps * extraDuration atFPS:endTime.fps];
    return endTime;
}

- (void)cancelExport {
    [self.currentExporter cancel];
    self.currentExporter = nil;
    self.mode = EditorModeNormal;
}

- (void)exporter:(Exporter *)exporter drawFrameAtTime:(FrameTime *)time inRect:(CGRect)drawIntoRect {
    [self.timeline scrollToTime:time.time animated:NO];
    self.canvas.time = time;
    [self.canvas drawViewHierarchyInRect:drawIntoRect afterScreenUpdates:YES];
}

- (void)exporter:(Exporter *)exporter updateProgress:(double)progress {
    
}

- (void)exporterDidFinish:(Exporter *)exporter {
    self.canvas.time = exporter.defaultTime;
    self.mode = EditorModeNormal;
}

#pragma mark Selection mode

- (void)enterSelectionMode {
    self.mode = EditorModeSelection;
}

- (UIToolbar *)createSelectionIconBar {
    UIToolbar *t = [UIToolbar new];
    [t setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    t.tintColor = [UIColor whiteColor];
    
    UIBarButtonItem *group = [[UIBarButtonItem alloc] initBorderedWithTitle:NSLocalizedString(@"Group", @"") target:self.canvas action:@selector(createGroup:)];
    UIBarButtonItem *delete = [[UIBarButtonItem alloc] initBorderedWithTitle:NSLocalizedString(@"Delete", @"") target:self.canvas action:@selector(delete:)];
    UIBarButtonItem *copy = [[UIBarButtonItem alloc] initBorderedWithTitle:NSLocalizedString(@"Copy", @"") target:self.canvas action:@selector(copy:)];
    UIBarButtonItem *paste = [[UIBarButtonItem alloc] initBorderedWithTitle:NSLocalizedString(@"Paste", @"") target:self.canvas action:@selector(paste:)];
    UIBarButtonItem *divider = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    t.items = @[delete, divider, copy, paste, group];
    
    return t;
}

#pragma mark Crop/Preview mode

- (void)enterCropMode {
    CropView *cropView = [CropView new];
    self.cropView = cropView;
    self.transientOverlayView = cropView;
    [self viewDidLayoutSubviews];
    CGFloat cropSize = round(MIN(self.cropView.bounds.size.width, self.cropView.bounds.size.height) * 0.8);
    cropView.cropRect = CGRectMake(self.cropView.bounds.size.width/2 - cropSize/2, self.cropView.bounds.size.height/2 - cropSize/2, cropSize, cropSize);
    
    UIButton *continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    continueButton.titleLabel.font = [UIFont boldSystemFontOfSize:continueButton.titleLabel.font.pointSize];
    [continueButton setTitle:NSLocalizedString(@"Continue", @"") forState:UIControlStateNormal];
    [continueButton addTarget:self action:@selector(startRunningExport) forControlEvents:UIControlEventTouchUpInside];
    self.toolbarView = continueButton;
    [self addAuxiliaryModeResetButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    
    AnimatedExporter *animated = [self.currentExporter isKindOfClass:[AnimatedExporter class]] ? (id)self.currentExporter : nil;
    
    if (animated) {
        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playButton.frame = CGRectMake(0, 0, 40, 40);
        [self configureViewWithFloatingButtonAppearance:self.playButton];
        self.playButton.layer.cornerRadius = self.playButton.bounds.size.width/2;
        [self.playButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.playButton addTarget:self action:@selector(togglePlayback) forControlEvents:UIControlEventTouchUpInside];
        self.playingPreviewNow = NO;
        self.durationCache = [self durationForExport].time;
        
        [self setFloatingButton:self.playButton forPosition:FloatingButtonPositionTopLeft];
        
        self.repetitionPicker = [RepetitionPicker picker];
        self.repetitionPicker.repeatCount = self.canvas.repeatCount;
        self.repetitionPicker.rebound = self.canvas.reboundAnimation;
        self.repetitionPicker.onlyAllowTogglingRebound = ![animated respectsRepeatCount];
        [self configureViewWithFloatingButtonAppearance:self.repetitionPicker];
        [self.repetitionPicker sizeToFit];
        self.repetitionPicker.layer.cornerRadius = self.repetitionPicker.bounds.size.height/2;
        [self setFloatingButton:self.repetitionPicker forPosition:FloatingButtonPositionTopRight];
        __weak EditorViewController *weakSelf = self;
        self.repetitionPicker.onChange = ^{
            weakSelf.canvas.repeatCount = weakSelf.repetitionPicker.repeatCount;
            weakSelf.canvas.reboundAnimation = weakSelf.repetitionPicker.rebound;
            weakSelf.durationCache = [weakSelf durationForExport].time;
        };
    }
}

- (void)togglePlayback {
    self.playingPreviewNow = !self.playingPreviewNow;
}

- (void)setPlayingPreviewNow:(BOOL)playingPreviewNow {
    _playingPreviewNow = playingPreviewNow;
    if (playingPreviewNow && !self.previewPlaybackDisplayLink) {
        self.previewPlaybackDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_updatePreviewPlayback)];
        [self.previewPlaybackDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    } else if (!playingPreviewNow) {
        [self.previewPlaybackDisplayLink invalidate];
        self.previewPlaybackDisplayLink = nil;
    }
    [self.playButton setImage:[UIImage imageNamed:(playingPreviewNow ? @"Pause" : @"PlayCentered")] forState:UIControlStateNormal];
}

- (void)_updatePreviewPlayback {
    NSTimeInterval t = self.canvas.time.time + self.previewPlaybackDisplayLink.duration;
    FrameTime *frameTime;
    if (t > _durationCache) {
        frameTime = [[FrameTime alloc] initWithFrame:0 atFPS:1];
    } else {
        frameTime = [[FrameTime alloc] initWithFrame:t * 100000 atFPS:100000];
    }
    self.canvas.time = frameTime;
    [self.timeline scrollToTime:t animated:NO];
}

@end

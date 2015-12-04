//
//  Drawable.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuickCollectionModal.h"
#import "Keyframe.h"
#import "StaticAnimation.h"
#import "OptionsView.h"

extern NSString * const DrawableArrayPasteboardType;

@class CanvasEditor;
@interface Drawable : UIView <NSCopying, TimeAware>

- (void)primaryEditAction;
- (void)setup; // override this
@property (nonatomic) CGFloat rotation, scale, itemOpacity;
- (UIViewController *)vcForPresentingModals;
- (NSArray <__kindof QuickCollectionItem*> *)optionsItems;
- (QuickCollectionItem *)mainAction;
- (UIView *)propertiesModalTopActionView;
- (UIViewController *)createInlineViewControllerForEditing;
- (CanvasEditor *)canvas;
@property (nonatomic,copy) void (^onShapeUpdate)();

- (void)setInternalSize:(CGSize)size;
- (void)updateAspectRatio:(CGFloat)aspect;
- (CGRect)unrotatedBoundingBox;

- (NSDictionary<__kindof NSString*, id>*)currentKeyframeProperties;
- (void)setCurrentKeyframeProperties:(NSDictionary<__kindof NSString *, id>*)props;
@property (nonatomic,readonly) KeyframeStore *keyframeStore;
- (void)keyframePropertiesChangedAtTime:(FrameTime *)time;

- (NSArray<__kindof OptionsViewCellModel*>*)optionsViewCellModels;

// helper for subclasses:
- (OptionsViewCellModel *)sliderForKey:(NSString *)key title:(NSString *)title;

/*
 -updatedKeyframeProperties should be called WHENEVER the user manipulates
 a keyframe-animatable property:
 - center
 - scale
 - rotation
 - alpha
 - staticAnimation
 */

- (void)updatedKeyframeProperties;
@property (nonatomic,copy) void(^onKeyframePropertiesUpdated)(); // set by the editor

@property (nonatomic) StaticAnimation *staticAnimation; // DO NOT modify this in place

@property (nonatomic) BOOL dimmed;

@property (nonatomic) BOOL useTimeForStaticAnimations;
@property (nonatomic) FrameTime *time;
@property (nonatomic) BOOL suppressTimingVisualizations;

@property (nonatomic) BOOL transientEDUView;

@property (nonatomic) BOOL preparedForStaticScreenshot;

@end
 
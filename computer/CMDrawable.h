//
//  CMDrawable.h
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

@import UIKit;
#import "Keyframe.h"
#import "EVInterpolation.h"
@class CMDrawableKeyframe;
@class OptionsViewCellModel;
#import "CanvasEditor.h"
#import "QuickCollectionModal.h"
#import "OptionsView.h"

@interface CMDrawableView : UIView

@end


@interface CMDrawable : NSObject <NSCoding, NSCopying>

- (instancetype)init;
- (NSArray<NSString*>*)keysForCoding;
@property (nonatomic) CGFloat boundsDiagonal;
@property (nonatomic,readonly) KeyframeStore *keyframeStore;
- (Class)keyframeClass;
@property (nonatomic,readonly) NSString *key;

- (CMDrawableView *)renderToView:(CMDrawableView *)existingOrNil atTime:(FrameTime *)time;

- (FrameTime *)maxTime;

- (NSArray <__kindof QuickCollectionItem*> *)optionsItemsWithEditor:(CanvasEditor *)editor;
- (QuickCollectionItem *)mainActionWithEditor:(CanvasEditor *)editor;
- (UIView *)propertiesModalTopActionViewWithEditor:(CanvasEditor *)editor;
- (UIViewController *)createInlineViewControllerForEditingWithEditor:(CanvasEditor *)editor;
- (NSArray<__kindof OptionsViewCellModel*>*)optionsViewCellModelsWithEditor:(CanvasEditor *)editor;

@end


@interface CMDrawableKeyframe : NSObject <NSCoding, EVInterpolation, NSCopying>

@property (nonatomic) FrameTime *frameTime;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat scale, rotation, alpha;
- (NSArray<NSString*>*)keys;

@end

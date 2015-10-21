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

@class Canvas;
@interface Drawable : UIView <NSCopying>

- (void)primaryEditAction;
- (void)setup; // override this
@property (nonatomic) CGFloat rotation, scale, itemOpacity;
- (UIViewController *)vcForPresentingModals;
- (NSArray <__kindof QuickCollectionItem*> *)optionsItems;
- (Canvas *)canvas;
@property (nonatomic,copy) void (^onShapeUpdate)();

- (void)setInternalSize:(CGSize)size;

- (NSDictionary<__kindof NSString*, id>*)currentKeyframeProperties;
- (void)setCurrentKeyframeProperties:(NSDictionary<__kindof NSString *, id>*)props;
@property (nonatomic,readonly) KeyframeStore *keyframeStore;
- (void)keyframePropertiesChangedAtTime:(FrameTime *)time;

- (void)updatedKeyframeProperties;
@property (nonatomic,copy) void(^onKeyframePropertiesUpdated)(); // set by the editor

@end

//
//  Drawable.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuickCollectionModal.h"

@class Canvas;
@interface Drawable : UIView <NSCopying>

- (void)primaryEditAction;
- (void)setup; // override this
@property (nonatomic) CGFloat rotation, scale;
- (UIViewController *)vcForPresentingModals;
- (NSArray <__kindof QuickCollectionItem*> *)optionsItems;
- (Canvas *)canvas;
@property (nonatomic,copy) void (^onShapeUpdate)();

- (void)setInternalSize:(CGSize)size;

@end

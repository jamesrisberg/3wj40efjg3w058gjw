//
//  Drawable.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OptionsView.h"

@class Canvas;
@interface Drawable : UIView

- (void)primaryEditAction;
- (void)setup; // override this
@property (nonatomic) CGFloat rotation, scale;
- (UIViewController *)vcForPresentingModals;
- (NSArray *)optionsCellModels;
- (Canvas *)canvas;
@property (nonatomic,copy) void (^onShapeUpdate)();

@end

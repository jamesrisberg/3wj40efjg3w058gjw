//
//  PropertiesView.h
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PropertyGroupModel, CMDrawable, CanvasEditor, FrameTime, CMTransactionStack;

@interface PropertiesView : UIView

- (void)setDrawables:(NSArray<CMDrawable *> *)drawables withEditor:(CanvasEditor *)editor time:(FrameTime *)time transactionStack:(CMTransactionStack *)transactionStack;
- (void)reloadValues;

@end

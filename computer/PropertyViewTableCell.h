//
//  PropertyViewTableCell.h
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PropertyModel, CMDrawable, FrameTime, CMTransactionStack, CanvasEditor, EditorViewController;

@interface PropertyViewTableCell : UITableViewCell

- (void)setup;

@property (nonatomic) PropertyModel *model;
@property (nonatomic) NSArray<CMDrawable*> *drawables;
@property (nonatomic) FrameTime *time;
@property (nonatomic,readonly) CMTransactionStack *transactionStack;
@property (nonatomic) EditorViewController *editor;

- (void)reloadValue;
// @property (nonatomic,copy) void (^valueDidChange)(id value);
@property (nonatomic) id value;
- (void)saveValue:(id)value;

- (UIViewController *)viewControllerForModals;

+ (CGFloat)heightForModel:(PropertyModel *)model;

+ (CGFloat)standardInlineControlPadding;

@end

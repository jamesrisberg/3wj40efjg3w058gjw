//
//  PropertiesViewTable.h
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PropertyModel, CMDrawable, FrameTime, CMTransactionStack;

@interface PropertiesViewTable : UITableView

@property (nonatomic) __weak CMTransactionStack *transactionStack;
- (void)setProperties:(NSArray<PropertyModel*>*)properties onDrawables:(NSArray<CMDrawable*>*)drawables time:(FrameTime *)time;
- (void)reloadValues;
@property (nonatomic) BOOL singleView;

@end

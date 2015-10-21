//
//  OptionsView.h
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OptionsTableViewCell.h"

@interface OptionsViewCellModel : NSObject

@property (nonatomic) Class cellClass;
@property (nonatomic,copy) void (^onCreate)(OptionsTableViewCell *cell);
@property (nonatomic,copy) void (^onSelect)(OptionsTableViewCell *cell);

@end



@interface OptionsView : UIView

@property (nonatomic) UITableView *tableView;
@property (nonatomic) Drawable *drawable;
@property (nonatomic) CGFloat height;
@property (nonatomic,copy) void (^onDismiss)();
@property (nonatomic) UIBlurEffect *underlyingBlurEffect;
@property (nonatomic) NSArray *models;

@end

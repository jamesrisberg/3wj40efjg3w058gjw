//
//  SwipeMenuView.h
//  computer
//
//  Created by Nate Parrott on 11/18/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwipeMenuViewAction : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) UIImage *icon;
@property (nonatomic,copy) void(^action)();

@end



@interface SwipeMenuView : UIScrollView

@property (nonatomic) NSArray <__kindof SwipeMenuViewAction*> *actions;
@property (nonatomic) UIView *view;

@end

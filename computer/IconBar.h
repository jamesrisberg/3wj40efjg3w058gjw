//
//  IconBar.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EditorViewController;

@interface IconBar : UIView

@property (nonatomic,weak) EditorViewController *editor;
@property (nonatomic,copy) void (^onDoneButtonPressed)();
@property (nonatomic) BOOL isModalEditing; // TODO

@end

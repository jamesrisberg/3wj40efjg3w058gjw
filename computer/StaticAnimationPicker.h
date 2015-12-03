//
//  StaticAnimationPicker.h
//  computer
//
//  Created by Nate Parrott on 10/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class StaticAnimation;

@interface StaticAnimationPicker : UIView

@property (nonatomic) StaticAnimation *animation;
@property (nonatomic,copy) void (^animationDidChange)();

@end

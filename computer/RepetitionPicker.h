//
//  RepetitionPicker.h
//  computer
//
//  Created by Nate Parrott on 11/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RepetitionPicker : UIButton

@property (nonatomic) BOOL rebound;
@property (nonatomic) NSInteger repeatCount;

+ (RepetitionPicker *)picker;

@property (nonatomic,copy) void(^onChange)();

@end

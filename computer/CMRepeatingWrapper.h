//
//  CMRepeatingWrapper.h
//  computer
//
//  Created by Nate Parrott on 12/9/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"

@interface CMRepeatingWrapper : CMDrawableView

@property (nonatomic) NSInteger count;
@property (nonatomic) BOOL vertical;
@property (nonatomic) CGFloat gap;

@property (nonatomic) CMDrawableView *child; // set child AFTER configuring!

@end

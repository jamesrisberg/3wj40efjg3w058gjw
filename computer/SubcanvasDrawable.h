//
//  SubcanvasDrawable.h
//  computer
//
//  Created by Nate Parrott on 10/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"

@interface SubcanvasDrawable : Drawable

@property (nonatomic) Canvas *subcanvas;

@property (nonatomic) NSInteger xRepeat, yRepeat;

@end

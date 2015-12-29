//
//  DeleteKeyframeButton.h
//  computer
//
//  Created by Nate Parrott on 12/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeleteKeyframeButton : UIView

@property (nonatomic,copy) void (^onPress)();

@end

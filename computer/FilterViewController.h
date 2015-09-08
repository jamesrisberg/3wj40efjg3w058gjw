//
//  FilterViewController.h
//  computer
//
//  Created by Nate Parrott on 9/8/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilterViewController : UINavigationController

- (instancetype)initWithImage:(UIImage *)image callback:(void(^)(UIImage *filtered))callback;

@end

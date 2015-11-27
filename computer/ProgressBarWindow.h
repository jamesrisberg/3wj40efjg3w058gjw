//
//  ProgressBarWindow.h
//  computer
//
//  Created by Nate Parrott on 11/27/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressBarWindowItem : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) CGFloat progress;
@property (nonatomic) NSTimeInterval minDisplayTime;

@end




@interface ProgressBarWindow : UIWindow

+ (instancetype)shared;
- (void)addItems:(NSArray<ProgressBarWindowItem *> *)items;
- (void)removeItem:(ProgressBarWindowItem *)item;

@end

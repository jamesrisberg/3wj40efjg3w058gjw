//
//  TimelineView.h
//  computer
//
//  Created by Nate Parrott on 10/19/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimelineView : UIView

+ (CGFloat)height;
@property (nonatomic,readonly) NSTimeInterval time;
- (void)scrollToTime:(NSTimeInterval)time animated:(BOOL)animated;

@end

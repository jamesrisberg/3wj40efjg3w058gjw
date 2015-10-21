//
//  TimelineView.h
//  computer
//
//  Created by Nate Parrott on 10/19/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Keyframe.h"

@class TimelineView;

@protocol TimelineViewDelegate <NSObject>

- (void)timelineViewDidScroll:(TimelineView *)timelineView;
- (BOOL)timelineView:(TimelineView *)timelineView shouldIndicateKeyframesExistAtTime:(FrameTime *)time;

@end

@interface TimelineView : UIView

+ (CGFloat)height;
@property (nonatomic,readonly) NSTimeInterval time;
- (void)scrollToTime:(NSTimeInterval)time animated:(BOOL)animated;
- (FrameTime *)currentFrameTime; // alternate representation for self.time
@property (nonatomic,weak) id<TimelineViewDelegate> delegate;
- (void)keyframeAvailabilityUpdatedForTime:(FrameTime *)time; // time can be nil

@end

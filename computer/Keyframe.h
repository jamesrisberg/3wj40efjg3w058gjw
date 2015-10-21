//
//  Keyframe.h
//  computer
//
//  Created by Nate Parrott on 10/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FrameTime : NSObject <NSCoding>

// frameTime will be converted to lowest-common-denominator
- (instancetype)initWithFrame:(NSInteger)frame atFPS:(NSInteger)fps;

@property (nonatomic,readonly) NSInteger frame, fps;
- (NSTimeInterval)time;

@end

@interface Keyframe : NSObject <NSCoding>

- (instancetype)init;
@property (nonatomic) FrameTime *frameTime;
@property (nonatomic) NSMutableDictionary<__kindof NSString*, id> *properties;

@end

@interface KeyframeStore : NSObject <NSCoding>

- (void)storeKeyframe:(Keyframe *)keyframe;
- (Keyframe *)keyframeAtTime:(FrameTime *)time;
- (Keyframe *)keyframeBeforeTime:(FrameTime *)time;
- (Keyframe *)keyframeAfterTime:(FrameTime *)time;
- (NSDictionary<__kindof NSString*, id>*)interpolatedPropertiesAtTime:(FrameTime *)time;

@end

//
//  AnimatedExporter.m
//  computer
//
//  Created by Nate Parrott on 11/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "AnimatedExporter.h"
#import "Keyframe.h"

@implementation AnimatedExporter

- (void)enumerateFrameTimes:(void(^)(FrameTime *time))block {
    NSInteger numFramesPerRun = MAX(1, self.endTime.time * self.fps);
    for (NSInteger rep=0; rep<self.repeatCount; rep++) {
        NSArray *directions = self.rebound ? @[@(1), @(-1)] : @[@1];
        for (NSNumber *dir in directions) {
            NSInteger direction = dir.integerValue;
            for (NSInteger frame=0; frame<numFramesPerRun; frame++){
                NSInteger effectiveFrame = (direction == -1) ? (numFramesPerRun - 1 - frame) : frame;
                block([[FrameTime alloc] initWithFrame:effectiveFrame atFPS:self.fps]);
            }
        }
    }
}

@end

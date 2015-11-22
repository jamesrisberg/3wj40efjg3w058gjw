//
//  AnimatedExporter.h
//  computer
//
//  Created by Nate Parrott on 11/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Exporter.h"

@class FrameTime;

@interface AnimatedExporter : Exporter

@property (nonatomic) NSInteger fps;
@property (nonatomic) NSInteger repeatCount;
@property (nonatomic) BOOL rebound;
- (void)enumerateFrameTimes:(void(^)(FrameTime *time))block;

@end

//
//  Exporter.h
//  computer
//
//  Created by Nate Parrott on 10/24/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Canvas, FrameTime, EditorViewController;

@class Exporter;
@protocol ExporterDelegate <NSObject>

- (void)exporter:(Exporter *)exporter drawFrameAtTime:(FrameTime *)time inRect:(CGRect)drawIntoRect;
- (void)exporter:(Exporter *)exporter updateProgress:(double)progress;
- (void)exporterDidFinish:(Exporter *)exporter;

@end

@interface Exporter : NSObject

// these should be set by clients prior to -start
@property (nonatomic) CGSize canvasSize;
@property (nonatomic) CGRect cropRect; // in canvas coords
@property (nonatomic,weak) EditorViewController *parentViewController;
@property (nonatomic) FrameTime *defaultTime; // the time when this export was initiated
@property (nonatomic) FrameTime *endTime;
@property (nonatomic,weak) id<ExporterDelegate> delegate;

// for subclasses:
- (void)start;
- (void)_askDelegateToRenderFrame:(FrameTime *)time;
- (void)cancel;

@end

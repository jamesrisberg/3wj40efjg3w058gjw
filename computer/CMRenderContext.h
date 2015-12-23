//
//  CMRenderContext.h
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

@import UIKit;
@class FrameTime;
@class _CMCanvasView;
@class CMLayoutBase;

@interface CMRenderContext : NSObject <NSCopying>

@property (nonatomic) FrameTime *time;
@property (nonatomic) BOOL useFrameTimeForStaticAnimations;
@property (nonatomic) BOOL renderMetaInfo;
@property (nonatomic) BOOL forStaticScreenshot;
@property (nonatomic) id<UICoordinateSpace> coordinateSpace;
@property (nonatomic) CGPoint scale;
@property (nonatomic) _CMCanvasView *canvasView;
@property (nonatomic) CGSize canvasSize;
@property (nonatomic) BOOL atRoot; // the view that's been passed this context is the root
@property (nonatomic) NSDictionary<NSString*, CMLayoutBase*> *layoutBasesForObjectsWithKeys;

@end

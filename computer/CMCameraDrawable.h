//
//  CMCameraDrawable.h
//  computer
//
//  Created by Nate Parrott on 12/26/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"
#import "CanvasPosition.h"

@interface CMCameraDrawable : CMDrawable

@property (nonatomic) CGFloat aspectRatio;
- (CanvasPosition *)canvasPositionAtTime:(FrameTime *)time;

@end

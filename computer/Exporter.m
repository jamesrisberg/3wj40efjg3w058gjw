//
//  Exporter.m
//  computer
//
//  Created by Nate Parrott on 10/24/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Exporter.h"

@implementation Exporter

- (void)_askDelegateToRenderFrame:(FrameTime *)time {
    [self.delegate exporter:self drawFrameAtTime:time inRect:CGRectMake(-self.cropRect.origin.x, -self.cropRect.origin.y, self.canvasSize.width, self.canvasSize.height)];
}

- (void)start {
    
}

- (void)cancel {
    
}

@end

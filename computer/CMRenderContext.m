//
//  CMRenderContext.m
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMRenderContext.h"

@implementation CMRenderContext

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

- (id)copy {
    CMRenderContext *ctx = [CMRenderContext new];
    ctx.time = self.time;
    ctx.useFrameTimeForStaticAnimations = self.useFrameTimeForStaticAnimations;
    ctx.renderMetaInfo = self.renderMetaInfo;
    ctx.forStaticScreenshot = self.forStaticScreenshot;
    ctx.coordinateSpace = self.coordinateSpace;
    ctx.canvasView = self.canvasView;
    ctx.canvasSize = self.canvasSize;
    ctx.atRoot = self.atRoot;
    ctx.layoutBasesForObjectsWithKeys = self.layoutBasesForObjectsWithKeys;
    return ctx;
}

@end

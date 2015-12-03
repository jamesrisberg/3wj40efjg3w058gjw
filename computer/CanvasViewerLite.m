//
//  CanvasViewerLite.m
//  computer
//
//  Created by Nate Parrott on 12/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CanvasViewerLite.h"
#import "CMCanvas.h"
#import "Keyframe.h"

@interface CanvasViewerLite () {
    CADisplayLink *_displayLink;
    CMCanvas *_canvas;
}

@property (nonatomic) _CMCanvasView *canvasView;
@property (nonatomic) BOOL rendering;

@end

@implementation CanvasViewerLite

- (CMCanvas *)canvas {
    if (!_canvas) _canvas = [CMCanvas new];
    return _canvas;
}

- (void)setCanvas:(CMCanvas *)canvas {
    _canvas = canvas;
}

- (void)setCanvasView:(_CMCanvasView *)canvasView {
    [_canvasView removeFromSuperview];
    _canvasView = canvasView;
    [self addSubview:_canvasView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _canvasView.frame = self.bounds;
}

#pragma mark Rendering

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    self.rendering = !!newWindow;
}

- (void)setRendering:(BOOL)rendering {
    if (rendering != self.rendering) {
        if (rendering) {
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        } else {
            [_displayLink invalidate];
            _displayLink = nil;
        }
    }
}

- (BOOL)rendering {
    return !!_displayLink;
}

- (void)render {
    CMRenderContext *ctx = [CMRenderContext new];
    ctx.time = self.time ? : [[FrameTime alloc] initWithFrame:0 atFPS:1];
    ctx.renderMetaInfo = NO;
    ctx.useFrameTimeForStaticAnimations = NO;
    self.canvasView = (id)[self.canvas renderToView:self.canvasView context:ctx];
}

@end

//
//  CMCanvas.h
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

@import UIKit;
#import "CMDrawable.h"

@interface CMCanvas : CMDrawable

@property (nonatomic) NSMutableArray<__kindof CMDrawable*> *contents;

- (id<UICoordinateSpace>)childCoordinateSpace:(CMRenderContext *)ctx; // for subclasses like groups

- (CGRect)contentBoundingBox;

- (NSDictionary<NSString*,CMLayoutBase*>*)layoutBasesForContentsInRenderContext:(CMRenderContext *)ctx;

@end

@interface _CMCanvasView : CMDrawableView

- (NSArray<CMDrawable*> *)hitsAtPoint:(CGPoint)point withCanvas:(CMCanvas *)associatedCanvas;
- (NSArray<CMDrawable*> *)allItemsOverlappingDrawable:(CMDrawable *)d withCanvas:(CMCanvas *)associatedCanvas;
- (CMDrawableView *)viewForDrawable:(CMDrawable *)drawable;
- (NSArray<CMDrawableView*>*)allDrawableViews;

@end

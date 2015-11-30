//
//  CMCanvas.h
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMDrawable.h"

@interface CMCanvas : CMDrawable

@property (nonatomic) NSMutableArray<__kindof CMDrawable*> *contents;

@end

@interface _CMCanvasView : CMDrawableView

- (NSArray<CMDrawable*> *)hitsAtPoint:(CGPoint)point withCanvas:(CMCanvas *)associatedCanvas;
- (CMDrawableView *)viewForDrawable:(CMDrawable *)drawable;

@end

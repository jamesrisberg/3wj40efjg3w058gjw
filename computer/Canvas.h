//
//  Canvas.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Drawable, ShapeStackList;

@interface Canvas : UIView <NSCopying>

- (void)insertDrawable:(Drawable *)drawable;
@property (nonatomic) Drawable *selection;
@property (nonatomic,copy) void (^selectionRectNeedUpdate)();

@property (nonatomic, weak) ShapeStackList *editorShapeStackList;

@end

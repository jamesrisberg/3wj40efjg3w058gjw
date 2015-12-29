//
//  CMGroupDrawable.m
//  computer
//
//  Created by Nate Parrott on 12/16/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMGroupDrawable.h"
#import "PropertyViewTableCell.h"
#import "EditorViewController.h"

@implementation CMGroupDrawable

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Group", @"A group object");
}

- (CGFloat)aspectRatio {
    CGRect contentBounds = [self contentBoundingBox];
    return contentBounds.size.width / contentBounds.size.height;
}

- (id<UICoordinateSpace>)childCoordinateSpace:(CMRenderContext *)ctx {
    CGRect contentBounds = [self contentBoundingBox];
    
    CanvasCoordinateSpace *space = [CanvasCoordinateSpace new];
    space.canvasView = ctx.canvasView;
    space.screenSpan = contentBounds.size;
    space.center = CGPointMake(CGRectGetMidX(contentBounds), CGRectGetMidY(contentBounds));
    
    return space;
}

- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *buttons = [PropertyModel new];
    buttons.buttonSelectorNames = @[@"editGroup:"];
    buttons.buttonTitles = @[NSLocalizedString(@"Edit Group", nil)];
    buttons.type = PropertyModelTypeButtons;
    return [@[buttons] arrayByAddingObjectsFromArray:[super uniqueObjectPropertiesWithEditor:editor]];
}

- (void)editGroup:(PropertyViewTableCell *)cell {
    [self editGroupWithEditor:cell.editor];
}

- (void)editGroupWithEditor:(EditorViewController *)editor {
    __weak CMGroupDrawable *weakSelf = self;
    EditorViewController *editorVC = [EditorViewController modalEditorForCanvas:self callback:^(CMCanvas *edited) {
        [weakSelf.contents removeAllObjects];
        [weakSelf.contents addObjectsFromArray:edited.contents];
        if (self.contents.count == 0) {
            [editor.canvas deleteDrawable:weakSelf];
        }
    }];
    editorVC.editPrompt = NSLocalizedString(@"Edit Group", @"");
    [editor presentViewController:editorVC animated:YES completion:nil];
}

- (BOOL)performDefaultEditActionWithEditor:(EditorViewController *)editor {
    [self editGroupWithEditor:editor];
    return YES;
}

@end

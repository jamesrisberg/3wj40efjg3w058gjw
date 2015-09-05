//
//  TouchForwardingView.m
//  computer
//
//  Created by Nate Parrott on 9/5/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "TouchForwardingView.h"

@implementation TouchForwardingView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return [self.forwardToView hitTest:[self.forwardToView convertPoint:point fromView:self] withEvent:event] ? : self.forwardToView;
}

@end

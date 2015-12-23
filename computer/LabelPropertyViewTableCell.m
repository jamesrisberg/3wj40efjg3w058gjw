//
//  LabelPropertyViewTableCell.m
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "LabelPropertyViewTableCell.h"
#import "PropertyModel.h"

@implementation LabelPropertyViewTableCell

- (void)setModel:(PropertyModel *)model {
    [super setModel:model];
    self.textLabel.text = model.labelText;
    self.textLabel.font = [UIFont systemFontOfSize:13];
    self.textLabel.alpha = 0.7;
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.numberOfLines = 0;
    self.textLabel.textColor = [UIColor whiteColor];
}

@end

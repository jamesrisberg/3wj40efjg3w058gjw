//
//  OptionsCell.m
//  computer
//
//  Created by Nate Parrott on 11/11/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "OptionsCell.h"

@interface OptionsCell ()

@property (nonatomic) UILabel *textLabel;

@end

@implementation OptionsCell

- (instancetype)init {
    self = [super init];
    [self setup];
    return self;
}

- (void)setup {
    self.textLabel = [UILabel new];
    [self addSubview:self.textLabel];
    
    self.textLabel.textColor = [UIColor whiteColor];
    self.backgroundColor = [UIColor clearColor];
}


@end

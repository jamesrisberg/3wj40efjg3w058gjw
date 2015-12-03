//
//  PropertyModel.m
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "PropertyModel.h"
#import "ButtonsPropertyViewTableCell.h"
#import "SliderPropertyViewTableCell.h"

@implementation PropertyModel

- (Class)cellClass {
    if (_type == PropertyModelTypeSlider) {
        return [SliderPropertyViewTableCell class];
    } else if (_type == PropertyModelTypeButtons) {
        return [ButtonsPropertyViewTableCell class];
    } else {
        return [PropertyViewTableCell class];
    }
}

@end

@implementation PropertyGroupModel

@end

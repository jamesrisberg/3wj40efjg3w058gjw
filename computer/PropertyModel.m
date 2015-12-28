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
#import "StaticAnimationsPropertyTableViewCell.h"
#import "TextPropertyTableViewCell.h"
#import "FillPropertyTableViewCell.h"
#import "LabelPropertyViewTableCell.h"
#import "AnotherDrawablePropertyTableViewCell.h"
#import "computer-Swift.h"

@implementation PropertyModel

- (Class)cellClass {
    switch (_type) {
        case PropertyModelTypeSlider:
            return [SliderPropertyViewTableCell class];
            break;
        case PropertyModelTypeButtons:
            return [ButtonsPropertyViewTableCell class];
            break;
        case PropertyModelTypeStaticAnimation:
            return [StaticAnimationsPropertyTableViewCell class];
            break;
        case PropertyModelTypeLabel:
            return [LabelPropertyViewTableCell class];
            break;
        case PropertyModelTypeAnotherDrawable:
            return [AnotherDrawablePropertyTableViewCell class];
            break;
        case PropertyModelTypeColor:
            return [FillPropertyTableViewCell class];
            break;
        case PropertyModelTypeFill:
            return [FillPropertyTableViewCell class];
            break;
        case PropertyModelTypeParticleImages:
            return [ParticlesPickerPropertyTableViewCell class];
            break;
        case PropertyModelTypeText:
            return [TextPropertyTableViewCell class];
            break;
        default:
            return [PropertyViewTableCell class];
            break;
    }
}

@end

@implementation PropertyGroupModel

@end

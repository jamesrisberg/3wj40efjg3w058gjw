//
//  PropertyModel.h
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, PropertyModelType) {
    PropertyModelTypeSlider,
    PropertyModelTypeButtons,
    PropertyModelTypeFill,
    PropertyModelTypeColor
};

@interface PropertyModel : NSObject

@property (nonatomic) PropertyModelType type;
@property (nonatomic) NSString *title;

@property (nonatomic) NSString *key;
@property (nonatomic) BOOL isKeyframeProperty;

// for PropertyModelTypeSlider
@property (nonatomic) CGFloat valueMin, valueMax;

// for PropertyModelTypeButtons
@property (nonatomic) NSArray<NSString*> *buttonTitles;
@property (nonatomic) NSArray<NSString*> *buttonSelectorNames;
@property (nonatomic) NSArray<NSString*> *availabilitySelectors; // called to determine if buttons should be enabled

- (Class)cellClass;

@end

@interface PropertyGroupModel : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSArray<PropertyModel*> *properties;

@end

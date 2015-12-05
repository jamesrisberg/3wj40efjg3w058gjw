//
//  CMTextDrawable.m
//  computer
//
//  Created by Nate Parrott on 12/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMTextDrawable.h"
#import <ReactiveCocoa.h>
#import "NSAttributedString+ResizeToFit.h"

@interface _CMTextDrawableView : CMDrawableView

@property (nonatomic) NSAttributedString *attributedString;
@property (nonatomic) UILabel *label;
@property (nonatomic) CGFloat textStart, textEnd;
@property (nonatomic) NSAttributedString *fittedAttributedString;

@end

@implementation _CMTextDrawableView

- (instancetype)init {
    self = [super init];
    
    self.label = [UILabel new];
    self.label.numberOfLines = 0;
    [self addSubview:self.label];
    
    RAC(self.label, attributedText) = [RACSignal combineLatest:@[RACObserve(self, fittedAttributedString), RACObserve(self, textStart), RACObserve(self, textEnd)] reduce:^id(NSAttributedString *string, NSNumber *startNum, NSNumber *endNum){
        NSInteger startIndex = string.length * startNum.floatValue;
        NSInteger endIndex = string.length * endNum.floatValue;
        NSMutableAttributedString *blanked = string.mutableCopy;
        [blanked addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:NSMakeRange(0, startIndex)];
        [blanked addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:NSMakeRange(endIndex, blanked.length - endIndex)];
        return blanked;
    }];
    
    return self;
}

+ (NSAttributedString *)defaultAttributedStringWithText:(NSString *)text {
    NSMutableParagraphStyle *para = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    para.alignment = NSTextAlignmentCenter;
    NSDictionary *defaultAttrs = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:20], NSForegroundColorAttributeName: [UIColor blackColor], NSParagraphStyleAttributeName: para};
    return [[NSAttributedString alloc] initWithString:text attributes:defaultAttrs];
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
    if ([_attributedString isEqualToAttributedString:attributedString]) return;
    _attributedString = attributedString;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = self.bounds;
    if (self.attributedString.length > 0) {
        self.fittedAttributedString = [self.attributedString resizeToFitInside:self.bounds.size];
    }
}

@end

@implementation CMTextDrawable

- (CMDrawableView *)renderToView:(__kindof CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx {
    _CMTextDrawableView *v = (id)([existingOrNil isKindOfClass:[_CMTextDrawableView class]] ? existingOrNil : [_CMTextDrawableView new]);
    v = [super renderToView:v context:ctx];
    CMTextDrawableKeyframe *keyframe = [self.keyframeStore interpolatedKeyframeAtTime:ctx.time];
    v.attributedString = self.text;
    v.textStart = keyframe.textStart;
    v.textEnd = keyframe.textEnd;
    return v;
}

- (Class)keyframeClass {
    return [CMTextDrawableKeyframe class];
}

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"text", @"aspectRatio"]];
}

- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *text = [PropertyModel new];
    text.key = @"text";
    text.type = PropertyModelTypeText;
    text.title = NSLocalizedString(@"Text", @"");
    return [@[text] arrayByAddingObjectsFromArray:[super uniqueObjectPropertiesWithEditor:editor]];
}

- (NSArray<PropertyModel*>*)animatablePropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *textStart = [PropertyModel new];
    textStart.key = @"textStart";
    textStart.title = NSLocalizedString(@"Text typing start", @"");
    
    PropertyModel *textEnd = [PropertyModel new];
    textEnd.key = @"textEnd";
    textEnd.title = NSLocalizedString(@"Text typing end", @"");
    
    for (PropertyModel *m in @[textStart, textEnd]) {
        m.isKeyframeProperty = YES;
        m.type = PropertyModelTypeSlider;
        m.valueMax = 1;
    }
    
    return [@[textStart, textEnd] arrayByAddingObjectsFromArray:[super animatablePropertiesWithEditor:editor]];
}

@end


@implementation CMTextDrawableKeyframe

- (instancetype)init {
    self = [super init];
    self.textEnd = 1;
    return self;
}

- (NSArray<NSString*>*)keys {
    return [[super keys] arrayByAddingObjectsFromArray:@[@"textStart", @"textEnd"]];
}

@end

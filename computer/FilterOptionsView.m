//
//  FilterOptionsView.m
//  computer
//
//  Created by Nate Parrott on 11/26/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilterOptionsView.h"
#import "ConvenienceCategories.h"
#import "CMPhotoPicker.h"

@interface FilterOptionsView ()

@property (nonatomic) FilterPickerFilterInfo *filterInfo;
@property (nonatomic) GPUImageOutput<GPUImageInput> *filter;

@property (nonatomic) FilterParameter *mainSliderParam, *mainPointParam;
@property (nonatomic) FilterParameter *colorFromImageParam;

@end

@implementation FilterOptionsView

- (void)setFilter:(GPUImageOutput<GPUImageInput> *)filter info:(FilterPickerFilterInfo *)info {
    _filter = filter;
    _filterInfo = info;
    
    NSMutableDictionary *paramsByType = [NSMutableDictionary new];
    for (FilterParameter *p in info.parameters) {
        if (!paramsByType[@(p.type)]) paramsByType[@(p.type)] = [NSMutableArray new];
        [paramsByType[@(p.type)] addObject:p];
    }
    
    self.mainSliderParam = [paramsByType[@(FilterParameterTypeFloat)] firstObject];
    self.mainPointParam = [paramsByType[@(FilterParameterTypePoint)] firstObject];
    self.colorFromImageParam = [paramsByType[@(FilterParameterTypeColorPickedFromImage)] firstObject];
    
    self.action.hidden = YES;
    [self.action removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    if (info.hasSecondaryInput) {
        self.action.hidden = NO;
        [self.action setTitle:NSLocalizedString(@"Change Background", @"") forState:UIControlStateNormal];
        [self.action addTarget:self action:@selector(changeSecondaryInputImage) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.action sizeToFit];
    self.action.frame = CGRectMake(self.action.frame.origin.x, self.action.frame.origin.y, self.action.frame.size.width + 20, self.action.frame.size.height + 20);
}

- (void)setMainSliderParam:(FilterParameter *)mainSliderParam {
    _mainSliderParam = mainSliderParam;
    self.mainSlider.hidden = !mainSliderParam;
    if (mainSliderParam) {
        self.mainSlider.minimumValue = mainSliderParam.min;
        self.mainSlider.maximumValue = mainSliderParam.max;
        self.mainSlider.value = [[self.filter valueForKey:mainSliderParam.key] floatValue];
    }
}

- (IBAction)mainSliderChanged:(id)sender {
    if (self.mainSliderParam) {
        [self.filter setValue:@(self.mainSlider.value) forKey:self.mainSliderParam.key];
        self.onChange();
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchedAtPoint:[touches.anyObject locationInView:self]];
    if (self.colorFromImageParam) {
        self.getColorAtPointBlock([touches.anyObject locationInView:self], ^(UIColor *color){
            [self.filter setValue:color forKey:self.colorFromImageParam.key];
            self.onChange();
        });
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchedAtPoint:[touches.anyObject locationInView:self]];
}

- (void)touchedAtPoint:(CGPoint)point {
    if (self.mainPointParam) {
        CGPoint p = self.transformPointIntoImageCoordinates(point);
        [self.filter setValue:[NSValue valueWithCGPoint:p] forKey:self.mainPointParam.key];
        self.onChange();
    }
}

- (void)changeSecondaryInputImage {
    CMPhotoPicker *picker = [CMPhotoPicker photoPicker];
    __weak FilterOptionsView *weakSelf = self;
    picker.snapshotViews = self.snapshotsForImagePicker;
    picker.imageCallback = ^(UIImage *image) {
        weakSelf.onChangeSecondaryInputImage(image);
    };
    [picker present];
}

@end

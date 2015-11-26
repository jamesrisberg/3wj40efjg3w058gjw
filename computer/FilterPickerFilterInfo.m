//
//  FilterPickerFilterInfo.m
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilterPickerFilterInfo.h"

@implementation FilterParameter

@end



@interface FilterPickerFilterInfo ()

@property (nonatomic,copy) GPUImageOutput<GPUImageInput>*(^filterBlock)();

@end

@implementation FilterPickerFilterInfo

+ (NSArray<__kindof FilterPickerFilterInfo*>*)allFilters {
    FilterPickerFilterInfo *noFilter = [FilterPickerFilterInfo new];
    [noFilter setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageFilter new];
    }];
    
    FilterPickerFilterInfo *brightness = [FilterPickerFilterInfo new];
    [brightness setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageBrightnessFilter *f = [GPUImageBrightnessFilter new];
        f.brightness = 0.67;
        return f;
    }];
    [brightness addSliderForKey:@"brightness" min:0 max:1 name:NSLocalizedString(@"Brightness", @"")];
    
    FilterPickerFilterInfo *sat = [FilterPickerFilterInfo new];
    [sat setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageSaturationFilter *s = [GPUImageSaturationFilter new];
        s.saturation = 0;
        return s;
    }];
    [sat addSliderForKey:@"saturation" min:0 max:1 name:NSLocalizedString(@"Saturation", @"")];
    
    FilterPickerFilterInfo *contrast = [FilterPickerFilterInfo new];
    [contrast setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageContrastFilter *c = [GPUImageContrastFilter new];
        c.contrast = 2;
        return c;
    }];
    [contrast addSliderForKey:@"contrast" min:0 max:4 name:NSLocalizedString(@"Contrast", @"")];
    
    FilterPickerFilterInfo *exp = [FilterPickerFilterInfo new];
    [exp setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageExposureFilter *f = [GPUImageExposureFilter new];
        f.exposure = 0.7;
        return f;
    }];
    [exp addSliderForKey:@"exposure" min:-10 max:10 name:NSLocalizedString(@"Exposure", @"")];
    
    FilterPickerFilterInfo *hue = [FilterPickerFilterInfo new];
    [hue setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageHueFilter *h = [GPUImageHueFilter new];
        return h;
    }];
    [hue addSliderForKey:@"hue" min:0 max:360 name:NSLocalizedString(@"Hue", @"")];
    
    FilterPickerFilterInfo *whiteBalance = [FilterPickerFilterInfo new];
    [whiteBalance setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageWhiteBalanceFilter *wb = [GPUImageWhiteBalanceFilter new];
        return wb;
    }];
    // TODO
    
    FilterPickerFilterInfo *colorize = [FilterPickerFilterInfo new];
    [colorize setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageMonochromeFilter *m = [GPUImageMonochromeFilter new];
        return m;
    }];
    [colorize addSliderForKey:@"intensity" min:0 max:1 name:NSLocalizedString(@"Intensity", @"")];
    [colorize addColorPickerForKey:@"color" name:@"color"];
    
    FilterPickerFilterInfo *blur = [FilterPickerFilterInfo new];
    [blur setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageGaussianBlurFilter new];
    }];
    [blur addSliderForKey:@"blurRadiusInPixels" min:3 max:13 name:@"Radius"];
    
    FilterPickerFilterInfo *gradientMap = [FilterPickerFilterInfo new];
    [gradientMap setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageFalseColorFilter *fc = [GPUImageFalseColorFilter new];
        return fc;
    }];
    [gradientMap addColorPickerForKey:@"firstColor" name:NSLocalizedString(@"Dark color", @"")];
    [gradientMap addColorPickerForKey:@"secondColor" name:NSLocalizedString(@"Light color", @"")];
    
    FilterPickerFilterInfo *sharpen = [FilterPickerFilterInfo new];
    [sharpen setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageSharpenFilter *sharpen = [GPUImageSharpenFilter new];
        return sharpen;
    }];
    [sharpen addSliderForKey:@"sharpness" min:-4 max:4 name:@"Sharpness"];
    
    FilterPickerFilterInfo *toon = [FilterPickerFilterInfo new];
    [toon setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageToonFilter new];
    }];
    [toon addSliderForKey:@"threshold" min:0 max:1 name:NSLocalizedString(@"Threshold", @"")];
    [toon addSliderForKey:@"quantizationLevels" min:5 max:60 name:NSLocalizedString(@"# of colors", @"")];
    
    FilterPickerFilterInfo *unsharp = [FilterPickerFilterInfo new];
    [unsharp setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageUnsharpMaskFilter *u = [GPUImageUnsharpMaskFilter new];
        return u;
    }];
    [unsharp addSliderForKey:@"blurRadiusInPixels" min:3 max:13 name:@"Blur radius"];
    [unsharp addSliderForKey:@"intensity" min:0 max:1 name:NSLocalizedString(@"Intensity", @"")];
    
    FilterPickerFilterInfo *gamma = [FilterPickerFilterInfo new];
    [gamma setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageGammaFilter *g = [GPUImageGammaFilter new];
        return g;
    }];
    [gamma addSliderForKey:@"gamma" min:0 max:3 name:NSLocalizedString(@"Gamma", @"")];
    
    FilterPickerFilterInfo *haze = [FilterPickerFilterInfo new];
    [haze setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImageHazeFilter *haze = [GPUImageHazeFilter new];
        return haze;
    }];
    [haze addSliderForKey:@"distance" min:-0.5 max:0.5 name:NSLocalizedString(@"Distance", @"")];
    [haze addSliderForKey:@"slope" min:-0.5 max:0.5 name:NSLocalizedString(@"Slope", @"")];
    
    FilterPickerFilterInfo *pixellate = [FilterPickerFilterInfo new];
    [pixellate setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        GPUImagePixellateFilter *pix = [GPUImagePixellateFilter new];
        return pix;
    }];
    [pixellate addSliderForKey:@"fractionalWidthOfAPixel" min:0.001 max:0.3 name:NSLocalizedString(@"Size", @"")];
    
    FilterPickerFilterInfo *invert = [FilterPickerFilterInfo new];
    [invert setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageColorInvertFilter new];
    }];
    
    FilterPickerFilterInfo *luminanceThreshold = [FilterPickerFilterInfo new];
    [luminanceThreshold setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageLuminanceThresholdFilter new];
    }];
    
    FilterPickerFilterInfo *adaptiveThreshold = [FilterPickerFilterInfo new];
    [adaptiveThreshold setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageAdaptiveThresholdFilter new];
    }];
    
    FilterPickerFilterInfo *avgLuminance = [FilterPickerFilterInfo new];
    [avgLuminance setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageAverageLuminanceThresholdFilter new];
    }];
    
    FilterPickerFilterInfo *polarPix = [FilterPickerFilterInfo new];
    [polarPix setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImagePolarPixellateFilter new];
    }];
    
    FilterPickerFilterInfo *polka = [FilterPickerFilterInfo new];
    [polka setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImagePolkaDotFilter new];
    }];
    
    FilterPickerFilterInfo *halftone = [FilterPickerFilterInfo new];
    [halftone setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageHalftoneFilter new];
    }];
    
    FilterPickerFilterInfo *crosshatch = [FilterPickerFilterInfo new];
    [crosshatch setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageCrosshatchFilter new];
    }];
    
    FilterPickerFilterInfo *sobel = [FilterPickerFilterInfo new];
    [sobel setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageSobelEdgeDetectionFilter new];
    }];
    
    FilterPickerFilterInfo *canny = [FilterPickerFilterInfo new];
    [canny setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageCannyEdgeDetectionFilter new];
    }];
    
    FilterPickerFilterInfo *xy = [FilterPickerFilterInfo new];
    [xy setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageXYDerivativeFilter new];
    }];
    
    FilterPickerFilterInfo *sketch = [FilterPickerFilterInfo new];
    [sketch setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageSketchFilter new];
    }];
    
    FilterPickerFilterInfo *tilt = [FilterPickerFilterInfo new];
    [tilt setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageTiltShiftFilter new];
    }];
    
    FilterPickerFilterInfo *cga = [FilterPickerFilterInfo new];
    [cga setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageCGAColorspaceFilter new];
    }];
    
    FilterPickerFilterInfo *post = [FilterPickerFilterInfo new];
    [post setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImagePosterizeFilter new];
    }];
    
    FilterPickerFilterInfo *emboss = [FilterPickerFilterInfo new];
    [emboss setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageEmbossFilter new];
    }];
    
    FilterPickerFilterInfo *kuwuhara = [FilterPickerFilterInfo new];
    [kuwuhara setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageKuwaharaFilter new];
    }];
    
    FilterPickerFilterInfo *vignette = [FilterPickerFilterInfo new];
    [vignette setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageVignetteFilter new];
    }];
    
    FilterPickerFilterInfo *motion = [FilterPickerFilterInfo new];
    [motion setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageMotionBlurFilter new];
    }];
    
    FilterPickerFilterInfo *zoom = [FilterPickerFilterInfo new];
    [zoom setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageZoomBlurFilter new];
    }];
    
    FilterPickerFilterInfo *swirl = [FilterPickerFilterInfo new];
    [swirl setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageSwirlFilter new];
    }];
    
    FilterPickerFilterInfo *bulge = [FilterPickerFilterInfo new];
    [bulge setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageBulgeDistortionFilter new];
    }];
    
    FilterPickerFilterInfo *pinch = [FilterPickerFilterInfo new];
    [pinch setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImagePinchDistortionFilter new];
    }];
    
    FilterPickerFilterInfo *stretch = [FilterPickerFilterInfo new];
    [stretch setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageStretchDistortionFilter new];
    }];
    
    FilterPickerFilterInfo *dilate = [FilterPickerFilterInfo new];
    [dilate setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageDilationFilter new];
    }];
    
    FilterPickerFilterInfo *erode = [FilterPickerFilterInfo new];
    [erode setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageErosionFilter new];
    }];
    
    FilterPickerFilterInfo *localBinary = [FilterPickerFilterInfo new];
    [localBinary setFilterBlock:^GPUImageOutput<GPUImageInput> *{
        return [GPUImageLocalBinaryPatternFilter new];
    }];
    
    return @[noFilter, brightness, invert, sat, exp, hue, gradientMap, colorize, gamma, contrast, unsharp, blur, sharpen, toon, pixellate, whiteBalance, haze, localBinary, erode, dilate, stretch, pinch, bulge, swirl, zoom, motion, vignette, kuwuhara, emboss, post, cga, tilt, sketch, xy, canny, sobel, crosshatch, halftone, polka, polarPix, avgLuminance, luminanceThreshold, adaptiveThreshold];
}

- (instancetype)init {
    self = [super init];
    _parameters = [NSMutableArray new];
    return self;
}

- (void)addSliderForKey:(NSString *)key min:(CGFloat)min max:(CGFloat)max name:(NSString *)name {
    FilterParameter *p = [FilterParameter new];
    p.key = key;
    p.name = name;
    p.min = min;
    p.max = max;
    p.type = FilterParameterTypeFloat;
    [self.parameters addObject:p];
}

- (void)addColorPickerForKey:(NSString *)key name:(NSString *)name {
    FilterParameter *p = [FilterParameter new];
    p.key = key;
    p.name = name;
    p.type = FilterParameterTypeColor;
    [self.parameters addObject:p];
}

- (GPUImageOutput<GPUImageInput> *)createFilter {
    return self.filterBlock();
}

@end

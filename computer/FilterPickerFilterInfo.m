//
//  FilterPickerFilterInfo.m
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilterPickerFilterInfo.h"
#import "CMGreenScreenFilter.h"
#import "ConvenienceCategories.h"

typedef void (^FilterInfoConfigurationBlock)(FilterPickerFilterInfo *filter);

@implementation FilterParameter

@end



@interface FilterPickerFilterInfo ()

@property (nonatomic) NSString *identifier;
@property (nonatomic,copy) GPUImageOutput<GPUImageInput>*(^filterBlock)();

@end

@implementation FilterPickerFilterInfo

+ (NSArray<__kindof FilterPickerFilterInfo*>*)allFilters {
    return [[[self class] filterIDs] map:^id(id obj) {
        return [[FilterPickerFilterInfo alloc] initWithID:obj];
    }];
}

- (instancetype)initWithID:(NSString *)identifier {
    self = [super init];
    _parameterValues = [NSMutableDictionary new];
    self.identifier = identifier;
    _parameters = [NSMutableArray new];
    FilterInfoConfigurationBlock b = [[self class] filtersByID][identifier];
    b(self);
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self initWithID:[aDecoder decodeObjectForKey:@"ID"]];
    _parameterValues = [aDecoder decodeObjectForKey:@"parameterValues"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.identifier forKey:@"ID"];
    [aCoder encodeObject:self.parameterValues forKey:@"parameterValues"];
}

+ (NSDictionary *)filtersByID {
    static NSDictionary *d;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        d =     @{
                  @"noFilter": ^(FilterPickerFilterInfo *noFilter) {
                      [noFilter setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageFilter new];
                      }];
                  },
                  @"brightness": ^(FilterPickerFilterInfo *brightness) {
                      [brightness setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageBrightnessFilter *f = [GPUImageBrightnessFilter new];
                          f.brightness = 0.67;
                          return f;
                      }];
                      [brightness addSliderForKey:@"brightness" min:0 max:1 name:NSLocalizedString(@"Brightness", @"")];
                      brightness.name = NSLocalizedString(@"Brightness", @"");
                  },
                  @"sat": ^(FilterPickerFilterInfo *sat) {
                      [sat setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageSaturationFilter *s = [GPUImageSaturationFilter new];
                          s.saturation = 0;
                          return s;
                      }];
                      [sat addSliderForKey:@"saturation" min:0 max:1 name:NSLocalizedString(@"Saturation", @"")];
                      sat.name = NSLocalizedString(@"Saturation", @"");
                  },
                  @"contrast": ^(FilterPickerFilterInfo *contrast) {
                      [contrast setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageContrastFilter *c = [GPUImageContrastFilter new];
                          c.contrast = 2;
                          return c;
                      }];
                      [contrast addSliderForKey:@"contrast" min:0 max:4 name:NSLocalizedString(@"Contrast", @"")];
                      contrast.name = NSLocalizedString(@"Contrast", @"");
                  },
                  @"exp": ^(FilterPickerFilterInfo *exp) {
                      [exp setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageExposureFilter *f = [GPUImageExposureFilter new];
                          f.exposure = 0.7;
                          return f;
                      }];
                      [exp addSliderForKey:@"exposure" min:-10 max:10 name:NSLocalizedString(@"Exposure", @"")];
                  },
                  @"hue": ^(FilterPickerFilterInfo *hue) {
                      [hue setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageHueFilter *h = [GPUImageHueFilter new];
                          return h;
                      }];
                      [hue addSliderForKey:@"hue" min:0 max:360 name:NSLocalizedString(@"Hue", @"")];
                  },
                  @"whiteBalance": ^(FilterPickerFilterInfo *whiteBalance) {
                      [whiteBalance setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageWhiteBalanceFilter *wb = [GPUImageWhiteBalanceFilter new];
                          return wb;
                      }];
                      // TODO
                  },
                  @"colorize": ^(FilterPickerFilterInfo *colorize) {
                      [colorize setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageMonochromeFilter *m = [GPUImageMonochromeFilter new];
                          return m;
                      }];
                      [colorize addSliderForKey:@"intensity" min:0 max:1 name:NSLocalizedString(@"Intensity", @"")];
                      [colorize addColorPickerForKey:@"color" name:@"color"];
                  },
                  @"blur": ^(FilterPickerFilterInfo *blur) {
                      [blur setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageGaussianBlurFilter new];
                      }];
                      [blur addSliderForKey:@"blurRadiusInPixels" min:3 max:13 name:@"Radius"];
                  },
                  @"gradientMap": ^(FilterPickerFilterInfo *gradientMap) {
                      [gradientMap setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageFalseColorFilter *fc = [GPUImageFalseColorFilter new];
                          return fc;
                      }];
                      [gradientMap addColorPickerForKey:@"firstColor" name:NSLocalizedString(@"Dark color", @"")];
                      [gradientMap addColorPickerForKey:@"secondColor" name:NSLocalizedString(@"Light color", @"")];
                  },
                  @"sharpen": ^(FilterPickerFilterInfo *sharpen) {
                      [sharpen setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageSharpenFilter *sharpen = [GPUImageSharpenFilter new];
                          return sharpen;
                      }];
                      [sharpen addSliderForKey:@"sharpness" min:-4 max:4 name:@"Sharpness"];
                  },
                  @"toon": ^(FilterPickerFilterInfo *toon) {
                      [toon setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageToonFilter new];
                      }];
                      [toon addSliderForKey:@"threshold" min:0 max:1 name:NSLocalizedString(@"Threshold", @"")];
                      [toon addSliderForKey:@"quantizationLevels" min:5 max:60 name:NSLocalizedString(@"# of colors", @"")];
                  },
                  @"unsharp": ^(FilterPickerFilterInfo *unsharp) {
                      [unsharp setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageUnsharpMaskFilter *u = [GPUImageUnsharpMaskFilter new];
                          return u;
                      }];
                      [unsharp addSliderForKey:@"blurRadiusInPixels" min:3 max:13 name:@"Blur radius"];
                      [unsharp addSliderForKey:@"intensity" min:0 max:1 name:NSLocalizedString(@"Intensity", @"")];
                  },
                  @"gamma": ^(FilterPickerFilterInfo *gamma) {
                      [gamma setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageGammaFilter *g = [GPUImageGammaFilter new];
                          return g;
                      }];
                      [gamma addSliderForKey:@"gamma" min:0 max:3 name:NSLocalizedString(@"Gamma", @"")];
                  },
                  @"haze": ^(FilterPickerFilterInfo *haze) {
                      [haze setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageHazeFilter *haze = [GPUImageHazeFilter new];
                          return haze;
                      }];
                      [haze addSliderForKey:@"distance" min:-0.5 max:0.5 name:NSLocalizedString(@"Distance", @"")];
                      [haze addSliderForKey:@"slope" min:-0.5 max:0.5 name:NSLocalizedString(@"Slope", @"")];
                  },
                  @"pixellate":^(FilterPickerFilterInfo *pixellate) {
                      [pixellate setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImagePixellateFilter *pix = [GPUImagePixellateFilter new];
                          return pix;
                      }];
                      [pixellate addSliderForKey:@"fractionalWidthOfAPixel" min:0.001 max:0.3 name:NSLocalizedString(@"Size", @"")];
                  },
                  @"invert": ^(FilterPickerFilterInfo *invert) {
                      [invert setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageColorInvertFilter new];
                      }];
                  },
                  @"luminanceThreshold": ^(FilterPickerFilterInfo *luminanceThreshold) {
                      [luminanceThreshold setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageLuminanceThresholdFilter new];
                      }];
                      [luminanceThreshold addSliderForKey:@"threshold" min:0 max:1 name:NSLocalizedString(@"Threshold", @"")];
                  },
                  @"adaptiveThreshold": ^(FilterPickerFilterInfo *adaptiveThreshold) {
                      [adaptiveThreshold setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageAdaptiveThresholdFilter new];
                      }];
                      [adaptiveThreshold addSliderForKey:@"blurRadiusInPixels" min:1 max:13 name:NSLocalizedString(@"Blur radius", @"")];
                  },
                  @"avgLuminance": ^(FilterPickerFilterInfo *avgLuminance) {
                      [avgLuminance setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageAverageLuminanceThresholdFilter new];
                      }];
                      [avgLuminance addSliderForKey:@"thresholdMultiplier" min:0 max:4 name:NSLocalizedString(@"Multiplier", @"")];
                  },
                  @"polarPix": ^(FilterPickerFilterInfo *polarPix) {
                      [polarPix setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImagePolarPixellateFilter new];
                      }];
                      [polarPix addPointPickerForKey:@"center" name:NSLocalizedString(@"Center", @"")];
                  },
                  @"polka": ^(FilterPickerFilterInfo *polka) {
                      [polka setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImagePolkaDotFilter new];
                      }];
                      [polka addSliderForKey:@"dotScaling" min:0.05 max:3 name:NSLocalizedString(@"Dot size", @"")];
                  },
                  @"halftone": ^(FilterPickerFilterInfo *halftone) {
                      [halftone setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageHalftoneFilter new];
                      }];
                      [halftone addSliderForKey:@"fractionalWidthOfAPixel" min:0.001 max:0.3 name:NSLocalizedString(@"Size", @"")];
                  },
                  @"crosshatch": ^(FilterPickerFilterInfo *crosshatch) {
                      [crosshatch setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageCrosshatchFilter new];
                      }];
                      [crosshatch addSliderForKey:@"crossHatchSpacing" min:0.01 max:1 name:NSLocalizedString(@"Spacing", @"")];
                      [crosshatch addSliderForKey:@"lineWidth" min:0.001 max:1 name:NSLocalizedString(@"Line width", @"")];
                  },
                  @"sobel": ^(FilterPickerFilterInfo *sobel) {
                      [sobel setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageSobelEdgeDetectionFilter new];
                      }];
                      [sobel addSliderForKey:@"edgeStrength" min:0.1 max:3 name:NSLocalizedString(@"Edge strength", @"")];
                      // TODO: more props.
                  },
                  @"canny": ^(FilterPickerFilterInfo *canny) {
                      [canny setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageCannyEdgeDetectionFilter new];
                      }];
                      // TODO
                  },
                  @"xy": ^(FilterPickerFilterInfo *xy) {
                      [xy setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageXYDerivativeFilter new];
                      }];
                  },
                  @"sketch": ^(FilterPickerFilterInfo *sketch) {
                      [sketch setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageSketchFilter new];
                      }];
                  },
                  @"tilt": ^(FilterPickerFilterInfo *tilt) {
                      [tilt setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageTiltShiftFilter new];
                      }];
                      [tilt addSliderForKey:@"blurRadiusInPixels" min:2 max:13 name:NSLocalizedString(@"Blur radius", @"")];
                      // TODO: more props
                  },
                  @"cga": ^(FilterPickerFilterInfo *cga) {
                      [cga setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageCGAColorspaceFilter new];
                      }];
                  },
                  @"post": ^(FilterPickerFilterInfo *post) {
                      [post setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImagePosterizeFilter new];
                      }];
                      [post addSliderForKey:@"colorLevels" min:1 max:256 name:NSLocalizedString(@"Color levels", @"")];
                  },
                  @"emboss": ^(FilterPickerFilterInfo *emboss) {
                      [emboss setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageEmbossFilter new];
                      }];
                      [emboss addSliderForKey:@"intensity" min:0 max:4 name:NSLocalizedString(@"Intensity", @"")];
                  },
                  @"kuwuhara": ^(FilterPickerFilterInfo *kuwuhara) {
                      [kuwuhara setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageKuwaharaFilter new];
                      }];
                      [kuwuhara addSliderForKey:@"radius" min:1 max:9 name:NSLocalizedString(@"Radius", @"")];
                  },
                  @"vignette": ^(FilterPickerFilterInfo *vignette) {
                      [vignette setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageVignetteFilter new];
                      }];
                      [vignette addColorPickerForKey:@"vignetteColor" name:NSLocalizedString(@"Color", @"")];
                      [vignette addPointPickerForKey:@"vignetteCenter" name:NSLocalizedString(@"Center", @"")];
                      // TODO: more props
                  },
                  @"motion": ^(FilterPickerFilterInfo *motion) {
                      [motion setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageMotionBlurFilter new];
                      }];
                  },
                  @"zoom": ^(FilterPickerFilterInfo *zoom) {
                      [zoom setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageZoomBlurFilter new];
                      }];
                      [zoom addSliderForKey:@"blurSize" min:0 max:4 name:NSLocalizedString(@"Blur size", @"")];
                      [zoom addPointPickerForKey:@"blurCenter" name:NSLocalizedString(@"Center", @"")];
                  },
                  @"swirl": ^(FilterPickerFilterInfo *swirl) {
                      [swirl setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageSwirlFilter new];
                      }];
                      [swirl addSliderForKey:@"angle" min:0 max:4 name:NSLocalizedString(@"Angle", @"")];
                      [swirl addSliderForKey:@"radius" min:0 max:1 name:NSLocalizedString(@"Radius", @"")];
                      [swirl addPointPickerForKey:@"center" name:NSLocalizedString(@"Center", @"")];
                  },
                  @"bulge": ^(FilterPickerFilterInfo *bulge) {
                      [bulge setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageBulgeDistortionFilter new];
                      }];
                      [bulge addSliderForKey:@"radius" min:0 max:1 name:NSLocalizedString(@"Radius", @"")];
                      [bulge addSliderForKey:@"scale" min:-1 max:1 name:NSLocalizedString(@"Scale", @"")];
                      [bulge addPointPickerForKey:@"center" name:NSLocalizedString(@"Center", @"")];
                  },
                  @"pinch": ^(FilterPickerFilterInfo *pinch) {
                      [pinch setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImagePinchDistortionFilter new];
                      }];
                      [pinch addSliderForKey:@"radius" min:0 max:1 name:NSLocalizedString(@"Radius", @"")];
                      [pinch addSliderForKey:@"scale" min:-1 max:1 name:NSLocalizedString(@"Scale", @"")];
                      [pinch addPointPickerForKey:@"center" name:NSLocalizedString(@"Center", @"")];
                  },
                  @"stretch": ^(FilterPickerFilterInfo *stretch) {
                      [stretch setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageStretchDistortionFilter new];
                      }];
                      [stretch addPointPickerForKey:@"center" name:NSLocalizedString(@"Center", @"")];
                  },
                  @"dilate": ^(FilterPickerFilterInfo *dilate) {
                      [dilate setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageDilationFilter new];
                      }];
                  },
                  @"erode": ^(FilterPickerFilterInfo *erode) {
                      [erode setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageErosionFilter new];
                      }];
                  },
                  @"localBinary": ^(FilterPickerFilterInfo *localBinary) {
                      [localBinary setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [GPUImageLocalBinaryPatternFilter new];
                      }];
                  },
                  @"witchHouse": ^(FilterPickerFilterInfo *witchHouse) {
                      [witchHouse setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          GPUImageFilter *witchHouse = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"WitchHouse"];
                          GPUImageBoxBlurFilter *blur = [GPUImageBoxBlurFilter new];
                          blur.blurRadiusInPixels *= 0.7;
                          GPUImageFilterGroup *group = [GPUImageFilterGroup new];
                          group.initialFilters = @[witchHouse];
                          group.terminalFilter = blur;
                          [witchHouse addTarget:blur];
                          return group;
                      }];
                  },
                  @"greenScreen": ^(FilterPickerFilterInfo *greenScreen) {
                      [greenScreen setFilterBlock:^GPUImageOutput<GPUImageInput> *{
                          return [CMGreenScreenFilter new];
                      }];
                      greenScreen.hasSecondaryInput = YES;
                      greenScreen.customThumbnailImageName = @"GreenScreenThumbnail";
                      FilterParameter *greenScreenColor = [FilterParameter new];
                      greenScreenColor.type = FilterParameterTypeColorPickedFromImage;
                      greenScreenColor.key = @"greenScreenColor";
                      greenScreenColor.name = NSLocalizedString(@"Color to replace", @"");
                      [greenScreen.parameters addObject:greenScreenColor];
                      [greenScreen addSliderForKey:@"unifiedSensitivityAndSmoothing" min:0 max:1 name:NSLocalizedString(@"Threshold", @"")];
                      
                  }
                  };
    });
    return d;
}

+ (NSArray<NSString *> *)filterIDs {
    return @[@"noFilter", @"brightness", @"invert", @"greenScreen", @"sat", @"exp", @"hue", @"gradientMap", @"witchHouse", @"colorize", @"gamma", @"contrast", @"unsharp", @"blur", @"sharpen", @"toon", @"pixellate", @"whiteBalance", @"haze", @"localBinary", @"erode", @"dilate", @"stretch", @"pinch", @"bulge", @"swirl", @"zoom", @"motion", @"vignette", @"kuwuhara", @"emboss", @"post", @"cga", @"tilt", @"sketch", @"xy", @"canny", @"sobel", @"crosshatch", @"halftone", @"polka", @"polarPix", @"avgLuminance", @"luminanceThreshold", @"adaptiveThreshold"];
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

- (void)addPointPickerForKey:(NSString *)key name:(NSString *)name {
    FilterParameter *p = [FilterParameter new];
    p.key = key;
    p.name = name;
    p.type = FilterParameterTypePoint;
    [self.parameters addObject:p];
}

- (GPUImageOutput<GPUImageInput> *)createFilter {
    GPUImageOutput<GPUImageInput> *op = self.filterBlock();
    for (NSString *key in self.parameterValues) {
        [op setValue:self.parameterValues[key] forKey:key];
    }
    return op;
}

@end

#import "CMGreenScreenFilter.h"

@implementation CMGreenScreenFilter

@synthesize thresholdSensitivity = _thresholdSensitivity;
@synthesize smoothing = _smoothing;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromFile:@"CMGreenScreenFilter"]))
    {
        return nil;
    }
    
    thresholdSensitivityUniform = [filterProgram uniformIndex:@"thresholdSensitivity"];
    smoothingUniform = [filterProgram uniformIndex:@"smoothing"];
    colorToReplaceUniform = [filterProgram uniformIndex:@"colorToReplace"];
    
    self.greenScreenColor = [UIColor greenColor];
    self.unifiedSensitivityAndSmoothing = 0.4;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setColorToReplaceRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;
{
    GPUVector3 colorToReplace = {redComponent, greenComponent, blueComponent};
    
    [self setVec3:colorToReplace forUniform:colorToReplaceUniform program:filterProgram];
}

- (void)setThresholdSensitivity:(CGFloat)newValue;
{
    _thresholdSensitivity = newValue;
    
    [self setFloat:(GLfloat)_thresholdSensitivity forUniform:thresholdSensitivityUniform program:filterProgram];
}

- (void)setSmoothing:(CGFloat)newValue;
{
    _smoothing = newValue;
    
    [self setFloat:(GLfloat)_smoothing forUniform:smoothingUniform program:filterProgram];
}

- (void)setUnifiedSensitivityAndSmoothing:(CGFloat)unifiedSensitivityAndSmoothing {
    _unifiedSensitivityAndSmoothing = unifiedSensitivityAndSmoothing;
    self.thresholdSensitivity = unifiedSensitivityAndSmoothing;
    self.smoothing = 0.01 + 0.99 * (unifiedSensitivityAndSmoothing * 0.35);
}

- (void)setGreenScreenColor:(UIColor *)greenScreenColor {
    _greenScreenColor = greenScreenColor;
    
    CGFloat r,g,b;
    if (![greenScreenColor getRed:&r green:&g blue:&b alpha:nil]) {
        CGFloat white;
        [greenScreenColor getWhite:&white alpha:nil];
        r = g = b = white; // TODO: do this correctly
    }
    
    [self setColorToReplaceRed:r green:g blue:b];
}

@end


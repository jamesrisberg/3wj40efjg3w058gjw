//
//  CMParticleDrawable.m
//  computer
//
//  Created by Nate Parrott on 12/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMParticleDrawable.h"
#import "ConvenienceCategories.h"
#import "computer-Swift.h"

@interface _CMParticleDrawableView : CMDrawableView {
    BOOL _wasRunning;
}

@property (nonatomic) ParticlePreset particlePreset;
@property (nonatomic,copy) void(^onUpdateParticleLayout)(CGSize size, CAEmitterLayer *emitter);
@property (nonatomic) CAEmitterLayer *emitter;
@property (nonatomic) NSArray<UIImage*> *customParticleImages;

@end

@implementation _CMParticleDrawableView

- (void)setTime:(NSTimeInterval)time running:(BOOL)running {
    self.emitter.speed = running ? 1 : 0;
    if (running) {
        if (!_wasRunning) {
            self.emitter.timeOffset = time + 60;
        }
    } else {
        self.emitter.timeOffset = time + 60;
    }
    _wasRunning = running;
}

- (void)setParticlePreset:(ParticlePreset)particlePreset {
    if (particlePreset == _particlePreset) return;
    
    _particlePreset = particlePreset;
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterShape = kCAEmitterLayerRectangle;
    self.emitter = emitter;
    
    if (particlePreset == ParticlePresetFire) {
        [self fire];
    } else if (particlePreset == ParticlePresetMacaroni) {
        [self macaroni];
    } else if (particlePreset == ParticlePresetSnow) {
        [self snow];
    } else if (particlePreset == ParticlePresetSparkle) {
        [self sparkle];
    } else if (particlePreset == ParticlePresetOrbs) {
        [self orbs];
    } else if (particlePreset == ParticlePresetSmoke) {
        [self smoke];
    } else if (particlePreset == ParticlePresetCustom) {
        [self setupCustomParticles];
    }
    
    if (self.onUpdateParticleLayout) {
        self.onUpdateParticleLayout(self.bounds.size, self.emitter);
    }
}

- (void)setEmitter:(CAEmitterLayer *)emitter {
    [_emitter removeFromSuperlayer];
    _emitter = emitter;
    self.emitter.frame = self.bounds;
    [self.layer addSublayer:emitter];
}

- (void)setBounds:(CGRect)bounds {
    CGSize oldSize = self.bounds.size;
    [super setBounds:bounds];
    if (!CGSizeEqualToSize(oldSize, bounds.size) && self.onUpdateParticleLayout) {
        self.onUpdateParticleLayout(self.bounds.size, self.emitter);
    }
    self.emitter.frame = self.bounds;
}

#pragma mark Presets

- (void)fire {
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[[UIImage imageNamed:@"spark"] CGImage];
    cell.color = [UIColor colorWithRed:0.505 green:0.230 blue:0.073 alpha:1].CGColor;
    cell.alphaRange = 0.2;
    cell.alphaSpeed = -0.6;
    self.emitter.emitterCells = @[cell];
    self.emitter.renderMode = kCAEmitterLayerAdditive;
    
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height * 0.7);
        layer.emitterSize = CGSizeMake(size.width * 0.7, size.height * 0.2);
    };
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.birthRate = 100.0 / self.emitter.emitterCells.count;
        cell.scale = 1.5;
        cell.scaleRange = 0.5;
        cell.scaleSpeed = -1.3;
        cell.lifetime = 1.7;
        cell.emissionLongitude = -M_PI/2;
        cell.emissionRange = M_PI/20;
        cell.velocity = 130;
        cell.velocityRange = 50;
    }
}

- (void)macaroni {
    NSArray *images = @[@"mac1", @"mac2", @"mac3", @"mac4"];
    self.emitter.emitterCells = [images map:^id(id obj) {
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.contents = (id)[[UIImage imageNamed:obj] CGImage];
        cell.color = [UIColor colorWithWhite:1 alpha:0.1].CGColor;
        cell.alphaRange = 0.1;
        cell.alphaSpeed = 0.6;
        return cell;
    }];
    
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.scale = 0.3;
        cell.scaleSpeed = -0.1;
        cell.lifetime = 3;
        cell.emissionLongitude = M_PI/2;
        // cell.emissionRange = 2*M_PI * 0.1;
        cell.velocity = 90;
        cell.velocityRange = 60;
        cell.birthRate = 100.0 / self.emitter.emitterCells.count;
        cell.spin = 0;
        cell.spinRange = 0.9;
    }
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height * 0.2);
        layer.emitterSize = CGSizeMake(size.width * 0.9, size.height * 0.2);
    };
}

- (void)snow {
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[UIImage imageNamed:@"spark"].CGImage;
    cell.color = [UIColor colorWithRed:0.9 green:0.9 blue:0.95 alpha:1].CGColor;
    cell.blueRange = 0.05;
    self.emitter.emitterCells = @[cell];
    
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.alphaSpeed = -0.34;
        cell.alphaRange = 0.3;
        cell.scale = 0.2;
        cell.scaleRange = 0.1;
        cell.scaleSpeed = -0.02;
        cell.lifetime = 3;
        cell.emissionLongitude = M_PI/2;
        // cell.emissionRange = 2*M_PI * 0.1;
        cell.velocity = 90;
        cell.velocityRange = 60;
        cell.birthRate = 200.0 / self.emitter.emitterCells.count;
    }
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height * 0.2);
        layer.emitterSize = CGSizeMake(size.width * 0.9, size.height * 0.2);
    };
}

- (void)sparkle {
    CAEmitterCell *cell1 = [CAEmitterCell emitterCell];
    cell1.contents = (id)[[UIImage imageNamed:@"sparkle"] CGImage];
    
    CAEmitterCell *cell2 = [CAEmitterCell emitterCell];
    cell2.contents = (id)[[UIImage imageNamed:@"sparkle"] CGImage];
    
    NSArray *cells = @[cell1, cell2];
    self.emitter.emitterCells = cells;
    
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height/2);
        layer.emitterSize = CGSizeMake(size.width * 1.1, size.height * 1.1);
    };
    
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.scale = 0;
        cell.scaleRange = 0;
        cell.scaleSpeed = 0.3;
        cell.lifetime = 2;
        cell.spin = M_PI * 2 * 0.1;
        cell.spinRange = M_PI * 2 * 0.1;
        cell.alphaRange = 0.2;
        cell.alphaSpeed = -0.5;
        cell.birthRate = 10;
    }
}

- (void)smoke {
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[[UIImage imageNamed:@"smoke"] CGImage];
    cell.color = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
    cell.alphaRange = 0.1;
    cell.alphaSpeed = -0.15;
    self.emitter.emitterCells = @[cell];
    //self.emitter.renderMode = kCAEmitterLayerAdditive;
    
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height * 0.7);
        layer.emitterSize = CGSizeMake(size.width * 0.01, size.height * 0.01);
    };
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.birthRate = 70 / self.emitter.emitterCells.count;
        cell.scale = 0;
        cell.scaleRange = 0;
        cell.scaleSpeed = 0.25;
        cell.lifetime = 4;
        cell.emissionLongitude = -M_PI/2;
        cell.emissionRange = M_PI/12;
        cell.velocity = 100;
        cell.velocityRange = 20;
    }
}

- (void)orbs {
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[[UIImage imageNamed:@"orb"] CGImage];
    cell.color = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1].CGColor;
    cell.redRange = 0.3;
    cell.greenRange = 0.3;
    cell.blueRange = 0.3;
    cell.birthRate = 14;
    cell.scale = 0.4;
    cell.scaleRange = 0.3;
    cell.scaleSpeed = 0.1;
    cell.emissionRange = 2 * M_PI;
    cell.velocity = 140;
    cell.velocityRange = 40;
    cell.alphaRange = 0.2;
    cell.alphaSpeed = -0.2;
    cell.lifetime = 5;
    self.emitter.emitterCells = @[cell];
    
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height/2);
        layer.emitterSize = CGSizeMake(0.05, 0.05);
    };
}

#pragma mark Custom Particles

- (void)setupCustomParticles {
    self.emitter.emitterCells = [self.customParticleImages map:^id(id obj) {
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.contents = (id)[obj CGImage];
        cell.color = [UIColor colorWithWhite:1 alpha:0].CGColor;
        cell.alphaRange = 0.1;
        cell.alphaSpeed = 2;
        return cell;
    }];
    
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.scale = 0.45;
        cell.scaleSpeed = -0.12;
        cell.lifetime = 0.45 / 0.12;
        cell.emissionLongitude = M_PI/2;
        // cell.emissionRange = 2*M_PI * 0.1;
        cell.velocity = 90;
        cell.velocityRange = 60;
        cell.birthRate = 35.0 / self.emitter.emitterCells.count;
        cell.spin = 0;
        cell.spinRange = 0.9;
    }
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height * 0.2);
        layer.emitterSize = CGSizeMake(size.width * 0.9, size.height * 0.2);
    };
}

- (void)setCustomParticleImages:(NSArray<UIImage *> *)customParticleImages {
    if (customParticleImages != _customParticleImages) {
        _customParticleImages = customParticleImages;
        if (self.particlePreset == ParticlePresetCustom) {
            [self setupCustomParticles];
        }
    }
}

@end




@interface CMParticleDrawable () {
    NSArray<UIImage*> *_imagesResizedForParticles;
}

@property (nonatomic) NSArray *customParticleImagesData;

@end

@implementation CMParticleDrawable

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"particlePreset", @"customParticleImagesData"]];
}

- (__kindof CMDrawableView *)renderToView:(__kindof CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx {
    _CMParticleDrawableView *v = [existingOrNil isKindOfClass:[_CMParticleDrawableView class]] ? (id)existingOrNil : [_CMParticleDrawableView new];
    [super renderToView:v context:ctx];
    v.particlePreset = self.particlePreset;
    v.customParticleImages = [self _imagesResizedForParticles];
    if (ctx.useFrameTimeForStaticAnimations) {
        [v setTime:ctx.time.time running:NO];
    } else {
        [v setTime:CFAbsoluteTimeGetCurrent() running:YES];
    }
    return v;
}

- (CGFloat)aspectRatio {
    NSNumber *n = @{
                    @(ParticlePresetMacaroni): @3,
                    @(ParticlePresetSmoke): @2,
                    @(ParticlePresetSnow): @2,
                    @(ParticlePresetFire): @2,
                    @(ParticlePresetCustom): @2,
                    }[@(self.particlePreset)];
    return n.floatValue ? : 1;
}

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Particle Effect", @"");
}

#pragma mark Custom particles

- (NSArray<PropertyGroupModel*>*)propertyGroupsWithEditor:(CanvasEditor *)editor {
    NSMutableArray *groups = [super propertyGroupsWithEditor:editor].mutableCopy;
    if (self.particlePreset == ParticlePresetCustom) {
        PropertyModel *editImages = [PropertyModel new];
        editImages.key = @"customParticleImages";
        editImages.type = PropertyModelTypeParticleImages;
        PropertyGroupModel *group = [PropertyGroupModel new];
        group.properties = @[editImages];
        group.title = NSLocalizedString(@"Particles", @"");
        group.singleView = YES;
        [groups insertObject:group atIndex:0];
    }
    return groups;
}

- (NSArray *)customParticleImagesData {
    return [self.customParticleImages map:^id(id obj) {
        return UIImagePNGRepresentation(obj);
    }];
}

- (void)setCustomParticleImagesData:(NSArray *)customParticleImagesData {
    self.customParticleImages = [customParticleImagesData map:^id(id obj) {
        return [UIImage imageWithData:obj];
    }];
}

- (void)setCustomParticleImages:(NSArray<UIImage *> *)customParticleImages {
    _customParticleImages = customParticleImages;
    _imagesResizedForParticles = nil;
}

- (NSArray<UIImage*> *)_imagesResizedForParticles {
    if (!_imagesResizedForParticles) {
        _imagesResizedForParticles = [self.customParticleImages map:^id(id obj) {
            return [[self class] resizeImageForCustomParticle:obj];
        }];
    }
    return _imagesResizedForParticles;
}

+ (UIImage *)resizeImageForCustomParticle:(UIImage *)image {
    return [image resizedWithMaxDimension:110];
}

@end

//
//  Grabcut.m
//  Backgrounder
//
//  Created by Nate Parrott on 6/15/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "Grabcut.h"
#import <opencv.hpp>
#import <opencv2/highgui/ios.h>

@interface Grabcut () {
    cv::Mat original, imageMat, result, bgModel, fgModel;
}

@property (strong) UIImage *image;

@end

@implementation Grabcut

- (id)initWithImage:(UIImage*)image {
    self = [super init];
    self.image = image;
    UIImageToMat(self.image, original);
    cv::cvtColor(original, original, CV_RGBA2RGB);
    UIImageToMat(self.image, imageMat);
    cv::cvtColor(imageMat, imageMat, CV_RGBA2RGB);
    return self;
}
- (void)maskToRect:(CGRect)boundingBox {
    
    cv::Rect rect = cv::Rect(boundingBox.origin.x, boundingBox.origin.y, boundingBox.size.width, boundingBox.size.height);
    cv::grabCut(imageMat, result, rect, bgModel, fgModel, 1, cv::GC_INIT_WITH_RECT);
}
- (void)addMask:(UIImage*)mask foregroundColor:(UIColor*)foreground backgroundColor:(UIColor*)background {
    CGFloat fr, fg, fb;
    [foreground getRed:&fr green:&fg blue:&fb alpha:nil];
    cv::Vec4b foregroundVec(fr*255, fg*255, fb*255, 255);
    
    CGFloat br, bg, bb;
    [background getRed:&br green:&bg blue:&bb alpha:nil];
    cv::Vec4b backgroundVec(br*255, bg*255, bb*255, 255);
    
    int filled = 0;
    int empty = 0;
    
    cv::Mat maskMat;
    UIImageToMat(mask, maskMat);
    for (int y=0; y<maskMat.rows; y++) {
        for (int x=0; x<maskMat.cols; x++) {
            cv::Vec4b color = maskMat.at<cv::Vec4b>(y, x);
            if (color[0] + color[1] + color[2] > 0) {
                filled++;
                int distFromForeground = 0;
                int distFromBackground = 0;
                for (int i=0; i<3; i++) {
                    distFromForeground += abs(color[i] - foregroundVec[i]);
                    distFromBackground += abs(color[i] - backgroundVec[i]);
                }
                BOOL foreground = distFromForeground < distFromBackground;
                result.at<unsigned char>(y, x) = foreground? cv::GC_FGD : cv::GC_BGD;
            } else {
                empty++;
            }
        }
    }
    
    cv::grabCut(imageMat, result, cv::Rect(), bgModel, fgModel, 1, cv::GC_EVAL);
}
- (UIImage*)extractImage {
    /*cv::compare(result,cv::GC_PR_FGD,result,cv::CMP_EQ);
    cv::Mat foregroundResult(imageMat.size(),CV_8UC3,cv::Scalar(255,255,255));
    imageMat.copyTo(foregroundResult,result); // bg pixels not copied
    return MatToUIImage(foregroundResult);
    */
    
    cv::Mat output(imageMat.rows, imageMat.cols, CV_8UC4, cv::Scalar(0,0,0,0));
    for (int y=0; y<imageMat.rows; y++) {
        for (int x=0; x<imageMat.cols; x++) {
            unsigned char classification = result.at<unsigned char>(y, x);
            if (classification == cv::GC_PR_FGD || classification == cv::GC_FGD) {
                cv::Vec3b color = original.at<cv::Vec3b>(y,x);
                output.at<cv::Vec4b>(y,x) = cv::Vec4b(color[0], color[1], color[2], 255);
            } else {
                output.at<cv::Vec4b>(y,x) = cv::Vec4b(0,0,0,0);
            }
        }
    }
    
    // from https://github.com/aptogo/OpenCVForiPhone/blob/master/OpenCVClient/UIImage%2BOpenCV.mm
    
    NSData *data = [NSData dataWithBytes:output.data length:output.elemSize() * output.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (output.elemSize() == 1)
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(output.cols,                                     // Width
                                        output.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * output.elemSize(),                           // Bits per pixel
                                        output.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaLast | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    UIImage* i = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return i;
    
    //return MatToUIImage(output);
}

@end

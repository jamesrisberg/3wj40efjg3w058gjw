precision highp float;

varying highp vec2 textureCoordinate;
varying highp vec2 textureCoordinate2;

uniform float thresholdSensitivity;
uniform float smoothing;
uniform vec3 colorToReplace;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

#define M_PI 3.1415926535897932384626433832795

const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

highp vec3 rgb2hsv(highp vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

highp vec3 rgb2xyz(highp vec3 rgb) {
    /*
     $r  = $rgb[self::RGB_RED] / 255;
     $g  = $rgb[self::RGB_GREEN] / 255;
     $b  = $rgb[self::RGB_BLUE] / 255;
     
     if ($r > 0.04045) {
     $r  = pow((($r + 0.055) / 1.055), 2.4);
     } else {
     $r  = $r / 12.92;
     }
     
     if ($g > 0.04045) {
     $g  = pow((($g + 0.055) / 1.055), 2.4);
     } else {
     $g  = $g / 12.92;
     }
     
     if ($b > 0.04045) {
     $b  = pow((($b + 0.055) / 1.055), 2.4);
     } else {
     $b  = $b / 12.92;
     }
     
     $r  *= 100;
     $g  *= 100;
     $b  *= 100;
     
     //Observer. = 2°, Illuminant = D65
     return array(
     self::XYZ_X => $r * 0.4124 + $g * 0.3576 + $b * 0.1805,
     self::XYZ_Y => $r * 0.2126 + $g * 0.7152 + $b * 0.0722,
     self::XYZ_Z => $r * 0.0193 + $g * 0.1192 + $b * 0.9505,
     );
     */
    if (rgb.x > 0.04045) {
        rgb.x = pow((rgb.x + 0.055) / 1.055, 2.4);
    } else {
        rgb.x = rgb.r / 12.92;
    }
    
    if (rgb.y > 0.04045) {
        rgb.y = pow((rgb.y + 0.55) / 1.055, 2.4);
    } else {
        rgb.y = rgb.y / 12.92;
    }
    
    if (rgb.z > 0.04045) {
        rgb.z = pow((rgb.z + 0.55) / 1.055, 2.4);
    } else {
        rgb.z = rgb.z / 12.92;
    }
    
    rgb = rgb * 100.0;
    
    float x = rgb.x * 0.4124 + rgb.y * 0.3576 + rgb.z * 0.1805;
    float y = rgb.x * 0.2126 + rgb.y * 0.7152 + rgb.z * 0.0722;
    float z = rgb.x * 0.0193 + rgb.y * 0.1192 + rgb.z * 0.9505;
    return vec3(x,y,z);
}

highp vec3 xyz2cielab(vec3 xyz) {
    /*
     private function XYZtoCIELAB($xyz)
     {
     $refX = 100;
     $refY = 100;
     $refZ = 100;
     
     $x = $xyz[self::XYZ_X] / $refX;
     $y = $xyz[self::XYZ_Y] / $refY;
     $z = $xyz[self::XYZ_Z] / $refZ;
     
     if ($x > 0.008856) {
     $x = pow($x, 1/3);
     } else {
     $x = (7.787 * $x) + (16 / 116);
     }
     
     if ($y > 0.008856) {
     $y = pow($y, 1/3);
     } else {
     $y = (7.787 * $y) + (16 / 116);
     }
     
     if ($z > 0.008856) {
     $z = pow($z, 1/3);
     } else {
     $z = (7.787 * $z) + (16 / 116);
     }
     
     return array(
     self::LAB_L => (116 * $y) - 16,
     self::LAB_A => 500 * ($x - $y),
     self::LAB_B => 200 * ($y - $z),
     );
     }
     */
    
    xyz = xyz / 100.0;
    
    if (xyz.x > 0.008856) {
        xyz.x = pow(xyz.x, 1.0/3.0);
    } else {
        xyz.x = (7.787 * xyz.x) + (16.0 / 116.0);
    }
    
    if (xyz.y > 0.008856) {
        xyz.y = pow(xyz.y, 1.0/3.0);
    } else {
        xyz.y = (7.787 * xyz.y) + (16.0 / 116.0);
    }
    
    if (xyz.z > 0.008856) {
        xyz.z = pow(xyz.z, 1.0/3.0);
    } else {
        xyz.z = (7.787 * xyz.z) + (16.0 / 116.0);
    }
    
    return vec3(116.0 * xyz.y - 16.0, 500.0 * (xyz.x - xyz.y), 200.0 * (xyz.y -xyz.z));
}

highp float rad2deg(highp float rad) {
    return rad / M_PI * 180.0;
}

highp float labToHue(highp float a, highp float b) {
    /*
     public function LABtoHue($a, $b)
     {
     $bias = 0;
     if ($a >= 0 && $b == 0) { return 0;   }
     if ($a <  0 && $b == 0) { return 180; }
     if ($a == 0 && $b >  0) { return 90;  }
     if ($a == 0 && $b <  0) { return 270; }
     if ($a >  0 && $b >  0) { $bias = 0;  }
     if ($a <  0)            { $bias = 180;}
     if ($a >  0 && $b <  0) { $bias = 360;}
     return (rad2deg(atan($b / $a)) + $bias);
     }
     */
    highp float bias = 0.0;
    if (a >= 0.0 && b == 0.0) return 0.0;
    if (a < 0.0 && b == 0.0) return 180.0;
    if (a == 0.0 && b > 0.0) return 90.0;
    if (a == 0.0 && b < 0.0) return 270.0;
    if (a > 0.0 && b > 0.0) bias = 0.0;
    if (a < 0.0) bias = 180.0;
    if (a > 0.0 && b < 0.0) bias = 360.0;
    return (rad2deg(atan(b / a)) + bias);
}

bool isnan(float val)
{
    return (val <= 0.0 || 0.0 <= val) ? false : true;
}

highp float deltaE200(vec3 lab1, vec3 lab2) {
    /*
     $weightL  = 1; // Lightness
     $weightC  = 1; // Chroma
     $weightH  = 1; // Hue
     */
    
    highp float weightL = 1.0;
    highp float weightC = 1.0;
    highp float weightH = 1.0;
    
    /*
     
     $xCA = sqrt($labA[self::LAB_A] * $labA[self::LAB_A] + $labA[self::LAB_B] * $labA[self::LAB_B]);
     $xCB = sqrt($labB[self::LAB_A] * $labB[self::LAB_A] + $labB[self::LAB_B] * $labB[self::LAB_B]);
     $xCX = ($xCA + $xCB) / 2;
     $xGX = 0.5 * (1 - sqrt((pow($xCX, 7)) / ((pow($xCX, 7)) + (pow(25, 7)))));
     $xNN = (1 + $xGX) * $labA[self::LAB_A];
     $xCA = sqrt($xNN * $xNN + $labA[self::LAB_B] * $labA[self::LAB_B]);
     $xHA = $this->LABtoHue($xNN, $labA[self::LAB_B]);
     $xNN = (1 + $xGX) * $labB[self::LAB_A];
     $xCB = sqrt($xNN * $xNN + $labB[self::LAB_B] * $labB[self::LAB_B]);
     $xHB = $this->LABtoHue($xNN, $labB[self::LAB_B]);
     $xDL = $labB[self::LAB_L] - $labA[self::LAB_L];
     $xDC = $xCB - $xCA;
     */
    
    highp float xCA = sqrt(lab1.y * lab1.y + lab1.z * lab1.z);
    highp float xCB = sqrt(lab2.y * lab2.y + lab2.z * lab2.z);
    highp float xCX = (xCA + xCB) / 2.0;
    highp float xGX = 0.5 * (1.0 - sqrt((pow(xCX, 7.0)) / ((pow(xCX, 7.0)) + (pow(25.0, 7.0)))));
    highp float xNN = (1.0 + xGX) * lab1.y;
    xCA = sqrt(xNN * xNN + lab1.z * lab1.z);
    highp float xHA = labToHue(xNN, lab1.z);
    xNN = (1.0 + xGX) * lab2.y;
    xCB = sqrt(xNN * xNN + lab2.z *lab2.z);
    xCB = sqrt(xNN * xNN + lab2.z *lab2.z);
    highp float xHB = labToHue(xNN, lab2.z);
    highp float xDL = lab2.x - lab1.x;
    highp float xDC = xCB - xCA;
    
    /*
     
     if (($xCA * $xCB) == 0) {
     $xDH = 0;
     } else {
     $xNN = round($xHB - $xHA, 12);
     if (abs($xNN) <= 180) {
     $xDH = $xHB - $xHA;
     } else {
     if ($xNN > 180) {
     $xDH = $xHB - $xHA - 360;
     } else {
     $xDH = $xHB - $xHA + 360;
     }
     } // if
     } // if
     
     */
    
    highp float xDH;
    if ((xCA * xCB) == 0.0) {
        xDH = 0.0;
    } else {
        xNN = floor((xHB - xHA) / 12.0 + 0.5) * 12.0;
        if (abs(xNN) <= 18.00) {
            xDH = xHB - xHA;
        } else {
            if (xNN > 180.0) {
                xDH = xHB - xHA - 360.0;
            } else {
                xDH = xHB - xHA + 360.0;
            }
        }
    }
    
    /*
     
     $xDH = 2 * sqrt($xCA * $xCB) * sin(rad2deg($xDH / 2));
     $xLX = ($labA[self::LAB_L] + $labB[self::LAB_L]) / 2;
     $xCY = ($xCA + $xCB) / 2;
     
     if (($xCA *  $xCB) == 0) {
     $xHX = $xHA + $xHB;
     } else {
     $xNN = abs(round($xHA - $xHB, 12));
     if ($xNN >  180) {
     if (($xHB + $xHA) <  360) {
     $xHX = $xHA + $xHB + 360;
     } else {
     $xHX = $xHA + $xHB - 360;
     }
     } else {
     $xHX = $xHA + $xHB;
     } // if
     $xHX /= 2;
     } // if
     */
    
    xDH = 2.0 * sqrt(xCA * xCB) * sin(rad2deg(xDH / 2.0));
    highp float xLX = (lab1.x + lab2.x) / 2.0;
    highp float xCY = (xCA + xCB) / 2.0;
    highp float xHX;
    
    if ((xCA *  xCB) == 0.0) {
        xHX = xHA + xHB;
    } else {
        xNN = abs(floor((xHA - xHB) / 12.0 + 0.5) * 12.0);
        if (xNN >  180.0) {
            if ((xHB + xHA) <  360.0) {
                xHX = xHA + xHB + 360.0;
            } else {
                xHX = xHA + xHB - 360.0;
            }
        } else {
            xHX = xHA + xHB;
        } // if
        xHX /= 2.0;
    } // if
    
    /*
     $xTX = 1 - 0.17 * cos(rad2deg($xHX - 30))
     + 0.24 * cos(rad2deg(2 * $xHX))
     + 0.32 * cos(rad2deg(3 * $xHX + 6))
     - 0.20 * cos(rad2deg(4 * $xHX - 63));
     
     $xPH = 30 * exp(- (($xHX  - 275) / 25) * (($xHX  - 275) / 25));
     $xRC = 2 * sqrt((pow($xCY, 7)) / ((pow($xCY, 7)) + (pow(25, 7))));
     $xSL = 1 + ((0.015 * (($xLX - 50) * ($xLX - 50)))
     / sqrt(20 + (($xLX - 50) * ($xLX - 50))));
     $xSC = 1 + 0.045 * $xCY;
     $xSH = 1 + 0.015 * $xCY * $xTX;
     $xRT = - sin(rad2deg(2 * $xPH)) * $xRC;
     $xDL = $xDL / $weightL * $xSL;
     $xDC = $xDC / $weightC * $xSC;
     $xDH = $xDH / $weightH * $xSH;
     
     $delta  = sqrt(pow($xDL, 2) + pow($xDC, 2) + pow($xDH, 2) + $xRT * $xDC * $xDH);
     return (is_nan($delta)) ? 1 : $delta / 100;
     */
    
    highp float xTX = 1.0 - 0.17 * cos(rad2deg(xHX - 30.0))
    + 0.24 * cos(rad2deg(2.0 * xHX))
    + 0.32 * cos(rad2deg(3.0 * xHX + 6.0))
    - 0.20 * cos(rad2deg(4.0 * xHX - 63.0));
    
    highp float xPH = 30.0 * exp(- ((xHX  - 275.0) / 25.0) * ((xHX  - 275.0) / 25.0));
    highp float xRC = 2.0 * sqrt((pow(xCY, 7.0)) / ((pow(xCY, 7.0)) + (pow(25.0, 7.0))));
    highp float xSL = 1.0 + ((0.015 * ((xLX - 50.0) * (xLX - 50.0)))
                / sqrt(20.0 + ((xLX - 50.0) * (xLX - 50.0))));
    highp float xSC = 1.0 + 0.045 * xCY;
    highp float xSH = 1.0 + 0.015 * xCY * xTX;
    highp float xRT = - sin(rad2deg(2.0 * xPH)) * xRC;
    xDL = xDL / weightL * xSL;
    xDC = xDC / weightC * xSC;
    xDH = xDH / weightH * xSH;
    
    highp float delta = sqrt(pow(xDL, 2.0) + pow(xDC, 2.0) + pow(xDH, 2.0) + xRT * xDC * xDH);
    return (isnan(delta)) ? 1.0 : delta / 100.0;
}

highp float colorDist(highp vec3 rgb1, highp vec3 rgb2) {
    return deltaE200(xyz2cielab(rgb2xyz(rgb1)), xyz2cielab(rgb2xyz(rgb1)));
}

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    
    vec3 maskHsv = rgb2hsv(colorToReplace);
    vec3 hsv = rgb2hsv(textureColor.xyz);
    
    float maskY = 0.2989 * colorToReplace.r + 0.5866 * colorToReplace.g + 0.1145 * colorToReplace.b;
    float maskCr = 0.7132 * (colorToReplace.r - maskY);
    float maskCb = 0.5647 * (colorToReplace.b - maskY);
    
    float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
    float Cr = 0.7132 * (textureColor.r - Y);
    float Cb = 0.5647 * (textureColor.b - Y);
    
    /*float chromaDist = distance(vec2(Cr, Cb), vec2(maskCr, maskCb));
    float rgbDist = distance(textureColor.xyz * W, colorToReplace * W);
    float dist = chromaDist * maskHsv.y + rgbDist * (1.0 - maskHsv.y);*/
    float dist = colorDist(textureColor.xyz, colorToReplace);
    
    //     float blendValue = 1.0 - smoothstep(thresholdSensitivity - smoothing, thresholdSensitivity , abs(Cr - maskCr) + abs(Cb - maskCb));
    float blendValue = 1.0 - smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, dist);
    gl_FragColor = mix(textureColor, textureColor2, blendValue);
}

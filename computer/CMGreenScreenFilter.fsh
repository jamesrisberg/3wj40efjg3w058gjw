precision highp float;

varying highp vec2 textureCoordinate;
varying highp vec2 textureCoordinate2;

uniform float thresholdSensitivity;
uniform float smoothing;
uniform vec3 colorToReplace;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

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
    
     float chromaDist = distance(vec2(Cr, Cb), vec2(maskCr, maskCb));
     float rgbDist = distance(textureColor.xyz * W, colorToReplace * W);
     float dist = chromaDist * maskHsv.y + rgbDist * (1.0 - maskHsv.y);
    
    //     float blendValue = 1.0 - smoothstep(thresholdSensitivity - smoothing, thresholdSensitivity , abs(Cr - maskCr) + abs(Cb - maskCb));
    float blendValue = 1.0 - smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, dist);
    gl_FragColor = mix(textureColor, textureColor2, blendValue);
}
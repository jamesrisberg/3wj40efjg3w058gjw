varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

highp float rand(highp vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{
    highp vec2 point = textureCoordinate + vec2(rand(vec2(0.0, floor(textureCoordinate.y * 10.0))) * 0.015, 0.0);
    lowp vec4 left = texture2D(inputImageTexture, point + vec2(-0.007, 0.0));
    lowp vec4 right = texture2D(inputImageTexture, point + vec2(0.007, 0.0));
    lowp vec4 center = texture2D(inputImageTexture, point);
    lowp vec4 fragmentColor = vec4(left.x, right.y, center.z, center.w);
    
    if (mod(textureCoordinate.y * 250.0, 5.0) < 1.0) {
        fragmentColor += 0.1;
    }
    
    gl_FragColor = fragmentColor;
}

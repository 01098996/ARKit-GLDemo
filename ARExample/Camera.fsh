precision highp float;

varying vec2 textureCoordinate;

uniform sampler2D capturedImageTextureY;
uniform sampler2D capturedImageTextureCbCr;

void main(void)
{
    vec4 Y_planeColor = texture2D(capturedImageTextureY, textureCoordinate);
    vec4 CbCr_planeColor = texture2D(capturedImageTextureCbCr, textureCoordinate);
    
    float Cb, Cr, Y;
    float R ,G, B;
    Y = Y_planeColor.r * 255.0;
    Cb = CbCr_planeColor.r * 255.0 - 128.0;
    Cr = CbCr_planeColor.a * 255.0 - 128.0;
    
    R = 1.402 * Cr + Y;
    G = -0.344 * Cb - 0.714 * Cr + Y;
    B = 1.772 * Cb + Y;
    
    
    vec4 videoColor = vec4(R / 255.0, G / 255.0, B / 255.0, 1.0);
    gl_FragColor = videoColor;
}

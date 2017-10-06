attribute vec4 position;
attribute vec2 texCoord;

varying vec2 textureCoordinate;

void main()
{
    gl_Position = position;
    textureCoordinate = texCoord;
}


attribute vec3 position;
attribute vec2 texCoord;
attribute vec3 normal;
attribute vec4 color;

// Camera Uniforms
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;

uniform mat4 modelMatrix;

varying vec4 outputPosition;
varying vec4 outputColor;
varying vec3 eyePosition;
varying vec3 outputNormal;

void main()
{
    // Make position a float4 to perform 4x4 matrix math on it
    vec4 newPosition = vec4(position, 1.0);
    mat4 modelViewMatrix = viewMatrix * modelMatrix;
    
    outputPosition = projectionMatrix * modelViewMatrix * newPosition;
    outputColor = color;
        // Calculate the positon of our vertex in eye space
    eyePosition = vec3((modelViewMatrix * newPosition).xyz);
    
    // Rotate our normals to world coordinates
    vec4 newNormal = modelMatrix * vec4(normal.x, normal.y, normal.z, 0.0);
    outputNormal = normalize(vec3(newNormal.xyz));
    
    gl_Position = outputPosition;
}


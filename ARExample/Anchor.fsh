precision highp float;

// Camera Uniforms
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;

// Lighting Properties
uniform vec3 ambientLightColor;
uniform vec3 directionalLightDirection;
uniform vec3 directionalLightColor;
uniform float materialShininess;

varying vec4 outputPosition;
varying vec4 outputColor;
varying vec3 eyePosition;
varying vec3 outputNormal;

void main(void)
{
    vec3 normal = vec3(outputNormal);
    
    // Calculate the contribution of the directional light as a sum of diffuse and specular terms
    vec3 directionalContribution = vec3(0.0);
    // Light falls off based on how closely aligned the surface normal is to the light direction
    float nDotL = clamp(dot(normal, -directionalLightDirection),0.0,1.0);
    
    // The diffuse term is then the product of the light color, the surface material
    // reflectance, and the falloff
    vec3 diffuseTerm = directionalLightColor * nDotL;
    
    // Apply specular lighting...
    
    // 1) Calculate the halfway vector between the light direction and the direction they eye is looking
    vec3 halfwayVector = normalize(-directionalLightDirection - vec3(eyePosition));
    
    // 2) Calculate the reflection angle between our reflection vector and the eye's direction
    float reflectionAngle = clamp(dot(normal, halfwayVector),0.0,1.0);
    
    // 3) Calculate the specular intensity by multiplying our reflection angle with our object's
    //    shininess
    float specularIntensity = clamp(pow(reflectionAngle, materialShininess),0.0,1.0);
    
    // 4) Obtain the specular term by multiplying the intensity by our light's color
    vec3 specularTerm = directionalLightColor * specularIntensity;
    
    // Calculate total contribution from this light is the sum of the diffuse and specular values
    directionalContribution = diffuseTerm + specularTerm;
    
    // The ambient contribution, which is an approximation for global, indirect lighting, is
    // the product of the ambient light intensity multiplied by the material's reflectance
    vec3 ambientContribution = ambientLightColor;
    
    // Now that we have the contributions our light sources in the scene, we sum them together
    // to get the fragment's lighting value
    vec3 lightContributions = ambientContribution + directionalContribution;
    
    // We compute the final color by multiplying the sample from our color maps by the fragment's
    // lighting value
    vec3 newColor = outputColor.rgb * lightContributions;
    
    // We use the color we just computed and the alpha channel of our
    // colorMap for this fragment's alpha value
    gl_FragColor = vec4(newColor, outputColor.w);
}


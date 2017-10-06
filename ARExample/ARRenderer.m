//
//  ARRenderer.m
//  ARExample
//
//  Created by ZhangXiaoJun on 2017/7/5.
//  Copyright © 2017年 ZhangXiaoJun. All rights reserved.
//

#import "ARRenderer.h"
#import "GLProgram.h"
#import <OpenGLES/ES2/gl.h>
#import <MetalKit/MetalKit.h>

struct ARData {
    GLfloat position[3];
    GLfloat texCoord[2];
    GLfloat normal[3];
    GLfloat color[4];
};

static const struct ARData kARDatas[]=
{
    0.038,     0.038 ,    0.038 , 0.000000   ,  0.000000  ,   1.00000   ,  0.00000  ,   0.00000,0,1,0,1,
    0.038 ,    0.038 ,   -0.038 , 1.000000  ,   0.000000,     1.00000  ,   0.00000  ,   0.00000,0,1,0,1,
    0.038 ,   -0.038 ,    0.038 ,0.000000  ,   1.000000,     1.00000  ,   0.00000  ,   0.00000,0,1,0,1,
    0.038 ,   -0.038  ,  -0.038  ,1.000000  ,   1.000000,     1.00000  ,   0.00000   ,  0.00000,0,1,0,1,
    -0.038 ,    0.038  ,  -0.038 ,0.000000 ,    0.000000,    -1.00000 ,    0.00000  ,   0.00000,1,0,0,1,
    -0.038 ,    0.038  ,   0.038 ,1.000000   ,  0.000000,    -1.00000 ,    0.00000 ,    0.00000,1,0,0,1,
    -0.038 ,   -0.038  ,  -0.038 ,0.000000  ,   1.000000,    -1.00000  ,   0.00000  ,   0.00000,1,0,0,1,
    -0.038 ,   -0.038 ,    0.038 ,1.000000 ,    1.000000,    -1.00000  ,   0.00000   ,  0.00000,1,0,0,1,
    -0.038 ,    0.038  ,  -0.038 ,0.000000  ,   0.000000,     0.00000  ,   1.00000  ,   0.00000,0,0,1,1,
    0.038 ,    0.038   , -0.038 ,1.000000   ,  0.000000,     0.00000  ,   1.00000   ,  0.00000,0,0,1,1,
    -0.038 ,    0.038 ,    0.038 ,0.000000 ,    1.000000,     0.00000 ,    1.00000 ,    0.00000,0,0,1,1,
    0.038 ,    0.038 ,    0.038 ,1.000000  ,   1.000000,     0.00000  ,   1.00000  ,   0.00000,0,0,1,1,
    -0.038 ,   -0.038,     0.038 ,0.000000 ,    0.000000,     0.00000 ,   -1.00000 ,    0.00000,1,0.5,0,1,
    0.038  ,  -0.038  ,   0.038 ,1.000000   ,  0.000000,     0.00000  ,  -1.00000  ,   0.00000,1,0.5,0,1,
    -0.038 ,   -0.038  ,  -0.038 ,0.000000  ,   1.000000,     0.00000  ,  -1.00000 ,    0.00000,1,0.5,0,1,
    0.038 ,   -0.038  ,  -0.038 ,1.000000   ,  1.000000,     0.00000   , -1.00000   ,  0.00000,1,0.5,0,1,
    -0.038 ,    0.038  ,   0.038 ,0.000000  ,   0.000000,    -0.00000 ,    0.00000 ,    1.00000,1,1,0,1,
    0.038  ,   0.038  ,   0.038 ,1.000000   ,  0.000000,    -0.00000   ,  0.00000   ,  1.00000,1,1,0,1,
    -0.038   , -0.038 ,    0.038 ,0.000000  ,   1.000000,    -0.00000  ,   0.00000  ,   1.00000,1,1,0,1,
    0.038  ,  -0.038  ,   0.038 ,1.000000  ,   1.000000,    -0.00000  ,   0.00000  ,   1.00000,1,1,0,1,
    0.038  ,   0.038  ,  -0.038 ,0.000000  ,   0.000000,    -0.00000  ,  -0.00000 ,   -1.00000,1,1,1,1,
    -0.038 ,    0.038 ,   -0.038 , 1.000000  ,   0.000000,    -0.00000 ,   -0.00000  ,  -1.00000,1,1,1,1,
    0.038  , -0.038 ,   -0.038    ,0.000000  ,   1.000000,    -0.00000  ,  -0.00000  ,  -1.00000,1,1,1,1,
    -0.038  ,  -0.038 ,   -0.038   ,1.000000  ,   1.000000,    -0.00000   , -0.00000 ,   -1.00000,1,1,1,1,
};

static const GLubyte kARDataIndices[] = {
    0,3,1,0,2,3,4,7,5,4,6,7,8,11,9,8,10,11,12,15,13,12,14,15,16,19,17,16,18,19,
    20,23,21,20,22,23
    
};

// The max number of command buffers in flight
static const NSUInteger kMaxBuffersInFlight = 3;

// The max number anchors our uniform buffer will hold
static const NSUInteger kMaxAnchorInstanceCount = 64;

// Structure shared between shader and C code to ensure the layout of shared uniform data accessed in
//    Metal shaders matches the layout of uniform data set in C code
typedef struct {
    // Camera Uniforms
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    
    // Lighting Properties
    vector_float3 ambientLightColor;
    vector_float3 directionalLightDirection;
    vector_float3 directionalLightColor;
    float materialShininess;
} SharedUniforms;

// Structure shared between shader and C code to ensure the layout of instance uniform data accessed in
//    Metal shaders matches the layout of uniform data set in C code
typedef struct {
    matrix_float4x4 modelMatrix;
} InstanceUniforms;

// The 256 byte aligned size of our uniform structures
static const size_t kAlignedSharedUniformsSize = (sizeof(SharedUniforms) & ~0xFF) + 0x100;
static const size_t kAlignedInstanceUniformsSize = ((sizeof(InstanceUniforms) * kMaxAnchorInstanceCount) & ~0xFF) + 0x100;

@interface ARRenderer ()
{
    void *_sharedUniformBufferAddress;
    void *_anchorUniformBufferAddress;
    SharedUniforms *_sharedUniformBuffer;
    InstanceUniforms *_anchorUniformBuffer;
    uint8_t _uniformBufferIndex;
    NSUInteger _anchorInstanceCount;
    
    uint8_t _sharedUniformBufferOffset;
    uint8_t _anchorUniformBufferOffset;
    char *_modelMatrixNames[kMaxAnchorInstanceCount];
    
    
    GLuint _cubeBuffer;
    GLuint _cubeIndicesBuffer;
    // MetalKit mesh containing vertex data and index buffer for our anchor geometry
    GLKMesh *_cubeMesh;
    EAGLContext *_context;
    CVOpenGLESTextureCacheRef _coreVideoTextureCache;
}
@end

@implementation ARRenderer

- (void)dealloc
{
    for(int i = 0; i < kMaxAnchorInstanceCount; i++){
        free(_modelMatrixNames[i]);
    }
}

- (instancetype)initWithSession:(ARSession *)session
{
    self = [super init];
    if (self) {
        _sesstion = session;
        for(int i = 0; i < kMaxAnchorInstanceCount; i++){
            const char *name = [[NSString stringWithFormat:@"modelMatrix[%d]",i] UTF8String];
            char *copyName = malloc(strlen(name) + 1);
            strcpy(copyName, name);
            _modelMatrixNames[i]  = copyName;
        }
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

        if (!_context || ![EAGLContext setCurrentContext:_context]){
            NSAssert(NO, @"Failed to init gl context !");
            return nil;
        }
        
        _anchorUniformBuffer = malloc(kAlignedInstanceUniformsSize * kMaxBuffersInFlight);
        _sharedUniformBuffer = malloc(kAlignedSharedUniformsSize * kMaxBuffersInFlight);
        
        _sceneSize = CGSizeZero;
        
        _anchorProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"Anchor"
                                                  fragmentShaderFilename:@"Anchor"];
        
        if (!_anchorProgram.initialized)
        {
            [_anchorProgram addAttribute:@"position"];
            [_anchorProgram addAttribute:@"texCoord"];
            [_anchorProgram addAttribute:@"normal"];
            [_anchorProgram addAttribute:@"color"];
            // Link program.
            if (![_anchorProgram link]) {
                NSLog(@"Link failed");
                
                NSString *progLog = [_anchorProgram programLog];
                NSLog(@"Program Log: %@", progLog);
                
                NSString *fragLog = [_anchorProgram fragmentShaderLog];
                NSLog(@"Frag Log: %@", fragLog);
                
                NSString *vertLog = [_anchorProgram vertexShaderLog];
                NSLog(@"Vert Log: %@", vertLog);
                
                _anchorProgram = nil;
            }
        }
        
        _program = [[GLProgram alloc] initWithVertexShaderFilename:@"Camera"
                                            fragmentShaderFilename:@"Camera"];
        
        if (!_program.initialized)
        {
            [_program addAttribute:@"position"];
            [_program addAttribute:@"texCoord"];
            // Link program.
            if (![_program link]) {
                NSLog(@"Link failed");
                
                NSString *progLog = [_program programLog];
                NSLog(@"Program Log: %@", progLog);
                
                NSString *fragLog = [_program fragmentShaderLog];
                NSLog(@"Frag Log: %@", fragLog);
                
                NSString *vertLog = [_program vertexShaderLog];
                NSLog(@"Vert Log: %@", vertLog);
                
                _program = nil;
            }
        }
        
        glGenBuffers(1, &_cubeBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _cubeBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(kARDatas), kARDatas, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        glGenBuffers(1, &_cubeIndicesBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _cubeIndicesBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(kARDataIndices), kARDataIndices, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_glTextureCache);
        NSAssert(err == 0, @"Failed to create CVOpenGLESTexture!");
    }
    return self;
}

- (void)createTextureFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
                       outputTexture:(CVOpenGLESTextureRef *)outputTexture
                          pixeFormat:(GLenum)pixelFormat
                          planeIndex:(NSUInteger)planeIndex{
    GLsizei width = (GLsizei)CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
    GLsizei height = (GLsizei)CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);
    
    CVReturn status = CVOpenGLESTextureCacheCreateTextureFromImage(NULL,
                                                                   _glTextureCache,
                                                                   pixelBuffer,
                                                                   NULL,
                                                                   GL_TEXTURE_2D,
                                                                   pixelFormat,
                                                                   width,
                                                                   height,
                                                                   pixelFormat,
                                                                   GL_UNSIGNED_BYTE,
                                                                   planeIndex,
                                                                   outputTexture);
    
    NSAssert(status == kCVReturnSuccess, @"获取YUV数据失败~~~~");
}

- (void)drawCameraFrame:(ARFrame *)frame
{
    [_context setDebugLabel:@"Draw Camera Frame"];
    
    glDisable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_ALWAYS);
    
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    [_program use];
    
    CVPixelBufferRef pixelBuffer = frame.capturedImage;
    [self createTextureFromPixelBuffer:pixelBuffer
                         outputTexture:&_capturedImageTextureY
                            pixeFormat:GL_LUMINANCE
                            planeIndex:0];
    [self createTextureFromPixelBuffer:pixelBuffer
                         outputTexture:&_capturedImageTextureCbCr
                            pixeFormat:GL_LUMINANCE_ALPHA
                            planeIndex:1];
    
    GLuint y = CVOpenGLESTextureGetName(_capturedImageTextureY);
    glBindTexture(GL_TEXTURE_2D, y);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    GLuint cbcr = CVOpenGLESTextureGetName(_capturedImageTextureCbCr);
    glBindTexture(GL_TEXTURE_2D, cbcr);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    static const GLfloat s_positions[] = {-1,-1,0,1,1,-1,0,1,-1,1,0,1,1,1,0,1};
    static const GLfloat s_texCoords[] = {0,1,
        1,1,
        0,0,
        1,0};
    
    GLuint position = [_program attributeIndex:@"position"];
    GLuint texCoord = [_program attributeIndex:@"texCoord"];
    GLuint capturedImageTextureY = [_program uniformIndex:@"capturedImageTextureY"];
    GLuint capturedImageTextureCbCr = [_program uniformIndex:@"capturedImageTextureCbCr"];
    
    glEnableVertexAttribArray(position);
    glEnableVertexAttribArray(texCoord);
    
    glVertexAttribPointer(position, 4, GL_FLOAT, GL_FALSE, 0, s_positions);
    glVertexAttribPointer(texCoord, 2, GL_FLOAT, GL_FALSE, 0, s_texCoords);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, y);
    glUniform1i(capturedImageTextureY, 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, cbcr);
    glUniform1i(capturedImageTextureCbCr, 1);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    CFRelease(_capturedImageTextureY);
    CFRelease(_capturedImageTextureCbCr);
    
    [_context setDebugLabel:nil];
}

#pragma mark Prepare Data

- (void)_updateBufferStates {
    // Update the location(s) to which we'll write to in our dynamically changing Metal buffers for
    //   the current frame (i.e. update our slot in the ring buffer used for the current frame)
    
    _uniformBufferIndex = (_uniformBufferIndex + 1) % kMaxBuffersInFlight;
    
    _sharedUniformBufferOffset = kAlignedSharedUniformsSize * _uniformBufferIndex;
    _anchorUniformBufferOffset = kAlignedInstanceUniformsSize * _uniformBufferIndex;
    
    _sharedUniformBufferAddress = ((uint8_t*)_sharedUniformBuffer) + _sharedUniformBufferOffset;
    _anchorUniformBufferAddress = ((uint8_t*)_anchorUniformBuffer) + _anchorUniformBufferOffset;
}

- (void)_updateSharedUniformsWithFrame:(ARFrame *)frame {
    // Update the shared uniforms of the frame
    SharedUniforms *uniforms = (SharedUniforms *)_sharedUniformBufferAddress;
    
    uniforms->viewMatrix = matrix_invert(frame.camera.transform);
    uniforms->projectionMatrix = [frame.camera projectionMatrixForOrientation:UIInterfaceOrientationLandscapeRight
                                                                 viewportSize:_sceneSize
                                                                        zNear:0.001
                                                                         zFar:1000];
    
    // Set up lighting for the scene using the ambient intensity if provided
    float ambientIntensity = 1.0;
    
    if (frame.lightEstimate) {
        ambientIntensity = frame.lightEstimate.ambientIntensity / 1000;
    }
    
    vector_float3 ambientLightColor = { 0.5, 0.5, 0.5 };
    uniforms->ambientLightColor = ambientLightColor * ambientIntensity;
    
    vector_float3 directionalLightDirection = { 0.0, 0.0, -1.0 };
    directionalLightDirection = vector_normalize(directionalLightDirection);
    uniforms->directionalLightDirection = directionalLightDirection;
    
    vector_float3 directionalLightColor = { 0.6, 0.6, 0.6};
    uniforms->directionalLightColor = directionalLightColor * ambientIntensity;
    
    uniforms->materialShininess = 30;
}

- (void)_updateAnchorsWithFrame:(ARFrame *)frame {
    // Update the anchor uniform buffer with transforms of the current frame's anchors
    NSInteger anchorInstanceCount = MIN(frame.anchors.count, kMaxAnchorInstanceCount);
    
    NSInteger anchorOffset = 0;
    if (anchorInstanceCount == kMaxAnchorInstanceCount) {
        anchorOffset = MAX(frame.anchors.count - kMaxAnchorInstanceCount, 0);
    }
    
    for (NSInteger index = 0; index < anchorInstanceCount; index++) {
        InstanceUniforms *anchorUniforms = ((InstanceUniforms *)_anchorUniformBufferAddress) + index;
        ARAnchor *anchor = frame.anchors[index + anchorOffset];
        
        // Flip Z axis to convert geometry from right handed to left handed
        matrix_float4x4 coordinateSpaceTransform = matrix_identity_float4x4;
        coordinateSpaceTransform.columns[2].z = -1.0;
        
        anchorUniforms->modelMatrix = matrix_multiply(anchor.transform, coordinateSpaceTransform);
    }
    
    _anchorInstanceCount = anchorInstanceCount;
}

- (void)_updateGameState:(ARFrame *)frame {
    [self _updateSharedUniformsWithFrame:frame];
    [self _updateAnchorsWithFrame:frame];
}

- (void)_drawAnchorGeometry
{
    glEnable(GL_CULL_FACE);
    glCullFace(GL_FRONT);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glDepthMask(GL_TRUE);
    glClear(GL_DEPTH_BUFFER_BIT);
    
    [_anchorProgram use];
 
    GLuint position = [_anchorProgram attributeIndex:@"position"];
    GLuint texCoord = [_anchorProgram attributeIndex:@"texCoord"];
    GLuint normal = [_anchorProgram attributeIndex:@"normal"];
    GLuint color = [_anchorProgram attributeIndex:@"color"];
    
    
    glEnableVertexAttribArray(position);
    glEnableVertexAttribArray(texCoord);
    glEnableVertexAttribArray(normal);
    glEnableVertexAttribArray(color);
    
    for(int i = 0; i < _anchorInstanceCount; i++){
        glUniformMatrix4fv([_anchorProgram uniformIndex:@"modelMatrix"], 1, GL_FALSE, (const GLfloat *)&_anchorUniformBuffer[i].modelMatrix);
        SharedUniforms *uniforms = (SharedUniforms *)_sharedUniformBufferAddress;
        
        glUniformMatrix4fv([_anchorProgram uniformIndex:@"projectionMatrix"], 1, GL_FALSE, (const GLfloat *)&uniforms->projectionMatrix);
        glUniformMatrix4fv([_anchorProgram uniformIndex:@"viewMatrix"], 1, GL_FALSE, (const GLfloat *)&uniforms->viewMatrix);
        glUniform3fv([_anchorProgram uniformIndex:@"ambientLightColor"], 1, (const GLfloat *)&uniforms->ambientLightColor);
        glUniform3fv([_anchorProgram uniformIndex:@"directionalLightDirection"], 1, (const GLfloat *)&uniforms->directionalLightDirection);
        glUniform3fv([_anchorProgram uniformIndex:@"directionalLightColor"], 1, (const GLfloat *)&uniforms->directionalLightColor);
        glUniform1f([_anchorProgram uniformIndex:@"materialShininess"], uniforms->materialShininess);
    
        
        glBindBuffer(GL_ARRAY_BUFFER, _cubeBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _cubeIndicesBuffer);
        
        
        glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(struct ARData), NULL);
        glVertexAttribPointer(texCoord, 2, GL_FLOAT, GL_FALSE, sizeof(struct ARData), (GLvoid *)(sizeof(GLfloat) * 3));
        glVertexAttribPointer(normal, 3, GL_FLOAT, GL_FALSE, sizeof(struct ARData), (GLvoid *)(sizeof(GLfloat) * 5));
        glVertexAttribPointer(color, 4, GL_FLOAT, GL_FALSE, sizeof(struct ARData), (GLvoid *)(sizeof(GLfloat) * 8));
        
        glDrawElements(GL_TRIANGLES, sizeof(kARDataIndices) / sizeof(GLubyte), GL_UNSIGNED_BYTE, NULL);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
}

#pragma mark Delegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    ARFrame *frame = _sesstion.currentFrame;
    if (!frame) {
        return;
    }
    
    _sceneSize = view.frame.size;
    [view bindDrawable];
    [self _updateBufferStates];
    [self _updateGameState:frame];
    [self drawCameraFrame:frame];
    [self _drawAnchorGeometry];
}

@end


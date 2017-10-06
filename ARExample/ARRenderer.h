//
//  ARRenderer.h
//  ARExample
//
//  Created by ZhangXiaoJun on 2017/7/5.
//  Copyright © 2017年 ZhangXiaoJun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>
#import <GLKit/GLKit.h>
#import <CoreVideo/CoreVideo.h>

@class GLProgram;
@interface ARRenderer : NSObject <ARSessionDelegate, GLKViewDelegate>
{
    GLProgram *_program;
    GLProgram *_anchorProgram;
    CVOpenGLESTextureCacheRef _glTextureCache;
    CVOpenGLESTextureRef _capturedImageTextureY;
    CVOpenGLESTextureRef _capturedImageTextureCbCr;
    ARSession *_sesstion;
}

- (instancetype)initWithSession:(ARSession *)session;

@property (nonatomic, readonly, strong) EAGLContext *context;

@property (nonatomic, readonly, assign) CGSize sceneSize;

@end

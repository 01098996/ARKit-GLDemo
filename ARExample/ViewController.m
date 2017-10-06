//
//  ViewController.m
//  ARExample
//
//  Created by ZhangXiaoJun on 2017/7/5.
//  Copyright © 2017年 ZhangXiaoJun. All rights reserved.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import "ARRenderer.h"

@interface ViewController ()
@property (nonatomic, strong) ARSession *session;
@property (nonatomic, strong) id<ARSessionDelegate, GLKViewDelegate> renderer;
@property (weak, nonatomic) IBOutlet GLKView *glView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.session = [ARSession new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self.glView selector:@selector(display)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    [self.session runWithConfiguration:configuration];
    
    self.renderer = [[ARRenderer alloc] initWithSession:self.session];
    self.glView.context = ((ARRenderer *)self.renderer).context;
    self.glView.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
    self.glView.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
    self.glView.drawableMultisample = GLKViewDrawableMultisampleNone;
    self.glView.delegate = self.renderer;
    self.session.delegate = self.renderer;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.displayLink invalidate];
    self.displayLink = nil;
    [self.session pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    ARFrame *currentFrame = [self.session currentFrame];
    
    // Create anchor using the camera's current position
    if (currentFrame) {
        
        // Create a transform with a translation of 0.2 meters in front of the camera
        matrix_float4x4 translation = matrix_identity_float4x4;
        translation.columns[3].z = -0.2;
        matrix_float4x4 transform = matrix_multiply(currentFrame.camera.transform, translation);
        
        // Add a new anchor to the session
        ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:transform];
        [self.session addAnchor:anchor];
    }
}


@end

//
//  FQVideoRecognizeViewController.m
//  FQFaceRecognizeSample
//
//  Created by fanqi on 2017/9/13.
//  Copyright © 2017年 fanqi. All rights reserved.
//

#import "FQVideoRecognizeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>

#define kSizeScale(size)        (size * (kScreenWidth / 375.0))
#define BtnWidth                ([UIScreen mainScreen].bounds.size.width / 3)
#define BtnHeight               50
#define IsDrawTexture           0

@interface FQVideoRecognizeViewController () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_deviceInput;
    AVCaptureVideoDataOutput *_output;
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_previewLayer;
    
    GLKView *_glkView;
    CIContext *_ciContext;
    GLKBaseEffect *_baseEffect;
    CGFloat _textureWidth;
    CGFloat _textureHeight;
    
    CIDetector *_detector;
    
    AVAssetWriter *_writer;
    AVAssetWriterInput *_assetVideoInput;
}

@property (nonatomic, weak) UIView *bottomView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UIButton *saveBtn;

@end

@implementation FQVideoRecognizeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeCapture];
    
    [self layoutUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)layoutUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.bottomView addSubview:self.cancelBtn];
    [self.bottomView addSubview:self.startBtn];
    [self.bottomView addSubview:self.saveBtn];
}

- (void)initializeCapture {
    // 获取设备
    NSArray *array = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in array) {
        if (device.position == AVCaptureDevicePositionBack) {
            _device = device;
            break;
        }
    }
    
    // 设备的输入
    _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
    
    // 捕获会话
    _session = [[AVCaptureSession alloc] init];
    
    if ([_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
        [_session setSessionPreset:AVCaptureSessionPresetMedium];
    }
    
    if ([_session canAddInput:_deviceInput]) {
        [_session addInput:_deviceInput];
    }
    
    // 输出
    _output = [[AVCaptureVideoDataOutput alloc] init];
    _output.alwaysDiscardsLateVideoFrames = YES;
    [_output setSampleBufferDelegate:self queue:dispatch_queue_create("CaptureQueue", NULL)];
    [_output setVideoSettings:@{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }
    
    {
//        // 默认预览层
//        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
//        _previewLayer.frame = self.view.bounds;
//        [self.view.layer addSublayer:_previewLayer];
    }
    
    
    {
        // 使用OpenGL绘制
        EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:glContext];

        _glkView = [[GLKView alloc] initWithFrame:self.view.bounds context:glContext];
//        _glkView.layer.contentsGravity = kCAGravityResizeAspectFill;
        _glkView.contentMode = UIViewContentModeScaleAspectFill;
        _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
        [self.view addSubview:_glkView];

        _ciContext = [CIContext contextWithEAGLContext:glContext];

        _baseEffect = [[GLKBaseEffect alloc] init];
#if IsDrawTexture
        // 纹理贴图
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ear_10" ofType:@"png"];
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:@{GLKTextureLoaderOriginBottomLeft: @(1)} error:nil];
        _baseEffect.texture2d0.enabled = GL_TRUE;
        _baseEffect.texture2d0.name = textureInfo.name;
        _baseEffect.texture2d0.target = textureInfo.target;

        _textureWidth = textureInfo.width;
        _textureHeight = textureInfo.height;

        // 如果贴图是png格式，设置贴图背景色透明
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
#else
        _baseEffect.useConstantColor = GL_TRUE;
        _baseEffect.constantColor = GLKVector4Make(1.0, 0.0, 0.0, 1.0);
#endif
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    }
    
    
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
    _detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef imgBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImg = [[CIImage alloc] initWithCVPixelBuffer:imgBuffer options:(__bridge NSDictionary *)attachments];
    
    // 原图的尺寸信息
//    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
//    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
//    NSLog(@"%f,%f",clap.size.width,clap.size.height);
    
    NSLog(@"原图尺寸: %f,%f,%f,%f",ciImg.extent.origin.x,ciImg.extent.origin.y,ciImg.extent.size.width,ciImg.extent.size.height);
    
    // 旋转原图，否则绘制的图片是旋转了90度的
    ciImg = [ciImg imageByApplyingTransform:[ciImg imageTransformForOrientation:6]];
    NSLog(@"原图旋转: %f,%f,%f,%f",ciImg.extent.origin.x,ciImg.extent.origin.y,ciImg.extent.size.width,ciImg.extent.size.height);
    
    [_glkView bindDrawable];
    [_ciContext drawImage:ciImg inRect:ciImg.extent fromRect:ciImg.extent];
    
    NSArray *features = [_detector featuresInImage:ciImg];
    
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self drawGraphWithFeatures:features forImgSize:ciImg.extent];
        });
    }
}

- (void)drawGraphWithFeatures:(NSArray *)features forImgSize:(CGRect)clap {
    for (CIFaceFeature *feature in features) {
        
        // 人脸在原始图片中的位置
        CGRect faceOriginalFrame = feature.bounds;
        NSLog(@"人脸原始坐标: %f,%f,%f,%f",faceOriginalFrame.origin.x,faceOriginalFrame.origin.y,faceOriginalFrame.size.width,faceOriginalFrame.size.height);
        
        // UIView 和 CoreImage 坐标转换
        CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
        transform = CGAffineTransformTranslate(transform, 0, -clap.size.height);
        
        CGRect faceFrame = CGRectApplyAffineTransform(faceOriginalFrame, transform);
        NSLog(@"人脸转换坐标: %f,%f,%f,%f",faceFrame.origin.x,faceFrame.origin.y,faceFrame.size.width,faceFrame.size.height);

        // 按显示区域的宽高的比率缩放
        CGSize displaySize = [UIScreen mainScreen].bounds.size;
        CGFloat scale = MIN(displaySize.height / clap.size.height, displaySize.width / clap.size.width);
        faceFrame = CGRectApplyAffineTransform(faceFrame, CGAffineTransformMakeScale(scale, scale));
        NSLog(@"人脸缩放坐标: %f,%f,%f,%f",faceFrame.origin.x,faceFrame.origin.y,faceFrame.size.width,faceFrame.size.height);

        // 人脸在图片中的坐标转换为它的容器里的坐标
        CGFloat offsetX = (displaySize.width - clap.size.width * scale) / 2;
        CGFloat offsetY = (displaySize.height - clap.size.height * scale) / 2;
        faceFrame.origin.x += offsetX;
        faceFrame.origin.y += offsetY;
        NSLog(@"人脸容器坐标: %f,%f,%f,%f",faceFrame.origin.x,faceFrame.origin.y,faceFrame.size.width,faceFrame.size.height);
        
        {
            // 测试UIView 和 CoreImage 坐标转换是否正确
//            UIBezierPath *path = [UIBezierPath bezierPathWithRect:faceFrame];
//
//            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
//            shapeLayer.fillColor = [UIColor clearColor].CGColor;
//            shapeLayer.strokeColor = [UIColor redColor].CGColor;
//            shapeLayer.lineWidth = 1;
//            shapeLayer.path = path.CGPath;
//            for (CALayer *layer in [UIApplication sharedApplication].keyWindow.layer.sublayers) {
//                if ([layer isKindOfClass:[CAShapeLayer class]]) {
//                    [layer removeFromSuperlayer];
//                }
//            }
//            [[UIApplication sharedApplication].keyWindow.layer addSublayer:shapeLayer];
        }
        
        [_baseEffect prepareToDraw];
        
        // 把人脸坐标转换成OpenGL坐标
        CGFloat glHeight = self.view.bounds.size.height / 2;
        CGFloat glWidth = self.view.bounds.size.width / 2;
        CGFloat x = faceFrame.origin.x / glWidth - 1;
        CGFloat y = 1 - faceFrame.origin.y / glHeight;

#if IsDrawTexture
        // 计算实际绘制的纹理坐标
        // 因为要绘制的是耳朵、帽子之类的，所以坐标应该在人脸的上方
        CGFloat width = faceFrame.size.width;
        CGFloat height = width / _textureWidth * _textureHeight;
        CGRect textureFrame = CGRectMake(faceFrame.origin.x, faceFrame.origin.y - height, width, height);

        // 转换成OpenGL坐标
        GLKVector3 leftBot = GLKVector3Make(x,
                                            y,
                                            0.0);
        GLKVector3 leftTop = GLKVector3Make(x,
                                            1 - CGRectGetMinY(textureFrame) / glHeight, 0.0);
        GLKVector3 rightBot = GLKVector3Make(CGRectGetMaxX(textureFrame) / glWidth - 1,
                                             y,
                                             0.0);
        GLKVector3 rightTop = GLKVector3Make(CGRectGetMaxX(textureFrame) / glWidth - 1,
                                             1 - CGRectGetMinY(textureFrame) / glHeight,
                                             0.0);

        // 顶点坐标（包含纹理坐标）
        float vertices[] = {
            leftTop.x, leftTop.y, 0.0,      0.0, 1.0,
            leftBot.x, leftBot.y, 0.0,      0.0, 0.0,
            rightBot.x, rightBot.y, 0.0,    1.0, 0.0,

            leftTop.x, leftTop.y, 0.0,      0.0, 1.0,
            rightTop.x, rightTop.y, 0.0,    1.0, 1.0,
            rightBot.x, rightBot.y, 0.0,    1.0, 0.0,
        };
#else
        // 转换成OpenGL坐标
        GLKVector3 leftTop = GLKVector3Make(x,
                                            y,
                                            0.0);
        GLKVector3 leftBot = GLKVector3Make(x,
                                            1 - CGRectGetMaxY(faceFrame) / glHeight,
                                            0.0);
        GLKVector3 rightTop = GLKVector3Make(CGRectGetMaxX(faceFrame) / glWidth - 1,
                                             y,
                                             0.0);
        GLKVector3 rightBot = GLKVector3Make(CGRectGetMaxX(faceFrame) / glWidth - 1,
                                             1 - CGRectGetMaxY(faceFrame) / glHeight
                                             , 0.0);
        // 顶点坐标（不包含纹理坐标）
        GLKVector3 vertices[6] = {
            leftTop,
            leftBot,
            rightBot,

            leftTop,
            rightTop,
            rightBot,
        };
#endif

        // 顶点缓冲对象 Vertex Buffer Object
        GLuint VBO; // 缓冲ID
        glGenBuffers(1, &VBO); // 生成标识符
        glBindBuffer(GL_ARRAY_BUFFER, VBO); // 将缓冲对象绑定到 GL_ARRAY_BUFFER 目标上
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW); // 把顶点数据从 CPU 内存复制到 GPU 的缓冲内存中


#if IsDrawTexture
        // 顶点属性
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GL_FLOAT), (void *)0);

        // 纹理
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GL_FLOAT), (GLfloat *)NULL + 3);
#else
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), (void *)0);
#endif

        glDrawArrays(GL_TRIANGLES, 0, 6);
    }
    
    [_glkView display];
}

#pragma mark - Events

- (void)cancelAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)startAction {
    if (_session) {
        [_session startRunning];
    }
}

- (void)saveAction {
    
}

#pragma mark - Getter

- (UIView *)bottomView {
    if (!_bottomView) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - BtnHeight, self.view.frame.size.width, BtnHeight)];
        view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        [self.view addSubview:view];
        _bottomView = view;
    }
    return _bottomView;
}

- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        UIButton *btn = [self buttonWithTitle:@"取消" frame:CGRectMake(0, 0, BtnWidth, BtnHeight)];
        [btn addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
        _cancelBtn = btn;
    }
    return _cancelBtn;
}

- (UIButton *)startBtn {
    if (!_startBtn) {
        UIButton *btn = [self buttonWithTitle:@"开始" frame:CGRectMake(BtnWidth, 0, BtnWidth, BtnHeight)];
        [btn addTarget:self action:@selector(startAction) forControlEvents:UIControlEventTouchUpInside];
        _startBtn = btn;
    }
    return _startBtn;
}

- (UIButton *)saveBtn {
    if (!_saveBtn) {
        UIButton *btn = [self buttonWithTitle:@"保存" frame:CGRectMake(BtnWidth * 2, 0, BtnWidth, BtnHeight)];
        [btn addTarget:self action:@selector(saveAction) forControlEvents:UIControlEventTouchUpInside];
        _saveBtn = btn;
    }
    return _saveBtn;
}

- (UIButton *)buttonWithTitle:(NSString *)title frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:16];
    return btn;
}

@end

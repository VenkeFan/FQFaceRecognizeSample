//
//  FQVideoRecognizeViewController.m
//  FQFaceRecognizeSample
//
//  Created by fanqi on 2017/9/13.
//  Copyright © 2017年 fanqi. All rights reserved.
//

#import "FQVideoRecognizeViewController.h"
#import <AVFoundation/AVFoundation.h>

#define BtnWidth            ([UIScreen mainScreen].bounds.size.width / 3)
#define BtnHeight           50

@interface FQVideoRecognizeViewController () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_deviceInput;
    AVCaptureVideoDataOutput *_output;
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_previewLayer;
    
    
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
    
    if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
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
    
    // 预览层
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:_previewLayer];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
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

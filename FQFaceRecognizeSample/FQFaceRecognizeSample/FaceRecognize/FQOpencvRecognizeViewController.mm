//
//  FQOpencvRecognizeViewController.m
//  FQFaceRecognizeSample
//
//  Created by fan qi on 2018/8/10.
//  Copyright © 2018年 fanqi. All rights reserved.
//

#import "FQOpencvRecognizeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/imgcodecs/ios.h>
#import "FQFacePointWrapper.h"

@interface FQOpencvRecognizeViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate> {
    
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_deviceInput;
    AVCaptureVideoDataOutput *_output;
    AVCaptureMetadataOutput *_metaout;
    AVCaptureSession *_session;
    
    AVAssetWriter *_writer;
    AVAssetWriterInput *_assetVideoInput;
    
    NSArray *_currentMetadata;
    
    FQFacePointWrapper *_facePoint;
}

@property (nonatomic, strong) UIImageView *cameraView;

@end

@implementation FQOpencvRecognizeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview: self.cameraView];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _facePoint = [[FQFacePointWrapper alloc] init];
        _currentMetadata = [NSArray array];
        
        NSArray *array = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in array) {
            if (device.position == AVCaptureDevicePositionFront) {
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
        
        _metaout = [[AVCaptureMetadataOutput alloc] init];
        [_metaout setMetadataObjectsDelegate:self queue:dispatch_queue_create("MetadataOutputQueue", NULL)];
        
        if ([_session canAddOutput:_metaout]) {
            [_session addOutput:_metaout];
        }
        
        if ([_metaout.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeFace]) {
            [_metaout setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
        }
        
        for (AVCaptureVideoDataOutput* output in _session.outputs) {
            for (AVCaptureConnection * av in output.connections) {
                //判断是否是前置摄像头状态
                if (av.supportsVideoMirroring) {
                    //镜像设置
                    av.videoOrientation = AVCaptureVideoOrientationPortrait;
                    if (_device.position == AVCaptureDevicePositionFront) {
                        av.videoMirrored = YES;
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
           [_session startRunning];
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    NSMutableArray *bounds = [NSMutableArray arrayWithCapacity:0];
    //每一帧，我们都看一下  self.currentMetadata 里面有没有东西，然后将里面的
    //AVMetadataFaceObject 转换成  AVMetadataObject，其中AVMetadataObject 的bouns 就是人脸的位置 ，我们将bouns 存到数组中
    for (AVMetadataFaceObject *faceobject in _currentMetadata) {
        AVMetadataObject *face = [captureOutput transformedMetadataObjectForMetadataObject:faceobject
                                                                                connection:connection];
        [bounds addObject:[NSValue valueWithCGRect:face.bounds]];
    }
    
    UIImage *image = [self imageFromPixelBuffer:sampleBuffer];
    cv::Mat mat;

    UIImageToMat(image, mat);

    //获取关键点，将脸部信息的数组 和 相机流 传进去
    NSArray *facesLandmarks = [_facePoint detecitonOnSampleBuffer:sampleBuffer inRects:bounds];

    // 绘制68 个关键点
    for (NSArray *landmarks in facesLandmarks) {
        for (NSValue *point in landmarks) {
            CGPoint p = [point CGPointValue];
            cv::rectangle(mat, cv::Rect(p.x, p.y, 4, 4), cv::Scalar(255, 0 , 0, 255), -1);
        }
    }

    for (NSValue *rect in bounds) {
        CGRect r = [rect CGRectValue];
        //画框
        cv::rectangle(mat, cv::Rect(r.origin.x, r.origin.y, r.size.width, r.size.height), cv::Scalar(255, 0, 0, 255));
    }

    //这里不考虑性能 直接怼Image
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cameraView.image = MatToUIImage(mat);
    });
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    //当检测到了人脸会走这个回调
    _currentMetadata = metadataObjects;
}

#pragma mark - Private

- (UIImage*)imageFromPixelBuffer:(CMSampleBufferRef)p {
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(p);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = (uint8_t *)CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    return image;
}

#pragma mark - Getter

- (UIImageView *)cameraView {
    if (!_cameraView) {
        _cameraView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _cameraView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _cameraView;
}

@end

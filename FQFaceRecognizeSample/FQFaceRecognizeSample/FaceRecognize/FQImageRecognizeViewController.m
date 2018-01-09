//
//  FQImageRecognizeViewController.m
//  FQFaceRecognizeSample
//
//  Created by fanqi on 2017/9/13.
//  Copyright © 2017年 fanqi. All rights reserved.
//

#import "FQImageRecognizeViewController.h"
#import "UIImage+Extension.h"
#import <CoreImage/CoreImage.h>

@interface FQImageRecognizeViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) CALayer *previewLayer;

@end

@implementation FQImageRecognizeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self layoutUI];
    
    {
        UIImage *img = [UIImage imageNamed:@"3.jpg"];
        self.previewLayer.contents = (__bridge id)img.CGImage;
        [self startRecognize:img];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)layoutUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"拍照" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn sizeToFit];
    [btn addTarget:self action:@selector(btnClicked) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
    img = [img fixOrientation];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        self.previewLayer.contents = (__bridge id)img.CGImage;
        [self startRecognize:img];
    }];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

#pragma mark - 

- (void)startRecognize:(UIImage *)image {
    [self.previewLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyHigh, CIDetectorAccuracy, nil];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    CIImage *ciImg = [CIImage imageWithCGImage:image.CGImage];
    NSArray<CIFeature *> *features = [detector featuresInImage:ciImg];
    for (CIFaceFeature *feature in features) {
        
        // 人脸在原始图片中的位置
        CGRect faceOriginalFrame = feature.bounds;
        
        // UIView 和 CoreImage 坐标转换
        CGSize ciImgSize = ciImg.extent.size;
        CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
        transform = CGAffineTransformTranslate(transform, 0, -ciImgSize.height);
        
        CGRect faceFrame = CGRectApplyAffineTransform(faceOriginalFrame, transform);
        
        // 按显示区域的宽高的比率缩放
        CGSize displaySize = self.previewLayer.frame.size;
        CGFloat scale = MIN(displaySize.height / image.size.height, displaySize.width / image.size.width);
        faceFrame = CGRectApplyAffineTransform(faceFrame, CGAffineTransformMakeScale(scale, scale));
        
        // 人脸在图片中的坐标转换为它的容器里的坐标
        CGFloat offsetX = (displaySize.width - ciImgSize.width * scale) / 2;
        CGFloat offsetY = (displaySize.height - ciImgSize.height * scale) / 2;
        faceFrame.origin.x += offsetX;
        faceFrame.origin.y += offsetY;
        
       
        {
            // 画人脸方框
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:faceFrame];
            
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.fillColor = [UIColor clearColor].CGColor;
            shapeLayer.strokeColor = [UIColor redColor].CGColor;
            shapeLayer.lineWidth = 1;
            shapeLayer.path = path.CGPath;
            
            [self.previewLayer addSublayer:shapeLayer];
        }
        
        
        {
            // 嘴巴
            if (feature.hasMouthPosition) {
                CGPoint originalMouth = feature.mouthPosition;
                CGPoint mouth = CGPointApplyAffineTransform(originalMouth, transform);
                mouth = CGPointApplyAffineTransform(mouth, CGAffineTransformMakeScale(scale, scale));
                mouth.x += offsetX;
                mouth.y += offsetY;
                CGRect mouthFrame = CGRectMake(mouth.x - 10, mouth.y - 5, 20, 10);
                
                UIBezierPath *path = [UIBezierPath bezierPathWithRect:mouthFrame];
                
                CAShapeLayer *shapeLayer = [CAShapeLayer layer];
                shapeLayer.fillColor = [UIColor clearColor].CGColor;
                shapeLayer.strokeColor = [UIColor redColor].CGColor;
                shapeLayer.lineWidth = 1;
                shapeLayer.path = path.CGPath;
                
                [self.previewLayer addSublayer:shapeLayer];
            }
        }
        
        
        {
            // 左眼
            if (feature.hasLeftEyePosition) {
                CGPoint originalEye = feature.leftEyePosition;
                CGPoint eye = CGPointApplyAffineTransform(originalEye, transform);
                eye = CGPointApplyAffineTransform(eye, CGAffineTransformMakeScale(scale, scale));
                eye.x += offsetX;
                eye.y += offsetY;
                CGRect eyeFrame = CGRectMake(eye.x - 5, eye.y - 5, 10, 10);
                
                UIBezierPath *path = [UIBezierPath bezierPathWithRect:eyeFrame];
                
                CAShapeLayer *shapeLayer = [CAShapeLayer layer];
                shapeLayer.fillColor = [UIColor clearColor].CGColor;
                shapeLayer.strokeColor = [UIColor redColor].CGColor;
                shapeLayer.lineWidth = 1;
                shapeLayer.path = path.CGPath;
                
                [self.previewLayer addSublayer:shapeLayer];
            }
        }
        
        
        {
            if (feature.hasRightEyePosition) {
                CGPoint originalEye = feature.rightEyePosition;
                CGPoint eye = CGPointApplyAffineTransform(originalEye, transform);
                eye = CGPointApplyAffineTransform(eye, CGAffineTransformMakeScale(scale, scale));
                eye.x += offsetX;
                eye.y += offsetY;
                CGRect eyeFrame = CGRectMake(eye.x - 5, eye.y - 5, 10, 10);
                
                UIBezierPath *path = [UIBezierPath bezierPathWithRect:eyeFrame];
                
                CAShapeLayer *shapeLayer = [CAShapeLayer layer];
                shapeLayer.fillColor = [UIColor clearColor].CGColor;
                shapeLayer.strokeColor = [UIColor purpleColor].CGColor;
                shapeLayer.lineWidth = 1;
                shapeLayer.path = path.CGPath;
                
                [self.previewLayer addSublayer:shapeLayer];
            }
        }
    }
}

#pragma mark - Events

- (void)btnClicked {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Getter

- (CALayer *)previewLayer {
    if (!_previewLayer) {
        CALayer *layer = [CALayer layer];
        layer.frame = self.view.bounds;
        layer.contentsGravity = kCAGravityResizeAspect; // 必须设置为这个
        [self.view.layer addSublayer:layer];
        _previewLayer = layer;
    }
    return _previewLayer;
}

@end

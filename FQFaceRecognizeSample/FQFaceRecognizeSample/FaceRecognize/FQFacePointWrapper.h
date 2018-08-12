//
//  FQFacePointWrapper.h
//  FQFaceRecognizeSample
//
//  Created by fan qi on 2018/8/11.
//  Copyright © 2018年 fanqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface FQFacePointWrapper : NSObject

- (NSArray <NSArray <NSValue *> *>*)detecitonOnSampleBuffer:(CMSampleBufferRef)sampleBuffer
                                                    inRects:(NSArray<NSValue *> *)rects;

@end

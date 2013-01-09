//
//  KNFFmpegFileReader.h
//  GLKDrawTest
//
//  Created by Choi Yeong Hyeon on 12. 11. 25..
//  Copyright (c) 2012년 Choi Yeong Hyeon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "avcodec.h"
#import "avformat.h"


@interface KNFFmpegFileReader : NSObject

@property (assign) AVCodecContext* codecCtx;
@property (readonly) int videoStreamIndex;

- (id)initWithFilepath:(NSString *)filepath;
- (void)readFrame:(void(^)(AVPacket* packet))completion;
- (void)cancelReadFrame;
@end

//
//  KNFFMpegFrameReder.m
//  FFMpegFrameReder
//
//  Created by cyh on 12. 12. 17..
//  Copyright (c) 2012년 cyh3813. All rights reserved.
//

#import "KNFFMpegFrameReder.h"
#import <libavformat/avformat.h>

@interface KNFFMpegFrameReder () {
    void(^readBlock_)(UInt8* data, int dataSize, int width, int height, int codecid);
    void(^finishBlock_)(BOOL finish);
    
    AVFormatContext*    frameContext_;
}
@end


@implementation KNFFMpegFrameReder

@synthesize filePath = _filePath;
@synthesize cancel = _cancel;

- (void)dealloc {
    
    [_filePath release];
    
    if (readBlock_) {
        [readBlock_ release];
        readBlock_ = nil;
    }
    
    if (finishBlock_) {
        [finishBlock_ release];
        finishBlock_ = nil;
    }
    
    [super dealloc];
}

- (id)initWidthFilePath:(NSString *)filepath {
    
    self = [super init];
    if (self) {
        self.filePath = filepath;
        
        if ([self initFFmpeg] == NO) {
            return nil;
        }
    }
    return self;
}


#pragma mark - Private
- (BOOL)initFFmpeg {
    
    av_register_all();
    if (avformat_open_input(&frameContext_, [self.filePath UTF8String], NULL, NULL) != 0) {

        frameContext_ = NULL;
        NSLog(@"Couldn't open file [%@]", self.filePath);
        
        return NO;
    }
    return YES;
}


- (void)readFrame {

    int videoStream = -1;
    for (int i = 0; i < frameContext_->nb_streams; i++) {
        if (frameContext_->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStream = i;
            break;
        }
    }
    if (videoStream == -1) {
        
        NSLog(@"(%s VideoStream can't found.", __func__);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (finishBlock_) {
                finishBlock_(NO);
            }
        });
        return;
    }

    AVCodecContext* pCodecCtx = frameContext_->streams[videoStream]->codec;
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    AVPacket packet;
    while (av_read_frame(frameContext_, &packet) >= 0) {
        
        if (readBlock_)
            readBlock_(packet.data, packet.size, pCodecCtx->width, pCodecCtx->height, pCodecCtx->codec_id);

        av_free_packet(&packet);
        
        if (_cancel)
            break;
    }
    
    avcodec_close(pCodecCtx);
    avformat_close_input(&frameContext_);
    frameContext_ = NULL;
    
    [pool release];
    
    if (finishBlock_) {
        dispatch_async(dispatch_get_main_queue(), ^{
            finishBlock_(!_cancel);
        });
    }
}


#pragma mark - Public
- (void)startFrameRead:(void(^)(UInt8* data, int dataSize, int width, int height, int codecid))readBlock
                finish:(void(^)(BOOL finish))finishBlock {
    
    if (frameContext_ == nil) {
        NSLog(@"Frame read done.");
        return;
    }

    readBlock_ = [readBlock copy];
    finishBlock_ = [finishBlock copy];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self readFrame];
    });
}

- (void)canceFrameRead {
    _cancel = YES;
}

@end

//
//  KNFFmpegFileReader.m
//  GLKDrawTest
//
//  Created by Choi Yeong Hyeon on 12. 11. 25..
//  Copyright (c) 2012년 Choi Yeong Hyeon. All rights reserved.
//

#import "KNFFmpegFileReader.h"

@interface KNFFmpegFileReader() {
    AVFormatContext* pFormatCtx;
    int videoStream;
    BOOL cancelReadFrame;
}

@property (copy, nonatomic) NSString* filepath;
@end

@implementation KNFFmpegFileReader
@synthesize codecCtx            = _codecCtx;
@synthesize filepath            = _filepath;
@synthesize videoStreamIndex    = _videoStreamIndex;

- (void)dealloc {
    [_filepath release];
    
    if (_codecCtx) {
        avcodec_close(_codecCtx);
        _codecCtx = NULL;
    }
    
    if (pFormatCtx) {
        avformat_close_input(&pFormatCtx);
        pFormatCtx = NULL;
    }
    [super dealloc];
}

- (id)initWithFilepath:(NSString *)filepath {

    self = [super init];
    if (self) {
        self.filepath = filepath;
        if ([self initInputfile] == NO)
            return nil;
    }
    return self;
}

- (BOOL)initInputfile {
    
    av_register_all();

    if (avformat_open_input(&pFormatCtx, [_filepath UTF8String], 0, 0) != 0) {
        NSLog(@"avformat_open_input failed.");
        return NO;
    }
    
    if (avformat_find_stream_info(pFormatCtx, 0) < 0) {
        NSLog(@"avformat_find_stream_info failed.");
        return NO;
    }
    
    for (int i = 0; i < pFormatCtx->nb_streams; i++) {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            _videoStreamIndex = i;
            break;
        }
    }
    
    if (videoStream == -1) {
        NSLog(@"videoStream found failed.");
        return NO;
    }

    _codecCtx = pFormatCtx->streams[videoStream]->codec;
    
    return YES;
}

- (void)readFrame:(void(^)(AVPacket* packet))completion {

    if (cancelReadFrame) {
        NSLog(@"Frame read canceled.");
        return;
    }
    
    AVPacket packet;
    while (av_read_frame(pFormatCtx, &packet) >= 0) {
        
        if (packet.stream_index == _videoStreamIndex) {
            completion(&packet);
        }
        av_free_packet(&packet);
        
        if (cancelReadFrame) {
            av_free_packet(&packet);
            break;
        }
    }
    avcodec_close(_codecCtx);
    _codecCtx = NULL;
    
    avformat_close_input(&pFormatCtx);
    pFormatCtx = NULL;
}

- (void)cancelReadFrame {
    cancelReadFrame = YES;
}

@end

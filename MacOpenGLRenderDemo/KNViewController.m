//
//  KNViewController.m
//  MacOpenGLRenderDemo
//
//  Created by cyh on 13. 1. 7..
//  Copyright (c) 2013년 cyh3813. All rights reserved.
//

#import "KNViewController.h"
#import "KNFFmpegFileReader.h"
#import "KNFFmpegDecoder.h"


@implementation KNViewController

@synthesize glView = _glView;
@synthesize glView2 = _glView2;
@synthesize renderButton = _renderButton;

- (void)dealloc {
    
    [_glView release];
    [_glView2 release];
    
    [_renderButton release];
    
    [super dealloc];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (IBAction)readFrames:(id)sender {

    [_renderButton setEnabled:NO];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"mov" ofType:@"mp4"];
        KNFFmpegFileReader* reader = [[KNFFmpegFileReader alloc] initWithFilepath:filePath];
        KNFFmpegDecoder* dec = [[KNFFmpegDecoder alloc] initWithCodecContext:reader.codecCtx
                                            videoStreamIndex:reader.videoStreamIndex];
        [reader readFrame:^(AVPacket *packet) {
            [dec decodeFrame:packet completion:^(NSDictionary *frameData) {
                
                [frameData retain];
                [_glView renderData:frameData];
//                [_glView2 renderData:frameData];
                [frameData release];
            }];
        }];
        [dec endDecode];
        [dec release];
        [reader release];
        
        [_glView clear:0 g:0 b:0 a:1];
        
        [_renderButton setEnabled:YES];
    });
}

- (IBAction)clear:(id)sender {
    [_glView clear:1 g:0 b:0 a:1];    
}

- (IBAction)fillImage:(id)sender {
    [_glView setAspectFit:NO];
}

- (IBAction)fitImage:(id)sender {
    [_glView setAspectFit:YES];
}

@end

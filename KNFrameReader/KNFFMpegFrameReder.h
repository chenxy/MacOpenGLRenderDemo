//
//  KNFFMpegFrameReder.h
//  FFMpegFrameReder
//
//  Created by cyh on 12. 12. 17..
//  Copyright (c) 2012년 cyh3813. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KNFFMpegFrameReder : NSObject
@property (copy, nonatomic) NSString* filePath;
@property (assign) BOOL cancel;

- (id)initWidthFilePath:(NSString *)filepath;
- (void)startFrameRead:(void(^)(UInt8* data, int dataSize, int width, int height, int codecid))readBlock
                finish:(void(^)(BOOL finish))finishBlock;
- (void)canceFrameRead;

- (BOOL)initFFmpeg;
- (void)readFrame;

@end

//
//  KNGLView.h
//  MacOpenGLRenderDemo
//
//  Created by cyh on 13. 1. 7..
//  Copyright (c) 2013년 cyh3813. All rights reserved.
//

/**
    IB에서 NSOpenglView의 DoubleBuffer Option On.
    Renderer에서 Accelated Renderer 선택.
 */
#import <Foundation/Foundation.h>

@interface KNGLView : NSOpenGLView

@property (assign) BOOL aspectFit;

- (void)renderData:(NSDictionary *)frameData;

- (void)renderVDA:(CVImageBufferRef)buffer;

- (void)clear:(float)r g:(float)g b:(float)r a:(float)a;
@end

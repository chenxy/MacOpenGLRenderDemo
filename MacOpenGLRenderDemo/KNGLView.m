//
//  KNGLView.m
//  MacVDA
//
//  Created by cyh on 13. 1. 14..
//  Copyright (c) 2013년 cyh3813. All rights reserved.
//

#import "KNGLView.h"

@interface KNGLView ()

@end

@implementation KNGLView

@synthesize backingWidth            = _backingWidth;
@synthesize backingHeight           = _backingHeight;
@synthesize clearBackground         = _clearBackground;
@synthesize aspectFit               = _aspectFit;

#pragma mark - View Cycle
- (void)drawRect:(NSRect)dirtyRect
{
    if (_clearBackground)
        [self clear:0.0f g:0.0f b:0.0f a:1.0f];
}

- (void)reshape {
    _backingWidth = self.bounds.size.width;
    _backingHeight = self.bounds.size.height;
}

- (void)prepareOpenGL {
    
    NSOpenGLPixelFormatAttribute	mAttrs []	= {
		NSOpenGLPFAWindow,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFAColorSize,		(NSOpenGLPixelFormatAttribute)32,
		NSOpenGLPFAAlphaSize,		(NSOpenGLPixelFormatAttribute)8,
		NSOpenGLPFADepthSize,		(NSOpenGLPixelFormatAttribute)24,
		(NSOpenGLPixelFormatAttribute) 0
	};
    [self setPixelFormat:[[[NSOpenGLPixelFormat alloc] initWithAttributes: mAttrs] autorelease]];

    _clearBackground = YES;
}


#pragma mark - Public
- (void)clear:(float)r g:(float)g b:(float)b a:(float)a {

    _clearBackground = YES;
    
    [self lockFocusIfCanDraw];
    glClearColor(r, g, b, a);
    glClear(GL_COLOR_BUFFER_BIT);
    [[self openGLContext] flushBuffer];
    [self unlockFocus];
}
@end

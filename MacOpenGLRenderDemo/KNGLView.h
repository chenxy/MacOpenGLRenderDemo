//
//  KNGLView.h
//  MacVDA
//
//  Created by cyh on 13. 1. 14..
//  Copyright (c) 2013년 cyh3813. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KNGLView : NSOpenGLView

@property (assign, readonly) int backingWidth;
@property (assign, readonly) int backingHeight;
@property (assign) BOOL clearBackground;
@property (assign) BOOL aspectFit;
- (void)clear:(float)r g:(float)g b:(float)b a:(float)a;
@end

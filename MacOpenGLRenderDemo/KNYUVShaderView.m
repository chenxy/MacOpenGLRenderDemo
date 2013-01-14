//
//  KNGLView.m
//  MacOpenGLRenderDemo
//
//  Created by cyh on 13. 1. 7..
//  Copyright (c) 2013년 cyh3813. All rights reserved.
//

#import "KNYUVShaderView.h"
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <OpenGL/glext.h>
#import <GLUT/GLUT.h>
#import <OpenGL/CGLIOSurface.h>

#define GL_SHADER_LOG_BUFFER        32768

/**
 YUV420 to RGB Shader Program
 */
const GLcharARB* shaderText=
"uniform sampler2DRect Ytex;\n"
"uniform sampler2DRect Utex,Vtex;\n"
"uniform float imageHeight;\n"
"void main(void) {\n"
"  float nx,ny,r,g,b,y,u,v;\n"
"  vec4 txl,ux,vx;"
"  nx=gl_TexCoord[0].x;\n"
"  ny=imageHeight-gl_TexCoord[0].y;\n"
"  y=texture2DRect(Ytex,vec2(nx,ny)).r;\n"
"  u=texture2DRect(Utex,vec2(nx/2.0,ny/2.0)).r;\n"
"  v=texture2DRect(Vtex,vec2(nx/2.0,ny/2.0)).r;\n"

"  y=1.1643*(y-0.0625);\n"
"  u=u-0.5;\n"
"  v=v-0.5;\n"

"  r=y+1.5958*v;\n"
"  g=y-0.39173*u-0.81290*v;\n"
"  b=y+2.017*u;\n"

"  gl_FragColor=vec4(r,g,b,1.0);\n"
"}\n";


@interface KNYUVShaderView() {
    GLhandleARB     FSHandle_;
    GLhandleARB     PHandle_;
}
- (void)initOpenGLShader;
- (void)updateVertex:(int)width height:(int)height;
- (void)updateViewPort;
- (void)makeTexture:(NSDictionary *)frameData;

@end

@implementation KNYUVShaderView

@synthesize aspectFit = _aspectFit;

#pragma mark - View Cycle
- (void)dealloc {
    
    glUseProgramObjectARB(0);
    glDeleteObjectARB(PHandle_);
    
    [self clearGLContext];

    [super dealloc];
}

- (void)reshape {
    [super reshape];    
    [self updateViewPort];
}

- (void)prepareOpenGL {
    [super prepareOpenGL];
    
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

    [self initOpenGLShader];
}


#pragma mark - Private
- (void)initOpenGLShader {

    [[self openGLContext] makeCurrentContext];
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, self.backingWidth, 0, self.backingHeight, -1, 1);
    glViewport(0, 0, self.backingWidth, self.backingHeight);

    int i;
    PHandle_=glCreateProgramObjectARB();
    FSHandle_=glCreateShaderObjectARB(GL_FRAGMENT_SHADER_ARB);
    
    glShaderSourceARB(FSHandle_, 1, &shaderText, NULL);
    glCompileShaderARB(FSHandle_);
    

    char* log = malloc(GL_SHADER_LOG_BUFFER);
    glGetObjectParameterivARB(FSHandle_, GL_OBJECT_COMPILE_STATUS_ARB, &i);
    glGetInfoLogARB(FSHandle_, GL_SHADER_LOG_BUFFER, NULL, log);
    printf("Compile Log: %s\n", log);
    free(log);
    
    glAttachObjectARB(PHandle_, FSHandle_);
    glLinkProgramARB(PHandle_);
    
    log = malloc(GL_SHADER_LOG_BUFFER);
    glGetInfoLogARB(PHandle_, GL_SHADER_LOG_BUFFER, NULL, log);
    printf("Link Log: %s\n", log);
    free(log);
    
    glUseProgramObjectARB(PHandle_);
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clear:0 g:0 b:0 a:1];
    });
}


- (void)updateViewPort {
    [self lockFocusIfCanDraw];
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, self.backingWidth, 0, self.backingHeight, -1, 1);
    glViewport(0, 0, self.backingWidth, self.backingHeight);
    
    [self unlockFocus];
}


- (void)makeTexture:(NSDictionary *)frameData {
    
    GLint width     = (GLint)[[frameData objectForKey:@"width"] integerValue];
    GLint heigth    = (GLint)[[frameData objectForKey:@"height"] integerValue];
    
    NSData* luma        = [frameData objectForKey:@"luma"];
    NSData* chromaB     = [frameData objectForKey:@"chromaB"];
    NSData* chromaR     = [frameData objectForKey:@"chromaR"];

    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    const GLint kTextureTarget = GL_TEXTURE_RECTANGLE_ARB;
    
    // *셰이더 프로그램으로 이미지의 높이를 전송.
    int i_imageHeight = glGetUniformLocationARB(PHandle_, "imageHeight");
    glUniform1f(i_imageHeight, (float)heigth);
    
    const UInt8 *pixels[3] = { luma.bytes, chromaB.bytes, chromaR.bytes };
    const GLint widths[3]  = { width, width / 2, width / 2 };
    const GLint heights[3] = { heigth, heigth / 2, heigth / 2 };
    const GLcharARB* varShaderTex[3] = {"Ytex", "Utex", "Vtex"};

    int shaderTex;
    for (int i = 0; i < 3; i++) {
        
        glActiveTexture(GL_TEXTURE0 + i);
        shaderTex = glGetUniformLocationARB(PHandle_, varShaderTex[i]);
        glUniform1iARB(shaderTex, i);
        glBindTexture(kTextureTarget, i);
        
        glTexParameteri(kTextureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(kTextureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
        glTexImage2D(kTextureTarget, 0, GL_LUMINANCE, widths[i], heights[i], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels[i]);
    }
}


- (void)updateVertex:(int)width height:(int)height {
    
    float dH, dW, dd, h, w, wMargin, hMargin;
    if (_aspectFit == NO) {
        wMargin = 0;
        hMargin = 0;
        w       = self.backingWidth;
        h       = self.backingHeight;
    } else {
        dH      = (float)self.backingHeight / height;
        dW      = (float)self.backingWidth	  / width;
        dd      = MIN(dH, dW);
        h       = (height * dd / (float)self.backingHeight);
        w       = (width  * dd / (float)self.backingWidth);
        w       = w * self.backingWidth;
        h       = h * self.backingHeight;
        wMargin = (self.backingWidth - w) / 2;
        hMargin = (self.backingHeight - h) / 2;
    }
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBegin(GL_QUADS);
    
    ///left,bottom
    glTexCoord2i(0, 0);
    glVertex2i(wMargin, hMargin);
    
    ///right,bottom
    glTexCoord2i(width, 0);
    glVertex2i(w + wMargin, hMargin);
    
    ///Right,top
    glTexCoord2i(width, height);
    glVertex2i(w + wMargin, h + hMargin);
    
    //left,top
    glTexCoord2i(0, height);
    glVertex2i(wMargin, h + hMargin);
    
    glEnd();
}

#pragma mark - Public
- (void)render:(NSDictionary *)frameData {

    if (self.isHidden) {
        NSLog(@" hidden");
        return;
    }
    
    self.clearBackground = NO;
    
    [self lockFocusIfCanDraw];
    
    GLint width     = (GLint)[[frameData objectForKey:@"width"] integerValue];
    GLint height    = (GLint)[[frameData objectForKey:@"height"] integerValue];
        
    [self makeTexture:frameData];
    
    [self updateVertex:width height:height];
        
    [[self openGLContext] flushBuffer];
    
    [self unlockFocus];
}

@end

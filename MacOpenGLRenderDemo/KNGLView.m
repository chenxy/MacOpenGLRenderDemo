//
//  KNGLView.m
//  MacOpenGLRenderDemo
//
//  Created by cyh on 13. 1. 7..
//  Copyright (c) 2013년 cyh3813. All rights reserved.
//

#import "KNGLView.h"
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <OpenGL/glext.h>
#import <GLUT/GLUT.h>

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


@interface KNGLView() {

    GLint           backingWidth_;
    GLint           backingHeight_;
    
    GLhandleARB     FSHandle_;
    GLhandleARB     PHandle_;
    
    GLuint			surfaceTexture_;
	IOSurfaceRef	surface_;

}
- (void)initOpenGLShader;
- (void)initVDARender;
- (void)render:(BOOL)vda;
- (void)updateViewPort;
- (void)makeTexture:(NSDictionary *)frameData;
- (void)makeSufaceToTexture:(IOSurfaceRef)suface;
@end

@implementation KNGLView

@synthesize aspectFit = _aspectFit;

#pragma mark - View Cycle
- (void)dealloc {
    
    glUseProgramObjectARB(0);
    glDeleteObjectARB(PHandle_);
    
    [self clearGLContext];
    
    if (surfaceTexture_)
        glDeleteTextures(1, &surfaceTexture_);
    
    if (surface_)
        CFRelease(surface_);
    
    [super dealloc];
}
- (void)awakeFromNib {
    [super awakeFromNib];
    
    NSLog(@"NSOpenGLView Frame : %f %f", self.frame.size.width, self.frame.size.height);
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)reshape {
    [super reshape];    
    [self updateViewPort];
}

- (void)prepareOpenGL {
    
    [super prepareOpenGL];
    [self initOpenGLShader];
    [self initVDARender];
}

///뷰사라졌을대 처리. (윈도우 깨졌을때)

#pragma mark - Private
- (void)initOpenGLShader {
    
    [[self openGLContext] makeCurrentContext];
    
    backingWidth_ = self.frame.size.width;
    backingHeight_ = self.frame.size.height;

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, backingWidth_, 0, backingHeight_, -1, 1);
    glViewport(0, 0, backingWidth_, backingHeight_);

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

- (void)initVDARender {
    
    long			swapInterval	= 1;
    
    [[self openGLContext] setValues:(GLint*)(&swapInterval)
                       forParameter: NSOpenGLCPSwapInterval];
    
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glGenTextures(1, &surfaceTexture_);
    glDisable(GL_TEXTURE_RECTANGLE_ARB);
}

- (void)updateViewPort {
    [self lockFocusIfCanDraw];
    
    backingWidth_ = self.frame.size.width;
    backingHeight_ = self.frame.size.height;
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, backingWidth_, 0, backingHeight_, -1, 1);
    glViewport(0, 0, backingWidth_, backingHeight_);
    
    [self unlockFocus];
}

- (void)render:(BOOL)vda {    
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

- (void)makeSufaceToTexture:(IOSurfaceRef)suface {
    
    if (surface_ && (surface_ != suface)) {
		CFRelease(surface_);
	}

    if ((surface_ = suface) != nil) {
		CGLContextObj   cgl_ctx = [[self openGLContext]  CGLContextObj];
		
		GLsizei w	= (GLsizei)IOSurfaceGetWidth(surface_);
		GLsizei h	= (GLsizei)IOSurfaceGetHeight(surface_);
		
		glEnable(GL_TEXTURE_RECTANGLE_ARB);
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, surfaceTexture_);
		CGLTexImageIOSurface2D(cgl_ctx,
                               GL_TEXTURE_RECTANGLE_ARB, GL_RGB8,
							   w,
                               h,
							   GL_YCBCR_422_APPLE,
                               GL_UNSIGNED_SHORT_8_8_APPLE,
                               surface_,
                               0);
        
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
		glDisable(GL_TEXTURE_RECTANGLE_ARB);
        
        glFlush();
	}
}

#pragma mark - Public
- (void)renderData:(NSDictionary *)frameData {

    if (self.isHidden) {
        NSLog(@" hidden");
        return;
    }
    
    [self lockFocusIfCanDraw];
    
    GLint width     = (GLint)[[frameData objectForKey:@"width"] integerValue];
    GLint heigth    = (GLint)[[frameData objectForKey:@"height"] integerValue];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self makeTexture:frameData];
    
    float dH, dW, dd, h, w, wMargin, hMargin;
    if (_aspectFit == NO) {
        wMargin = 0;
        hMargin = 0;
        w       = backingWidth_;
        h       = backingHeight_;
    } else {
        dH      = (float)backingHeight_ / heigth;
        dW      = (float)backingWidth_	  / width;
        dd      = MIN(dH, dW);
        h       = (heigth * dd / (float)backingHeight_);
        w       = (width  * dd / (float)backingWidth_ );
        w       = w * backingWidth_;
        h       = h * backingHeight_;
        wMargin = (backingWidth_ - w) / 2;
        hMargin = (backingHeight_ - h) / 2;
    }
    
    glBegin(GL_QUADS);
    
    ///left,bottom
    glTexCoord2i(0, 0);
    glVertex2i(wMargin, hMargin);
    
    ///right,bottom
    glTexCoord2i(width, 0);
    glVertex2i(w + wMargin, hMargin);
    
    ///Right,top
    glTexCoord2i(width, heigth);
    glVertex2i(w + wMargin, h + hMargin);
    
    //left,top
    glTexCoord2i(0, heigth);
    glVertex2i(wMargin, h + hMargin);

    glEnd();
    
    [[self openGLContext] flushBuffer];
    
    [self unlockFocus];
}

- (void)renderVDA:(CVImageBufferRef)buffer {
    
}


- (void)clear:(float)r g:(float)g b:(float)b a:(float)a {
        
    [self lockFocusIfCanDraw];
    
    glClearColor(r, g, b, a);
    glClear(GL_COLOR_BUFFER_BIT);

    [[self openGLContext] flushBuffer];
    
    [self unlockFocus];
}

@end

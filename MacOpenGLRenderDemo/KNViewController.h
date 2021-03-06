//
//  KNViewController.h
//  MacOpenGLRenderDemo
//
//  Created by cyh on 13. 1. 7..
//  Copyright (c) 2013년 cyh3813. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KNYUVShaderView.h"

@interface KNViewController : NSObject
@property (retain, nonatomic) IBOutlet NSButton* renderButton;
@property (retain, nonatomic) IBOutlet KNYUVShaderView* glView;
@property (retain, nonatomic) IBOutlet KNYUVShaderView* glView2;
- (IBAction)readFrames:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)fillImage:(id)sender;
- (IBAction)fitImage:(id)sender;
@end

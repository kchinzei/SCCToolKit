/*=========================================================================
 
 Program:   Small Computings for Clinicals Project
 Module:    $HeadURL: $
 Date:      $Date: $
 Version:   $Revision: $
 URL:       http://scc.pj.aist.go.jp
 
 (c) 2013- Kiyoyuki Chinzei, Ph.D., AIST Japan, All rights reserved.
 
 Acknowledgement: This work is/was supported by many research fundings.
 See Acknowledgement.txt
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.  See License.txt for license terms.
 
 =========================================================================*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface QCvGLWidget_CIImageDrower : NSObject
- (id) init;

- (void) drawImageWithScaleToFill:(CIImage *)ciImage
                           inRect:(CGRect)destRect
                    withPointSize:(float)pointSize;

- (void) drawImageWithoutScaling:(CIImage *) ciImage
                          inRect:(CGRect)destRect
                   withPointSize:(float)pointSize;

- (void) drawImageWithScaleAspectFit:(CIImage *) ciImage
                              inRect:(CGRect)destRect
                       withPointSize:(float)pointSize;

- (void) drawImageWithScaleAspectFill:(CIImage *) ciImage
                               inRect:(CGRect)destRect
                        withPointSize:(float)pointSize;
@end

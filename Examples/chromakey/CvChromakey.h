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

struct CvMat;

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface CvChromakey : NSObject

@property (nonatomic) float minHueAngle;    //! 0-360
@property (nonatomic) float maxHueAngle;    //! 0-360
@property (nonatomic) float minValue;       //! 0-1

- (id) initWithHueAngles:(float)minH to:(float)maxH withMinValue:(float)minV;

- (CIImage *) updateFilter:(CIImage *)foreImage withBkgnd:(CIImage *)bkgndImage;

- (void) dealloc;

@end

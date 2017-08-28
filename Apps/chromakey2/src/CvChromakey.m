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

#include <dispatch/dispatch.h>

#import "CvChromakey.h"
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSOpenGL.h>
#import <AppKit/NSOpenGLLayer.h>

static float rgbToHue(const float* rgb);
static float rgbToValue(const float* rgb);

@interface CvChromakey()

@property (nonatomic, strong) CIFilter *noiseReduction;
@property (nonatomic, strong) CIFilter *colorCube;
@property (nonatomic, strong) CIFilter *sourceOverCompositing;
@property (nonatomic) int colorCubeSize;
@property (nonatomic) dispatch_queue_t chromaQueue;
@property (nonatomic) dispatch_group_t chromaGroup;

- (CIFilter *) colorCubeWithSize:(int) size
                    fromHueAngle:(float) minHueAngle
                      toHueAngle:(float) maxHueAngle
                        minValue:(float) minVal
                        maxValue:(float) maxVal;

@end

@implementation CvChromakey
@synthesize minHueAngle, maxHueAngle, minValue, maxValue;
@synthesize noiseReduction, colorCube, sourceOverCompositing;
@synthesize colorCubeSize;
@synthesize chromaQueue, chromaGroup;
@synthesize noBkgnd;

- (id) init {
    self = [super init];
    if (self) {
        chromaGroup = dispatch_group_create();
        chromaQueue = dispatch_queue_create("jp.go.aist.chromaqueue", DISPATCH_QUEUE_SERIAL);

        // Prepare the filters.
        colorCubeSize = 64;
        minValue = 0;
        maxValue = 1.0;
        minHueAngle = -1;
        maxHueAngle = -1;
        noBkgnd = false;
        
        dispatch_sync(chromaQueue, ^{
            noiseReduction = [CIFilter filterWithName:@"CIBoxBlur"];
            //noiseReduction = [CIFilter filterWithName:@"CINoiseReduction"];
            [noiseReduction setDefaults];
            [noiseReduction setValue:[NSNumber numberWithInt:5] forKey:@"inputRadius"];
            //[noiseReduction setValue:[NSNumber numberWithFloat:0.2] forKey:@"inputNoiseLevel"];
            colorCube = [CIFilter filterWithName:@"CIColorCube"];
            [colorCube setDefaults];
            sourceOverCompositing = [CIFilter filterWithName:@"CISourceOverCompositing"];
            [sourceOverCompositing setDefaults];
            
            // The rest is done when image arrives.
        });
    }
    return self;
}

- (void) dealloc {
    dispatch_release(chromaQueue);
    dispatch_release(chromaGroup);
    self.colorCube = nil;
    self.sourceOverCompositing = nil;
    self.noiseReduction = nil;
    [super dealloc];
}

- (id) initWithHueAngles:(float)minH to:(float)maxH withMinValue:(float)minV withMaxValue:(float)maxV;
{
    self = [self init];
    if (self) {
        self.minValue = minV;
        self.maxValue = maxV;
        self.minHueAngle = minH;
        self.maxHueAngle = maxH;
    }
    return self;
}

- (CIImage *) updateFilter:(CIImage *)foreImage withBkgnd:(CIImage *)bkgndImage
{
    __block CIImage *outputImage;
    dispatch_sync(chromaQueue, ^{
        CIImage *result;
        if (foreImage != nil) {
            [noiseReduction setValue:foreImage forKey:kCIInputImageKey];
            [colorCube setValue:[noiseReduction valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
            //[colorCube setValue:foreImage forKey:kCIInputImageKey];
            result = [colorCube valueForKey:kCIOutputImageKey];
            if (noBkgnd) {
                outputImage = result;
            } else {
                [sourceOverCompositing setValue:result forKey:kCIInputImageKey];
                [sourceOverCompositing setValue:bkgndImage forKey:kCIInputBackgroundImageKey];
                outputImage = [sourceOverCompositing valueForKey:kCIOutputImageKey];
            }
        } else {
            outputImage = bkgndImage;
        }
    });
    return outputImage;
}

- (void) setMinHueAngle:(float) hueAngle
{
    minHueAngle = hueAngle;
    if (minHueAngle >= 0 && maxHueAngle >=0)
        colorCube = [self colorCubeWithSize:colorCubeSize
                               fromHueAngle:minHueAngle
                                 toHueAngle:maxHueAngle
                                   minValue:minValue
                                   maxValue:maxValue];
}

- (void) setMaxHueAngle:(float) hueAngle
{
    maxHueAngle = hueAngle;
    if (minHueAngle >= 0 && maxHueAngle >=0)
        colorCube = [self colorCubeWithSize:colorCubeSize
                               fromHueAngle:minHueAngle
                                 toHueAngle:maxHueAngle
                                   minValue:minValue
                                   maxValue:maxValue];
}

- (void) setMinValue:(float) val
{
    if (val >= 1.0)
        val /= 256;
    minValue = val;
    if (minHueAngle >= 0 && maxHueAngle >=0)
        colorCube = [self colorCubeWithSize:colorCubeSize
                               fromHueAngle:minHueAngle
                                 toHueAngle:maxHueAngle
                                   minValue:minValue
                                   maxValue:maxValue];
}

- (void) setMaxValue:(float) val
{
    if (val >= 1.0)
        val /= 256;
    maxValue = val;
    if (minHueAngle >= 0 && maxHueAngle >=0)
        colorCube = [self colorCubeWithSize:colorCubeSize
                               fromHueAngle:minHueAngle
                                 toHueAngle:maxHueAngle
                                   minValue:minValue
                                   maxValue:maxValue];
}


- (CIFilter *) colorCubeWithSize:(int) size
                    fromHueAngle:(float) minHue
                      toHueAngle:(float) maxHue
                        minValue:(float) minVal
                        maxValue:(float) maxVal

{
    // Allocate memory
    size_t cubeDataSize = size * size * size * sizeof (float) * 4;
    float *cubeData = (float *) malloc(cubeDataSize);
    float rgb[3], *c = cubeData;
    
    // Populate cube with a simple gradient going from 0 to 1
    for (int z = 0; z < size; z++){
        rgb[2] = ((double)z)/(size-1); // Blue value
        for (int y = 0; y < size; y++){
            rgb[1] = ((double)y)/(size-1); // Green value
            for (int x = 0; x < size; x ++){
                rgb[0] = ((double)x)/(size-1); // Red value
                // Convert RGB to HSV
                float hue = rgbToHue(rgb);
                float val = rgbToValue(rgb);
                // Use the hue value to determine which to make transparent
                // The minimum and maximum hue angle depends on
                // the color you want to remove
                float alpha = (val < minVal || val > maxVal || (hue > minHue && hue < maxHue)) ? 0.0f: 1.0f;
                // Calculate premultiplied alpha values for the cube
                c[0] = rgb[0] * alpha;
                c[1] = rgb[1] * alpha;
                c[2] = rgb[2] * alpha;
                c[3] = alpha;
                c += 4;
            }
        }
    }
    // Create memory with the cube data
    NSData *data = [NSData dataWithBytesNoCopy:cubeData
                                        length:(NSUInteger)cubeDataSize
                                  freeWhenDone:YES];
    [colorCube setValue:[NSNumber numberWithInt:size] forKey:@"inputCubeDimension"];
    [colorCube setValue:data forKey:@"inputCubeData"];
    
    return colorCube;
}

@end

static float rgbToHue(const float* rgb)
{
    float r, g, b, hue;
    r = *rgb++;
    g = *rgb++;
    b = *rgb;
    
    // Equation from http://ja.wikipedia.org/wiki/HSV色空間
    float min, max, f1;
    f1 = (r < g)? r : g;
    min = (f1 < b)? f1 : b;
    f1 = (r > g)? r : g;
    max = (f1 > b)? f1 : b;
    
    if (min != max) {
        if (max == r)
            hue = 60 * (g - b) / (max - min);
        else if (max == g)
            hue = 60 * (b - r) / (max - min) + 120;
        else
            hue = 60 * (r - g) / (max - min) + 240;
        if (hue < 0)
            hue += 360;
    }
    else
        hue = -1;
    return hue;
}

static float rgbToValue(const float* rgb)
{
    float r, g, b, max;
    r = *rgb++;
    g = *rgb++;
    b = *rgb;
    max = (r > g)? r : g;
    max = (max > b)? max : b;
    return max;
}

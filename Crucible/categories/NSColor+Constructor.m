//
//  NSColor+Constructor.m
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#import "NSColor+Constructor.h"

static inline void HSLToHSB(float_quad hsl, float_quad *hsb) {
    // Alpha
    hsb->d = hsl.d;
    hsb->a = hsl.a - floor(hsl.a);
    
    hsb->c = 2 * hsl.c + hsl.b * (1 - fabs(2 * hsl.c - 1)) / 2;
    hsb->b = 2 * (hsb->c - hsl.c) / hsb->c;
}

@implementation COLOR_CLASS (Constructor)

+ (instancetype)colorWithHexColor:(unsigned  int)clr {
    unsigned char r = (unsigned char)(clr >> 16);
    unsigned char g = (unsigned char)(clr >> 8);
    unsigned char b = (unsigned char)(clr);
    

    return [COLOR_CLASS colorWithRed:(CGFloat)r / 255. green:(CGFloat)g / 255. blue:(CGFloat)b / 255. alpha:1.0];
}

+ (instancetype)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation lightness:(CGFloat)lightness alpha:(CGFloat)alpha {
    
    float_quad hsl = { hue, saturation, lightness, alpha };
    float_quad hsb = { 0.0, 0.0, 0.0, 1.0 };
    HSLToHSB(hsl, &hsb);

    return [COLOR_CLASS colorWithHue:hsb.a saturation:hsb.b brightness:hsb.c alpha:hsb.d];
}

@end

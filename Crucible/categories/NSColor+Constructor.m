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
    hsb->b = hsl.b * ((hsl.c <= 1.0) ? hsl.c : (2.0 - hsl.c));
    hsb->c = (hsb->b + hsl.c) * 0.5;
    if (hsb->b != 0.0) {
        hsb->b = (2 * hsb->b) / (hsb->b + hsl.c);
    }
    hsb->a = hsl.a;
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
    float_quad hsb;
    HSLToHSB(hsl, &hsb);
    
    return [COLOR_CLASS colorWithHue:hsb.a saturation:hsb.b lightness:hsb.c alpha:hsb.d];
}

@end

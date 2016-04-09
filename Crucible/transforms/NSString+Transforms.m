//
//  NSString+Transforms.m
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#import "NSString+Transforms.h"
#import "NSObject+Transforms.h"
#import "NSColor+Constructor.h"

@implementation NSString (Transforms)

TRANSFORM(url) {
    return [NSURL URLWithString:self];
}

TRANSFORM(file_url) {
    return [NSURL fileURLWithPath:self];
}

static BOOL scan_float(NSScanner *scanner, CGFloat *flt, CGFloat scale) {
    float f;
    int i;

    if ([scanner scanFloat:(float *)&f]) {
    fin:
        
        if ([scanner scanString:@"%" intoString:NULL]) {
            f /= 100;
        } else {
            f *= scale;
        }
        
        *flt = f;
        return YES;
    } else if ([scanner scanInt:&i]) {
        f = (float)i;
        goto fin;
    }
    return NO;
}

static BOOL scan_quad(NSScanner *scanner, float_quad scale, float_quad *quad, BOOL alpha) {
    scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    BOOL succ = [scanner scanString:@"(" intoString:NULL];
    succ &= scan_float(scanner, &(quad->a), scale.a);
    succ &= [scanner scanString:@"," intoString:NULL];
    succ &= scan_float(scanner, &(quad->b), scale.b);
    succ &= [scanner scanString:@"," intoString:NULL];
    succ &= scan_float(scanner, &(quad->c), scale.c);
    if (alpha) {
        succ &= [scanner scanString:@"," intoString:NULL];
        succ &= scan_float(scanner, &(quad->d), scale.d);
    } else {
        quad->d = 1.0;
    }
    succ = [scanner scanString:@")" intoString:NULL];
    return succ;
}

TRANSFORM(color) {
    if ([self hasPrefix:@"#"]) {
        NSString *hexCode = [self substringFromIndex:1];
        if (hexCode.length == 1) {
            hexCode = [NSString stringWithFormat:@"%@%@%@%@%@%@", hexCode, hexCode, hexCode, hexCode, hexCode, hexCode];
        } else if (hexCode.length == 3) {
            unichar first = [hexCode characterAtIndex:0];
            unichar second = [hexCode characterAtIndex:1];
            unichar third = [hexCode characterAtIndex:2];
            hexCode = [NSString stringWithFormat:@"%c%c%c%c%c%c", first, first, second, second, third, third];

        } else if (hexCode.length != 6) {
            return nil;
        }
        
        unsigned int hex;
        NSScanner *scanner = [NSScanner scannerWithString:hexCode];
        [scanner scanHexInt:&hex];
#
        return [COLOR_CLASS colorWithHexColor:hex];
        
    } else if ([self.lowercaseString hasPrefix:@"rgb"]) {
        NSString *quad = [self substringFromIndex:3];
        BOOL alpha = [quad hasPrefix:@"a"];
        if (alpha) quad = [quad substringFromIndex:1];
        float_quad args = { 0.0, 0.0, 0.0, 0.0 };
        float_quad scale = { 1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 1.0 };
        NSScanner *scan = [NSScanner scannerWithString:quad];
        if (scan_quad(scan, scale, &args, alpha)) {
            return [COLOR_CLASS colorWithRed:args.a green:args.b blue:args.c alpha:args.d];
        }
        
        return nil;
    } else if ([self.lowercaseString hasPrefix:@"hsl"]) {
        NSString *quad = [self substringFromIndex:3];
        BOOL alpha = [quad hasPrefix:@"a"];
        if (alpha) quad = [quad substringFromIndex:1];
        
        float_quad args = { 0.0, 0.0, 0.0, 0.0 };
        float_quad scale = { 1.0 / 360.0, 1.0, 1.0, 1.0 };
        NSScanner *scan = [NSScanner scannerWithString:quad];
        if (scan_quad(scan, scale, &args, alpha)) {
            return [COLOR_CLASS colorWithHue:args.a saturation:args.b lightness:args.c alpha:args.d];
        }
        
        return nil;
    } else if ([self.lowercaseString hasPrefix:@"hsb"]) {
        NSString *quad = [self substringFromIndex:3];
        BOOL alpha = [quad hasPrefix:@"a"];
        if (alpha) quad = [quad substringFromIndex:1];
        
        float_quad args = { 0.0, 0.0, 0.0, 0.0 };
        float_quad scale = { 1.0 / 360.0, 1.0, 1.0, 1.0 };
        NSScanner *scan = [NSScanner scannerWithString:quad];
        if (scan_quad(scan, scale, &args, alpha)) {
            return [COLOR_CLASS colorWithHue:(args.a - floor(args.a)) saturation:args.b brightness:args.c alpha:args.d];
        }
        
        return nil;
    } else if ([self.lowercaseString hasPrefix:@"gray("]) {
        NSString *num = [self substringFromIndex:5];
        NSScanner *scan = [NSScanner scannerWithString:num];
        CGFloat g, a = 1.0;
        if (scan_float(scan, &g, 1.0 / 255.0)) {
            if ([scan scanString:@"," intoString:NULL]) {
                scan_float(scan, &a, 1.0);
            }
            
            return [COLOR_CLASS colorWithWhite:g alpha:a];
            
        }
        
        return nil;

    }
    
    return nil;
}

TRANSFORM(alloc_init) {
    Class cls = objc_getClass(self.UTF8String);
    if (cls != NULL) {
        return [[cls alloc] init];
    }
    
    return nil;
}

@end

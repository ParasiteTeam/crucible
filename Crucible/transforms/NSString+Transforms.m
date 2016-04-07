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
        
    }
    return nil;
}

@end

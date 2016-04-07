//
//  NSColor+Constructor.m
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#import "NSColor+Constructor.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@implementation UIColor (Constructor)
#else
@implementation NSColor (Constructor)
#endif

+ (instancetype)colorWithHexColor:(unsigned  int)clr {
    unsigned char r = (unsigned char)(clr >> 16);
    unsigned char g = (unsigned char)(clr >> 8);
    unsigned char b = (unsigned char)(clr);
    
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return [UIColor colorWithRed:(CGFloat)r / 255. green:(CGFloat)g / 255. blue:(CGFloat)b / 255. alpha:1.0];
#else
    return [NSColor colorWithRed:(CGFloat)r / 255. green:(CGFloat)g / 255. blue:(CGFloat)b / 255. alpha:1.0];
#endif
}

@end

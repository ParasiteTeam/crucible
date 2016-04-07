//
//  NSColor+Constructor.h
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    #define COLOR_CLASS UIColor
#else
    #define COLOR_CLASS NSColor
#endif

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@interface COLOR_CLASS (Constructor)
+ (instancetype)colorWithHexColor:(unsigned  int)hex;
@end

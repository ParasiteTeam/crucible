//
//  NSColor+Constructor.h
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
@interface UIColor (Constructor)
#else
#import <Cocoa/Cocoa.h>
@interface NSColor (Constructor)
#endif

+ (instancetype)colorWithHexColor:(unsigned  int)hex;
@end

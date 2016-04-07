//
//  NSNumber+Transforms.m
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#import "NSNumber+Transforms.h"
#import "NSColor+Constructor.h"

@implementation NSNumber (Transforms)

TRANSFORM(color) {
    unsigned int clr = self.unsignedIntValue;
    return [NSColor colorWithHexColor:clr];
}

@end

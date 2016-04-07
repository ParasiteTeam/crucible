//
//  NSString+Transforms.m
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#import "NSString+Transforms.h"

@implementation NSString (Transforms)

TRANSFORM(url) {
    return [NSURL URLWithString:self];
}

TRANSFORM(file_url) {
    return [NSURL fileURLWithPath:self];
}

TRANSFORM(color) {
    return nil;
}

@end

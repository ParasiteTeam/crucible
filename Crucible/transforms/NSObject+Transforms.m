//
//  NSObject+Transforms.m
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#import "NSObject+Transforms.h"

@implementation NSObject (Transforms)

TRANSFORM(url) {
    return nil;
}

TRANSFORM(file_url) {
    return nil;
}

TRANSFORM(color) {
    return nil;
}

TRANSFORM(now) {
    return [NSDate date];
}

@end

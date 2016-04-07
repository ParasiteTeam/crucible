//
//  values.m
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "values.h"

id transform_value(id value, NSString *transform) {
    SEL transform_selector = NSSelectorFromString([@(MACRO(TRANSFORM_PREFIX)) stringByAppendingString: transform]);
    if ([value respondsToSelector:transform_selector]) {
        return (__bridge_transfer id)[value performSelector:transform_selector];
    }
    return nil;
}


id sanitize_value(id value) {
    if ([value isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *d = (NSDictionary *)value;
        if (d[VALUE_KEY] != nil) {
            // Transform!
            id value = sanitize_value(d[VALUE_KEY]);
            NSString *transform = d[TRANSFORM_KEY];
            if (transform != nil) {
                value = transform_value(value, transform);
            }
            
            return value;
        }
        
        NSMutableDictionary *sanitized = [NSMutableDictionary dictionaryWithCapacity:d.count];
        for (NSString *k in d.allKeys) {
            id san = sanitize_value(d[k]);
            if (san != nil)
                sanitized[k] = sanitize_value(san);
        }
        
        return sanitized;
        
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *a = (NSArray *)value;
        NSMutableArray *sanitized = [NSMutableArray arrayWithCapacity:a.count];
        for (NSUInteger idx = 0; idx < a.count; idx++) {
            id san = sanitize_value(a[idx]);
            [sanitized addObject:san];
        }
        
        return sanitized;
    }
    
    return value;
}

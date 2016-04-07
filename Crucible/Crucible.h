//
//  Crucible.h
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#ifndef Crucible_h
#define Crucible_h

#import <ParasiteRuntime/ParasiteRuntime.h>
#import <Foundation/Foundation.h>
#import "Transform.h"

extern NSString *const CRUCIBLE_PATH;
extern NSString *const HOOKS_KEY;
extern NSString *const CLASS_KEY;
extern NSString *const METHODS_KEY;
extern NSString *const SYMBOL_KEY;
extern NSString *const IMAGE_KEY;
extern NSString *const VALUE_KEY;
extern NSString *const RETURN_KEY;
extern NSString *const TRANSFORM_KEY;
extern NSString *const MIN_VERSION_KEY;
extern NSString *const MAX_VERSION_KEY;

#define MACRO(M) #M

//#ifdef DEBUG
#define CLog(...) NSLog(@"[Crucible] " __VA_ARGS__)
//#else
//    #define CLog(...) (void)0
//#endif

#endif /* Crucible_h */

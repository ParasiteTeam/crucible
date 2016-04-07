//
//  hooks.h
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#ifndef hooks_h
#define hooks_h

#import <Foundation/Foundation.h>
#import "Crucible.h"

void process_class_hook(NSDictionary *hook);
void process_function_hook(NSDictionary *hook);
void process_hooks(NSDictionary *plist, int version);

#endif /* hooks_h */

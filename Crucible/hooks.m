//
//  hooks.m
//  Crucible
//
//  Created by Alexander Zielenski on 4/7/16.
//  Copyright © 2016 Alexander Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "hooks.h"
#import "values.h"

static IMP implementationForValue(id value, NSString *type) {
    unichar rtn = [type characterAtIndex:type.length - 1];
    NSNumber *val = (NSNumber *)value;
    NSString *str = (NSString *)value;
    
    BOOL is_string = [value isKindOfClass:[NSString class]];
    BOOL is_number = [value isKindOfClass:[NSNumber class]];
    
    IMP imp = NULL;
    
    if ([type hasPrefix:@"^"]) rtn = @encode(vm_address_t)[0];
    if ([type hasPrefix:@"b"]) rtn = @encode(vm_address_t)[0];
    if ([type hasPrefix:@"?"]) rtn = @encode(vm_address_t)[0];
    
    switch (rtn) {
        case 'c': {
            if (!is_number && !(is_string && str.length == 1)) return NULL;
            
            imp = imp_implementationWithBlock(^char() {
                if (is_string) return [str characterAtIndex:0];
                return val.charValue;
            });
            break;
        }
        case 'i': {
            if (!is_number) return NULL;
            imp = imp_implementationWithBlock(^int() {
                return val.intValue;
            });
            break;
        }
        case 's': {
            if (!is_number) return NULL;
            
            imp = imp_implementationWithBlock(^short() {
                return val.shortValue;
            });
            break;
        }
        case 'l': {
            if (!is_number) return NULL;
            
            imp = imp_implementationWithBlock(^long() {
                return val.longValue;
            });
            break;
        }
        case 'q': {
            if (!is_number) return NULL;
            
            imp = imp_implementationWithBlock(^long long() {
                return val.longLongValue;
            });
            break;
        }
        case 'C': {
            if (!is_number && !(is_string && str.length == 1)) return NULL;
            
            imp = imp_implementationWithBlock(^unsigned char() {
                if (is_string) return [str characterAtIndex:0];
                return val.unsignedCharValue;
            });
            break;
        }
        case 'I': {
            if (!is_number) return NULL;
            
            imp = imp_implementationWithBlock(^unsigned int() {
                return val.unsignedIntValue;
            });
            break;
        }
        case 'S': {
            if (!is_number) return NULL;
            
            imp = imp_implementationWithBlock(^unsigned short() {
                return val.unsignedShortValue;
            });
            break;
        }
        case 'L': {
            if (!is_number) return NULL;
            
            imp = imp_implementationWithBlock(^unsigned long() {
                return val.unsignedLongValue;
            });
            break;
        }
        case 'Q': {
            if (!is_number) return NULL;
            
            imp = imp_implementationWithBlock(^unsigned long long() {
                return val.unsignedLongLongValue;
            });
            break;
        }
        case 'f': {
            if (!is_number) return NULL;
            
            imp = imp_implementationWithBlock(^float() {
                return val.floatValue;
            });
            break;
        }
        case 'd': {
            if (!is_number) return NULL;
            
            imp = imp_implementationWithBlock(^double() {
                return val.doubleValue;
            });
            break;
        }
        case 'v': {
            imp = imp_implementationWithBlock(^void() {
                return;
            });
            break;
        }
        case '*': {
            if (!is_string && ![value isKindOfClass:[NSData class]]) return NULL;
            
            imp = imp_implementationWithBlock(^char *() {
                if ([value isKindOfClass:[NSData class]]) {
                    return (char *)((NSData *)value).bytes;
                }
                return (char *)str.UTF8String;
            });
            break;
        }
        case 'B': {
            imp = imp_implementationWithBlock(^char() {
                return val.boolValue;
            });
            break;
        }
        case '#': {
            if (!is_string) return NULL;
            
            imp = imp_implementationWithBlock(^Class() {
                return NSClassFromString(str);
            });
            break;
        }
        case ':': {
            if (!is_string) return NULL;
            
            imp = imp_implementationWithBlock(^SEL() {
                return NSSelectorFromString(str);
            });
            break;
        }
        case ']':;
        case '}':;
        case ')': {
            // Unsupported type
            CLog(@"Hooking of unsupported array, struct, or union type, %@. Skipping...", type);
            return NULL;
        }
        default: {
            imp = imp_implementationWithBlock(^id() {
                return value;
            });
            break;
        }
    }
    
    return imp;
}

void process_class_hook(NSDictionary *hook) {
    NSString *className = hook[CLASS_KEY];
    Class cls = objc_getClass(className.UTF8String);
    if (cls == NULL) return;
    
    NSArray *methods = hook[METHODS_KEY];
    if (![methods isKindOfClass:[NSArray class]]) return;
    
    for (NSArray *method in methods) {
        if (![method isKindOfClass:[NSArray class]]) continue;
        if (method.count != 2 && method.count != 3) continue;
        
        NSString *selName = method[0];
        unsigned char instanceMethod = 2;
        if ([selName hasPrefix:@"+"]) {
            instanceMethod = 0;
            selName = [selName substringFromIndex:1];
        } else if ([selName hasPrefix:@"-"]) {
            instanceMethod = 1;
            selName = [selName substringFromIndex:1];
        }
        
        SEL sel = NSSelectorFromString(selName);
        id value = method[1];
        
        value = sanitize_value(value);
        
        Method m = class_getInstanceMethod(cls, sel);
        if ((m == NULL && instanceMethod == 2) || instanceMethod == 0) {
            m = class_getInstanceMethod(object_getClass(cls), sel);
            
            CLog(@"Got method %p", m);
            if (m == NULL) continue;
        }
        
        IMP implementation = NULL;
        // If it's analyzed as a number we want to figure out the correct type to return
        char *return_type = method_copyReturnType(m);
        NSString *rtn = @(return_type);
        free(return_type);
        
        implementation = implementationForValue(value, rtn);
        CLog(@"Got imp: %p", implementation);
        
        CLog(@"Hooking %@ (%@) for %@", selName, rtn, value);
        if (implementation != NULL) {
            method_setImplementation(m, implementation);
        }
    }
}

void process_function_hook(NSDictionary *hook) {
    NSString *symbol = hook[SYMBOL_KEY];
    NSString *image = hook[IMAGE_KEY];
    
    if (image != NULL) {
        image = [image stringByReplacingOccurrencesOfString:@"@executable_path"
                                                 withString:[[NSProcessInfo processInfo] arguments][0]];
        
        if ([image hasPrefix:@"identifier:"]) {
            image = [image substringFromIndex:@"identifier:".length];
            NSBundle *bndl = [NSBundle bundleWithIdentifier:image];
            if (!bndl || !bndl.isLoaded) return;
            image = bndl.executablePath;
        }
    }
    
    id value = sanitize_value(hook[VALUE_KEY]);
    NSString *returns = hook[RETURN_KEY];
    
    CLog(@"Hooking %@ with %@ (%@) in %@", symbol, value, returns, image);
    if (!symbol || !returns || !value) return;
    
    // We can just use whatever calling conventions we want for the argument
    // so it doesnt matter that it just takes id, SEL
    // We just need to worry about return type calling conventions for primitives
    IMP implementation = implementationForValue(value, returns);
    void *img = PSGetImageByName(image.UTF8String);
    
    void *func = PSFindSymbol(img, symbol.UTF8String);
    
    CLog(@"Swapping %p and %p", func, implementation);
    if (func != NULL && implementation != NULL) {
        // We have the symbol to hook and we have the block to invoke.
        // Need to create a trampoline for the block. PSHookFunctionPtr crashes here
        mmap(0, 0, 0, 0, 0, 0);
        mprotect(0, 0, 0);
        
        vm_address_t replace = (vm_address_t)func;
        vm_address_t target = (vm_address_t)implementation;
        
        // Copy original code
        char buf[PAGE_SIZE * 2];
        memcpy(buf, (void *)(replace & (~PAGE_MASK)), PAGE_SIZE * 2);
        
        // Patch the trampoline in
        extern void _tramp_begin();
        extern void _tramp_end();
        
        char *xmb = &buf[replace & PAGE_MASK];
        memcpy(xmb, _tramp_begin, ((vm_address_t)_tramp_end) - ((vm_address_t)_tramp_begin));
        
        vm_address_t *tramp_target = (vm_address_t *)&xmb[((vm_address_t)_tramp_end) - ((vm_address_t)_tramp_begin)];
        tramp_target--;
        *tramp_target = target;
        
        munmap((void *)(replace & (~PAGE_MASK)), PAGE_SIZE*2);
        mmap((void *)(replace & (~PAGE_MASK)), PAGE_SIZE*2, PROT_READ|PROT_WRITE, MAP_ANON|MAP_PRIVATE, 0, 0);
        memcpy((void *)(replace & (~PAGE_MASK)), buf, PAGE_SIZE*2);
        mprotect((void *)(replace & (~PAGE_MASK)), PAGE_SIZE*2, PROT_READ|PROT_EXEC);
    }
    
}

void process_hooks(NSDictionary *plist, int version) {
    NSArray *hooks = plist[HOOKS_KEY];
    if (hooks == nil) return;
    
    for (NSDictionary *hook in hooks) {
        if (![hook isKindOfClass:[NSDictionary class]]) continue;
        
        NSNumber *minNumber = hook[MIN_VERSION_KEY];
        NSNumber *maxNumber = hook[MAX_VERSION_KEY];
        
        if (minNumber != nil && version < minNumber.intValue) continue;
        if (maxNumber != nil && version > maxNumber.intValue) continue;
        
        if ([hook.allKeys containsObject:CLASS_KEY]) {
            CLog(@"Processing Class Hook");
            process_class_hook(hook);
        } else if ([hook.allKeys containsObject:SYMBOL_KEY]) {
            CLog(@"Processing Function Hook");
            process_function_hook(hook);
        }
        
    }
    
}

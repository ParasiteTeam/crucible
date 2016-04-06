//
//  Crucible.m
//  Crucible
//
//  Created by Crucible on 4/5/16.
//  Copyright © 2016 Crucible. All rights reserved.
//

#import <ParasiteRuntime/ParasiteRuntime.h>
#import <Foundation/Foundation.h>

static NSString *const CRUCIBLE_PATH = @"/Library/Parasite/Crucible";
static NSString *const HOOKS_KEY = @"Hooks";
static NSString *const CLASS_KEY = @"Class";
static NSString *const METHODS_KEY = @"Methods";
static NSString *const SYMBOL_KEY = @"Symbol";
static NSString *const IMAGE_KEY = @"Image";
static NSString *const VALUE_KEY = @"Value";
static NSString *const RETURN_KEY = @"Returns";
static NSString *const TRANSFORM_KEY = @"Transform";
static NSString *const MIN_VERSION_KEY = @"MinBundleVersion";
static NSString *const MAX_VERSION_KEY = @"MaxBundleVersion";

//#ifdef DEBUG
    #define CLog(...) NSLog(@"[Crucible] " __VA_ARGS__)
//#else
//    #define CLog(...) (void)0
//#endif

static id transform_value(id value, NSString *transform) {
    BOOL is_string = [value isKindOfClass:[NSString class]];
    BOOL is_number = [value isKindOfClass:[NSNumber class]];
    
    if ([transform isEqualToString:@"url"]) {
        if (!is_string) return nil;
        return [NSURL URLWithString:value];
    } else if ([transform isEqualToString:@"file_url"]) {
        if (!is_string) return nil;
        return [NSURL fileURLWithPath:value];
    } else if ([transform isEqualToString:@"now"]) {
        return [NSDate date];
    } else if ([transform isEqualToString:@"hex"]) {
        if (!is_number && !is_string) return nil;
        
    } else if ([transform isEqualToString:@"color"]) {
        // prefix with rgba/hsla/hsba
    }
    
    return value;
}


static id sanitize_value(id value) {
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
            if (!is_string) return NULL;
            
            imp = imp_implementationWithBlock(^char *() {
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

static void process_class_hook(NSDictionary *hook) {
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
        
        if (method.count == 3) {
            NSString *transform = method[2];
            value = transform_value(value, transform);
            value = sanitize_value(value);
        }
        
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

static void process_function_hook(NSDictionary *hook) {
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
    
    id value = hook[VALUE_KEY];
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

static void process_hooks(NSDictionary *plist, int version) {
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

static void load_path(NSString *path, int version) {
    if (![path.pathExtension isEqualToString:@"plist"]) return;
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    if (plist != nil) {
        CLog(@"Processing %@", path.lastPathComponent.stringByDeletingPathExtension);
        process_hooks(plist, version);
    }
}

ctor {
    @autoreleasepool {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *crucible = [manager contentsOfDirectoryAtPath:CRUCIBLE_PATH error:nil];
        
        for (NSString *name in crucible) {
            NSString *identifier = name.stringByDeletingPathExtension;
            
            int version = [[[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey] intValue];
            
            if ([identifier hasPrefix:@"class_"]) {
                NSString *className = [identifier substringFromIndex:@"class_".length];
                Class cls = objc_getClass(className.UTF8String);
                if (cls == NULL) continue;
                
                NSBundle *bndl = [NSBundle bundleForClass:cls];
                if (bndl != nil)
                    version = [[bndl infoDictionary][(__bridge NSString *)kCFBundleVersionKey] intValue];
            } else if (![[NSBundle bundleWithIdentifier:identifier] isLoaded]) continue;
            
            // We should load this plist's hooks
            NSString *path = [CRUCIBLE_PATH stringByAppendingPathComponent:name];
            BOOL is_dir = NO;
            if ([manager fileExistsAtPath:path isDirectory:&is_dir]) {
                if (is_dir) {
                    NSArray *contents = [manager contentsOfDirectoryAtPath:path error:nil];
                    for (NSString *name in contents) {
                        if (![name.pathExtension isEqualToString:@"plist"]) continue;
                        NSString *file_path = [path stringByAppendingPathComponent:name];
                        load_path(file_path, version);
                    }
                    
                } else {
                    load_path(path, version);
                }
            }
        }
    }
}
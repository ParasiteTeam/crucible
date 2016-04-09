//
//  Crucible.m
//  Crucible
//
//  Created by Crucible on 4/5/16.
//  Copyright © 2016 Crucible. All rights reserved.
//

#import <ParasiteRuntime/ParasiteRuntime.h>
#import "Crucible.h"
#import "hooks.h"

NSString *const CRUCIBLE_PATH = @"/Library/Parasite/Crucible";
NSString *const HOOKS_KEY = @"Hooks";
NSString *const CLASS_KEY = @"Class";
NSString *const METHODS_KEY = @"Methods";
NSString *const SYMBOL_KEY = @"Symbol";
NSString *const IMAGE_KEY = @"Image";
NSString *const VALUE_KEY = @"Value";
NSString *const RETURN_KEY = @"Returns";
NSString *const TRANSFORM_KEY = @"Transform";
NSString *const MIN_VERSION_KEY = @"MinBundleVersion";
NSString *const MAX_VERSION_KEY = @"MaxBundleVersion";

static void load_path(NSString *path, int version) {
    if (![path.pathExtension isEqualToString:@"plist"]) return;
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    if (plist != nil) {
        CLog(@"Processing %@", path.lastPathComponent.stringByDeletingPathExtension);
        process_hooks(plist, version);
    }
}

static void __CrucibleInit() {
    @autoreleasepool {
        
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *crucible = [manager contentsOfDirectoryAtPath:CRUCIBLE_PATH error:nil];
        
        for (NSString *name in crucible) {
            NSString *identifier = name.stringByDeletingPathExtension;
            
            int version = [[[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey] intValue];
            
            if ([identifier hasPrefix:@"class_"]) {
                NSString *className = [identifier substringFromIndex:@"class_".length];
                Class cls = objc_getClass(className.UTF8String);
                CLog(@"Checking for class %@", className);
                
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

static void __CrucibleCallback(CFURLRef path, CFIndex i, CFIndex total) {
    if (i == total - 1) {
        // Done!
        __CrucibleInit();
    }
}

ctor {
    PSRegisterCallback(__CrucibleCallback);
}
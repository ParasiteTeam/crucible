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
        CFURLEnumeratorRef num = CFURLEnumeratorCreateForDirectoryURL(kCFAllocatorDefault,
                                                                      (__bridge CFURLRef)[NSURL fileURLWithPath:CRUCIBLE_PATH],
                                                                      kCFURLEnumeratorSkipInvisibles,
                                                                      (__bridge CFArrayRef)@[ (__bridge id)kCFURLIsDirectoryKey ]);
        CFURLRef nextRef = NULL;
        while (CFURLEnumeratorGetNextURL(num, &nextRef, NULL) == kCFURLEnumeratorSuccess) {
            NSURL *url = (__bridge NSURL *)nextRef;
            NSString *name = url.lastPathComponent;
            
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
            NSNumber *isDir;
            [url getResourceValue:&isDir forKey:(__bridge NSString *)kCFURLIsDirectoryKey error:nil];
            if (isDir.boolValue) {
                CFURLEnumeratorRef sub = CFURLEnumeratorCreateForDirectoryURL(kCFAllocatorDefault,
                                                                              nextRef,
                                                                              kCFURLEnumeratorSkipInvisibles,
                                                                              nil);
                CFURLRef subRef;
                while (CFURLEnumeratorGetNextURL(sub, &subRef, NULL) == kCFURLEnumeratorSuccess) {
                    NSString *path = [(__bridge NSURL *)subRef path];
                    load_path(path, version);
                }
                CFRelease(sub);
            } else {
                load_path(path, version);
            }
        }
        
        CFRelease(num);
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
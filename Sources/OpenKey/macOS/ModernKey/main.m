//
//  main.m
//  ModernKey
//
//  Created by Tuyen on 1/18/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"

static NSString* const kLegacyOpenKeyDomain = @"com.tuyenmai.openkey";

static void importLegacyOpenKeySettings(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"NonFirstTime"] || [defaults boolForKey:@"ImportedLegacySettings"]) {
        return;
    }
    NSDictionary *legacy = [defaults persistentDomainForName:kLegacyOpenKeyDomain];
    if (legacy.count > 0) {
        NSString *ownDomain = [[NSBundle mainBundle] bundleIdentifier];
        NSMutableDictionary *merged = [legacy mutableCopy];
        [merged addEntriesFromDictionary:[defaults persistentDomainForName:ownDomain] ?: @{}];
        [defaults setPersistentDomain:merged forName:ownDomain];
    }
    [defaults setBool:YES forKey:@"ImportedLegacySettings"];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        importLegacyOpenKeySettings();
    }
    return NSApplicationMain(argc, argv);
}

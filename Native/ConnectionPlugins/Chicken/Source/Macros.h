//
//  Macros.h
//  Chicken
//
//  Created by Felix Deimel on 18.04.19.
//

#ifndef Macros_h
#define Macros_h

#import <Cocoa/Cocoa.h>

#define kChickenVncFrameworkBundleIdentifier @"com.lemonmojo.ChickenVncFramework"

#define ChickenVncFrameworkLocalizedString(key, comment)    \
NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleWithIdentifier:kChickenVncFrameworkBundleIdentifier], comment)

#define ChickenVncFrameworkBundle() \
[NSBundle bundleWithIdentifier:kChickenVncFrameworkBundleIdentifier]

#endif /* Macros_h */

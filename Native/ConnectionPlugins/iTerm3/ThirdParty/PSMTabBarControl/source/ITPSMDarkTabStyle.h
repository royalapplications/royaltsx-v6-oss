//
//  ITPSMDarkTabStyle.h
//  iTerm
//
//  Created by Brian Mock on 10/28/14.
//
//

#import <Cocoa/Cocoa.h>
#import "ITPSMTabStyle.h"
#import "ITPSMYosemiteTabStyle.h"

@interface ITPSMDarkTabStyle : ITPSMYosemiteTabStyle<ITPSMTabStyle>
+ (NSColor *)tabBarColor;
@end

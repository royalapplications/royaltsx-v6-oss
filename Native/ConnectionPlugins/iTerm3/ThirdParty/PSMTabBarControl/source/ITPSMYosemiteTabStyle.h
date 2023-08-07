//
//  ITPSMYosemiteTabStyle.h
//  ITPSMTabBarControl
//
//  Created by John Pannell on 2/17/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ITPSMTabStyle.h"
#import "ITPSMTabBarControl.h"

@interface ITPSMYosemiteTabStyle : NSObject<NSCoding, ITPSMTabStyle>

@property(nonatomic, readonly) ITPSMTabBarControl *tabBar;
@property(nonatomic, readonly) NSColor *tabBarColor;

#pragma mark - For subclasses

- (NSColor *)topLineColorSelected:(BOOL)selected;
- (BOOL)anyTabHasColor;
- (CGFloat)tabColorBrightness:(ITPSMTabBarCell *)cell;

@end

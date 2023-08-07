//
//  ITPSMTabStyle.h
//  ITPSMTabBarControl
//
//  Created by John Pannell on 2/17/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

/* 
Protocol to be observed by all style delegate objects.  These objects handle the drawing responsibilities for ITPSMTabBarCell; once the control has been assigned a style, the background and cells draw consistent with that style.  Design pattern and implementation by David Smith, Seth Willits, and Chris Forsythe, all touch up and errors by John P. :-)
*/

#import "ITPSMTabBarCell.h"
#import "ITPSMTabBarControl.h"

@protocol ITPSMTabStyle <NSObject>

// identity
- (NSString *)name;

// control specific parameters
- (float)leftMarginForTabBarControl;
- (float)rightMarginForTabBarControl;
- (float)topMarginForTabBarControl;

// add tab button
- (NSImage *)addTabButtonImage;
- (NSImage *)addTabButtonPressedImage;
- (NSImage *)addTabButtonRolloverImage;

// cell specific parameters
- (NSRect)dragRectForTabCell:(ITPSMTabBarCell *)cell orientation:(PSMTabBarOrientation)orientation;
- (NSRect)closeButtonRectForTabCell:(ITPSMTabBarCell *)cell;
- (NSRect)iconRectForTabCell:(ITPSMTabBarCell *)cell;
- (NSRect)indicatorRectForTabCell:(ITPSMTabBarCell *)cell;
- (NSRect)objectCounterRectForTabCell:(ITPSMTabBarCell *)cell;
- (float)minimumWidthOfTabCell:(ITPSMTabBarCell *)cell;
- (float)desiredWidthOfTabCell:(ITPSMTabBarCell *)cell;

// cell values
- (NSAttributedString *)attributedObjectCountValueForTabCell:(ITPSMTabBarCell *)cell;
- (NSAttributedString *)attributedStringValueForTabCell:(ITPSMTabBarCell *)cell;

// drawing
- (void)drawTabCell:(ITPSMTabBarCell *)cell highlightAmount:(CGFloat)highlightAmount;
- (void)drawBackgroundInRect:(NSRect)rect color:(NSColor*)color horizontal:(BOOL)horizontal;
- (void)drawTabBar:(ITPSMTabBarControl *)bar inRect:(NSRect)rect horizontal:(BOOL)horizontal;

- (NSColor *)accessoryFillColor;
- (NSColor *)accessoryStrokeColor;
- (void)fillPath:(NSBezierPath*)path;
- (NSColor *)accessoryTextColor;

// Should light-tinted controls be used?
- (BOOL)useLightControls;

- (NSColor *)textColorDefaultSelected:(BOOL)selected;
- (void)drawPostHocDecorationsOnSelectedCell:(ITPSMTabBarCell *)cell
                               tabBarControl:(ITPSMTabBarControl *)bar;

@end

@interface ITPSMTabBarControl (StyleAccessors)

- (NSMutableArray *)cells;
- (void)sanityCheck:(NSString *)callsite;
- (void)sanityCheck:(NSString *)callsite force:(BOOL)force;

@end

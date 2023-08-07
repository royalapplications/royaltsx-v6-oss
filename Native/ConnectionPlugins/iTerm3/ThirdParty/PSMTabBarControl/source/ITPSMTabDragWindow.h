//
//  ITPSMTabDragWindow.h
//  ITPSMTabBarControl
//
//  Created by Kent Sutherland on 6/1/06.
//  Copyright 2006 Kent Sutherland. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ITPSMTabBarCell;

@interface ITPSMTabDragWindow : NSWindow {
	ITPSMTabBarCell *_cell;
	NSImageView *_imageView;
}
+ (ITPSMTabDragWindow *)dragWindowWithTabBarCell:(ITPSMTabBarCell *)cell image:(NSImage *)image styleMask:(unsigned int)styleMask;

- (id)initWithTabBarCell:(ITPSMTabBarCell *)cell image:(NSImage *)image styleMask:(unsigned int)styleMask;
- (NSImage *)image;
@end

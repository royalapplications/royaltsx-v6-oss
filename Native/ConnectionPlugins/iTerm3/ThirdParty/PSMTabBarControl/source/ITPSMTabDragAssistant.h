//
//  ITPSMTabDragAssistant.h
//  ITPSMTabBarControl
//
//  Created by John Pannell on 4/10/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

/*
 This class is a sigleton that manages the details of a tab drag and drop.  The details were beginning to overwhelm me when keeping all of this in the control and cells :-)
 */

#import <Cocoa/Cocoa.h>
#import "ITPSMTabBarControl.h"
@class ITPSMTabBarCell;
@class ITPSMTabDragWindow;

#define kPSMTabDragAnimationSteps 8
#define kITPSMTabDragWindowAlpha 0.75
#define PI 3.1417

@interface ITPSMTabDragAssistant : NSObject

// Creation/destruction
+ (ITPSMTabDragAssistant *)sharedDragAssistant;

// Accessors
- (ITPSMTabBarControl *)sourceTabBar;
- (void)setSourceTabBar:(ITPSMTabBarControl *)tabBar;
- (ITPSMTabBarControl *)destinationTabBar;
- (void)setDestinationTabBar:(ITPSMTabBarControl *)tabBar;
- (ITPSMTabBarCell *)draggedCell;
- (void)setDraggedCell:(ITPSMTabBarCell *)cell;
- (int)draggedCellIndex;
- (void)setDraggedCellIndex:(int)value;
- (BOOL)isDragging;
- (void)setIsDragging:(BOOL)value;
- (NSPoint)currentMouseLoc;
- (void)setCurrentMouseLoc:(NSPoint)point;
- (ITPSMTabBarCell *)targetCell;
- (void)setTargetCell:(ITPSMTabBarCell *)cell;

// Functionality
- (void)startAnimationWithOrientation:(PSMTabBarOrientation)orientation width:(CGFloat)width;
- (void)startDraggingCell:(ITPSMTabBarCell *)cell fromTabBar:(ITPSMTabBarControl *)control withMouseDownEvent:(NSEvent *)event;
- (void)draggingEnteredTabBar:(ITPSMTabBarControl *)control atPoint:(NSPoint)mouseLoc;
- (void)draggingUpdatedInTabBar:(ITPSMTabBarControl *)control atPoint:(NSPoint)mouseLoc;
- (void)draggingExitedTabBar:(ITPSMTabBarControl *)control;
- (void)performDragOperation:(id<NSDraggingInfo>)sender;
- (void)draggedImageEndedAt:(NSPoint)aPoint operation:(NSDragOperation)operation;
- (void)finishDrag;

- (void)draggingBeganAt:(NSPoint)aPoint;
- (void)draggingMovedTo:(NSPoint)aPoint;

// Animation
- (void)animateDrag:(NSTimer *)timer;
- (void)calculateDragAnimationForTabBar:(ITPSMTabBarControl *)control;

// Placeholder
- (void)distributePlaceholdersInTabBar:(ITPSMTabBarControl *)control withDraggedCell:(ITPSMTabBarCell *)cell;
- (void)distributePlaceholdersInTabBar:(ITPSMTabBarControl *)control;
- (void)removeAllPlaceholdersFromTabBar:(ITPSMTabBarControl *)control;

@end

@interface ITPSMTabBarControl (DragAccessors)

- (id<ITPSMTabStyle>)style;
- (NSMutableArray *)cells;
- (void)setControlView:(id)view;
- (id)cellForPoint:(NSPoint)point cellFrame:(NSRectPointer)outFrame;
- (ITPSMTabBarCell *)lastVisibleTab;
- (int)numberOfVisibleTabs;

@end

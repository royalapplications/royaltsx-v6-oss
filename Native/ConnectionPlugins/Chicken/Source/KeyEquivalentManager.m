//
//  KeyEquivalentManager.m
//  Chicken of the VNC
//
//  Created by Jason Harris on Sun Mar 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "KeyEquivalentManager.h"
#import "KeyEquivalent.h"
#import "KeyEquivalentEntry.h"
//#import "KeyEquivalentPrefsController.h"
#import "KeyEquivalentScenario.h"
#import "RFBConnection.h"
#import "RFBView.h"
#import "Session.h"


// Scenarios
NSString *kNonConnectionWindowFrontmostScenario = @"NonConnectionWindowFrontmostScenario";
NSString *kConnectionWindowFrontmostScenario = @"ConnectionWindowFrontmostScenario";
NSString *kConnectionFullscreenScenario = @"ConnectionFullscreenScenario";

@interface KeyEquivalentManager(Private)

- (void)loadScenarios;

@end


@implementation KeyEquivalentManager

#pragma mark -
#pragma mark Private


- (void)makeAllScenariosInactive
{
	NSEnumerator *scenarioEnumerator = [mScenarioDict keyEnumerator];
	NSString *scenarioName;
	
	while ( scenarioName = [scenarioEnumerator nextObject] )
	{
		KeyEquivalentScenario *scenario = [mScenarioDict objectForKey: scenarioName];
		[scenario makeActive: NO];
	}
}


- (void)rfbViewDidBecomeKey: (RFBView *)view
{
	mKeyRFBView = view;
	Session *session = [[view delegate] session];
	if (session)
	{
        if ([session viewOnly])
            [self setCurrentScenarioToName: kNonConnectionWindowFrontmostScenario];
//        else if ([session connectionIsFullscreen])
//			[self setCurrentScenarioToName: kConnectionFullscreenScenario];
		else
			[self setCurrentScenarioToName: kConnectionWindowFrontmostScenario];
	}
}


- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	Class RFBViewClass = [RFBView class];
	Class NSScrollViewClass = [NSScrollView class];
	
	NSWindow *window = [aNotification object];
    if ([[window className] isEqualToString: @"NSCarbonMenuWindow"]) {
        /* Opening the help menu causes an NSCarbonMenuWindow to become key, but
         * then when it closes, we don't get windowDidBecomeKey for the
         * frontmost window. So, we ignore events for NSCarbonMenuWindow
         * instances. Since NSCarbonMenuWindow is not part of the public API, we
         * we can't do [NSCarbonMenuWindow class], so we have to a string
         * compare. */
        return;
    }

	NSView *contentView = [window contentView];
	if ( [contentView isKindOfClass: NSScrollViewClass] )
		contentView = [(NSScrollView *)contentView documentView];
	if ( [contentView isKindOfClass: RFBViewClass] )
	{
		[self rfbViewDidBecomeKey: (RFBView *)contentView];
 		return;
	}
	
	NSEnumerator *subviewEnumerator = [[contentView subviews] objectEnumerator];
	NSView *subview;
	
	while ( subview = [subviewEnumerator nextObject] )
	{
		if ( [subview isKindOfClass: NSScrollViewClass] )
			subview = [(NSScrollView *)subview documentView];
		if ( [subview isKindOfClass: RFBViewClass] )
		{
			[self rfbViewDidBecomeKey: (RFBView *)subview];
			return;
		}
	}
	mKeyRFBView = nil;
	if (window)
		[self setCurrentScenarioToName: kNonConnectionWindowFrontmostScenario];
}


- (void)windowWillClose:(NSNotification *)aNotification
{
	NSWindow *closingWindow = [aNotification object];

    // remove window from KeyEquivalentScenarios if necessary
    [self removeEquivalentForWindow:[closingWindow title]];

    // if all windows now closed, go to non-connection window scenario
	NSEnumerator *windowEnumerator = [[NSApp windows] objectEnumerator];
	NSWindow *window;
	while ( window = [windowEnumerator nextObject] )
    {
		if ( window != closingWindow && [window isVisible] )
        {
			return;
        }
	}
	[self setCurrentScenarioToName: kNonConnectionWindowFrontmostScenario];
}


- (NSString *)description
{  return [mScenarioDict description];  }


#pragma mark -
#pragma mark Obtaining An Instance

+ (id)defaultManager
{
	static id sDefaultManager = nil;
	
	if ( ! sDefaultManager )
	{
		sDefaultManager = [[self alloc] init];
		NSParameterAssert( sDefaultManager != nil );
	}
	return sDefaultManager;
}


- (id)init
{
	if ( self = [super init] )
	{
        /* Get the unaltered key equivalents, which form the basis for our
         * defaults. */
        standardKeyEquivalents = [[KeyEquivalentScenario alloc] initFromMainMenu];
        [self loadScenarios];

		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver: self selector: @selector(windowDidBecomeKey:) name: NSWindowDidBecomeKeyNotification object: nil];
		[notificationCenter addObserver: self selector: @selector(windowWillClose:) name: NSWindowWillCloseNotification object: nil];
	}
	return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[mScenarioDict release];
	[mCurrentScenarioName release];
	[super dealloc];
}


#pragma mark -
#pragma mark Persistent Scenarios


- (void)loadScenarios
{
//    return;
//
//	[self loadScenariosFromPreferences];
//	if ( ! mScenarioDict || [mScenarioDict count] == 0 )
//		[self loadScenariosFromDefaults];
//	NSParameterAssert( mScenarioDict && [mScenarioDict count] > 0 );
}


- (void)loadScenariosFromPreferences
{
//    return;
//
//	NSUserDefaults *defaults;
//	NSDictionary *foundDict;
//
//	defaults = [NSUserDefaults standardUserDefaults];
//	[defaults synchronize];
//	foundDict = [defaults objectForKey: @"KeyEquivalentScenarios"];
//	if ( foundDict )
//		[self takeScenariosFromPropertyList: foundDict];
}


/* Load default settings for key equivalent scenarios. */
- (void)loadScenariosFromDefaults
{
//    return;
//    
//    KeyEquivalentScenario   *minimal;
//    NSMenuItem              *fullscreen;
//    KeyEquivalentEntry      *entry;
//    
//    /* For connection window and fullscreen scenarios, use only a single
//     * equivalent: for entering and exiting fullscreen mode. */
//    fullscreen = [[NSApp delegate] getFullScreenMenuItem];
//    entry = [[KeyEquivalentEntry alloc] initWithMenuItem:fullscreen];
//    minimal = [[KeyEquivalentScenario alloc] init];
//    [minimal setEntry:entry
//        forEquivalent:[standardKeyEquivalents
//                                        keyEquivalentForMenuItem:fullscreen]];
//
//    [mScenarioDict release];
//    mScenarioDict = [[NSMutableDictionary alloc] init];
//    [mScenarioDict setObject:[[standardKeyEquivalents copy] autorelease]
//                      forKey:kNonConnectionWindowFrontmostScenario];
//    [mScenarioDict setObject:minimal forKey:kConnectionWindowFrontmostScenario];
//    [mScenarioDict setObject:[[minimal copy] autorelease]
//                      forKey:kConnectionFullscreenScenario];
//
//    [entry release];
//    [minimal release];
}


- (void)makeScenariosPersistant
{
	NSUserDefaults *defaults;
	
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: [self propertyList] forKey: @"KeyEquivalentScenarios"];
}


- (void)restoreDefaults
{
	NSUserDefaults *defaults;
	
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey: @"KeyEquivalentScenarios"];
	[self loadScenariosFromDefaults];
}


- (NSDictionary *)propertyList
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSEnumerator *scenarioNameEnumerator = [mScenarioDict keyEnumerator];
	NSString *scenarioName;
	
	while ( scenarioName = [scenarioNameEnumerator nextObject] )
	{
		NSArray *scenarioArray = [[mScenarioDict objectForKey: scenarioName] propertyList];
		[dict setObject: scenarioArray forKey: scenarioName];
	}
	return dict;
}


- (void)takeScenariosFromPropertyList: (NSDictionary *)propertyList
{
	if ( ! mScenarioDict )
		mScenarioDict = [[NSMutableDictionary alloc] init];
	NSEnumerator *scenarioNameEnumerator = [propertyList keyEnumerator];
	NSString *scenarioName;
	while ( scenarioName = [scenarioNameEnumerator nextObject] )
	{
		KeyEquivalentScenario *scenario = [[KeyEquivalentScenario alloc] initWithPropertyList: [propertyList objectForKey: scenarioName]];
		[mScenarioDict setObject: scenario forKey: scenarioName];
		[scenario release];
	}
}


#pragma mark -
#pragma mark Dealing With The Current Scenario


- (void)setCurrentScenarioToName: (NSString *)scenario
{
	if (scenario == mCurrentScenarioName)
		return;
	mCurrentScenario = [mScenarioDict objectForKey: scenario];
	[self makeAllScenariosInactive];
	[mCurrentScenario makeActive: YES];
	[mCurrentScenarioName release];
	mCurrentScenarioName = [scenario retain];
}


- (NSString *)currentScenarioName
{  return mCurrentScenarioName;  }


#pragma mark -
#pragma mark Obtaining Scenario Equivalents


- (KeyEquivalentScenario *)keyEquivalentsForScenarioName: (NSString *)scenario
{  return [mScenarioDict objectForKey: scenario];  }


#pragma mark -
#pragma mark Performing Key Equivalants


- (BOOL)performEquivalentWithCharacters: (NSString *)characters modifiers:(NSEventModifierFlags)modifiers
{
	KeyEquivalent* keyEquivalent = [[KeyEquivalent alloc] initWithCharacters:characters modifiers:modifiers];
	
	NSMenuItem* menuItem = [mCurrentScenario menuItemForKeyEquivalent:keyEquivalent];
	[keyEquivalent release];
	
	if (menuItem) {
		[NSApp sendAction:menuItem.action to:menuItem.target from:menuItem];
		
		return YES;
	}
	
	return NO;
}


#pragma mark -
#pragma mark Performing Key Equivalants


- (RFBView *)keyRFBView
{  return mKeyRFBView;  }


- (void)removeEquivalentForWindow:(NSString *)title
{
    KeyEquivalentEntry      *entry;
    NSEnumerator            *e = [mScenarioDict objectEnumerator];
    KeyEquivalentScenario   *scen;
    
    entry = [[KeyEquivalentEntry alloc] initWithTitle: title];
    while (scen = [e nextObject])
        [scen removeEntry: entry];
    [entry release];
//    [[KeyEquivalentPrefsController sharedController] menusChanged];
}

@end

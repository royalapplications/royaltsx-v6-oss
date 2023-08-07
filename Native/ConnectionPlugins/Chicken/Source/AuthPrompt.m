/* AuthPrompt.m
 * Copyright (C) 2011 Dustin Cartwright
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#import <AuthPrompt.h>
#import "Macros.h"

@implementation AuthPrompt

- (id)initWithDelegate:(id<AuthPromptDelegate>)aDelegate
{
    if (self = [super init]) {
        delegate = aDelegate;
		
		NSBundle* bundle = [NSBundle bundleForClass:AuthPrompt.class];
		
		NSArray* _topLevelObjects;
		[bundle loadNibNamed:@"AuthPrompt" owner:self topLevelObjects:&_topLevelObjects];
		
		topLevelObjects = _topLevelObjects;
		
        [self loadLanguage];
    }
    return self;
}

- (void)dealloc
{
	if (topLevelObjects) {
		[topLevelObjects release]; topLevelObjects = nil;
	}
	
	[super dealloc];
}

- (void)loadLanguage
{
    panel.title = ChickenVncFrameworkLocalizedString(@"VNC Plugin (Chicken)", nil);
    passwordFieldLabel.stringValue = ChickenVncFrameworkLocalizedString(@"SSH Password:", nil);
    buttonCancel.title = ChickenVncFrameworkLocalizedString(@"Cancel", nil);
    buttonOk.title = ChickenVncFrameworkLocalizedString(@"OK", nil);
}

- (void)runSheetOnWindow:(NSWindow *)window
{
	__weak AuthPrompt* weakSelf = self;
	
	[window beginSheet:panel completionHandler:^(NSModalResponse returnCode) {
		AuthPrompt* strongSelf = weakSelf;
		
		if (!strongSelf) {
			return;
		}
		
		[strongSelf->panel orderOut:self];
		
		[strongSelf autorelease];
	}];
	
    [self retain];
}

- (void)stopSheet
{
    [NSApp endSheet:panel];
}

- (IBAction)enterPassword:(id)sender
{
    [delegate authPasswordEntered:[passwordField stringValue]];
    [NSApp endSheet:panel];
}

- (IBAction)cancel:(id)sender
{
    [NSApp endSheet:panel];
    [delegate authCancelled];
}

@end

/* Copyright (C) 1998-2000  Helmut Maierhofer <helmut.maierhofer@chello.at>
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

#import "Session.h"
#import "IServerData.h"
#import "KeyEquivalent.h"
#import "KeyEquivalentManager.h"
#import "KeyEquivalentScenario.h"
#import "PrefController.h"
#import "ProfileManager.h"
#import "RFBConnection.h"
#import "RFBView.h"
#import "SshWaiter.h"
#import "Macros.h"
#define XK_MISCELLANY
#include <X11/keysymdef.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1050
@interface NSAlert(AvailableInLeopard)
    - (void)setShowsSuppressionButton:(BOOL)flag;
    - (NSButton *)suppressionButton;
@end
#endif

/* Ah, the joy of supporting 4 different releases of the OS */
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1050
#if __LP64__
typedef long NSInteger;
#else
typedef int NSInteger;
#endif
#endif

@interface NSScrollView(AvailableInLion)
    - (void)setScrollerStyle:(NSInteger)newScrollerStyle;
@end

enum {
    NSScrollerStyleLegacy = 0,
    NSScrollerStyleOverlay = 1
};
#endif

@interface Session(Private)

- (void)startTimerForReconnectSheet;

- (void)displayPasswordSheet;

@end

@implementation Session

@synthesize scrollView, delegate;

- (id)initWithConnection:(RFBConnection*)aConnection andDelegate:(id<SessionDelegate>)aDelegate andMainWindow:(NSWindow*)aWindow {
	if ((self = [super init]) == nil) {
        return nil;
	}
    
    connection = [aConnection retain];
    server_ = [[connection server] retain];
    host = [[server_ host] retain];
    sshTunnel = [[connection sshTunnel] retain];
    
    _isFullscreen = NO; // jason added for fullscreen display
    
//    [NSBundle loadNibNamed:@"RFBConnection.nib" owner:self];
	NSBundle* bundle = [NSBundle bundleForClass:Session.class];

	NSArray* topLevelObjects;

	BOOL loadSuccess = [bundle loadNibNamed:@"RFBConnection"
									  owner:self
							topLevelObjects:&topLevelObjects];

	NSAssert(loadSuccess, @"Failed to load nib");
	_topLevelObjects = [topLevelObjects retain];
	
	delegate = aDelegate;
	window = aWindow;
	
	[rfbView registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeString, NSPasteboardTypeFileURL, nil]];
    
    password = [[connection password] retain];
    
    _reconnectWaiter = nil;
    _reconnectSheetTimer = nil;
    
    _horizScrollFactor = 0;
    _vertScrollFactor = 0;
    
    /* On 10.7 Lion, the overlay scrollbars don't reappear properly on hover.
     * So, for now, we're going to force legacy scrollbars. */
    if ([scrollView respondsToSelector:@selector(setScrollerStyle:)])
        [scrollView setScrollerStyle:NSScrollerStyleLegacy];
    
    _connectionStartDate = [[NSDate alloc] init];
    
    [connection setSession:self];
    [connection setRfbView:rfbView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tintChanged:)
                                                 name:ProfileTintChangedMsg
                                               object:[connection profile]];
    
	[connection setFrameBufferUpdateSeconds: [[PrefController sharedController] frontFrameBufferUpdateSeconds]];
    [rfbView setTint:[[connection profile] tintWhenFront:YES]];
    
    [self loadLanguage];
    
    return self;
}

- (id)initWithConnection:(RFBConnection *)aConnection
{
    return [self initWithConnection:aConnection andDelegate:nil andMainWindow:nil];
}

- (void)loadLanguage
{
    authHeader.stringValue = ChickenVncFrameworkLocalizedString(@"AuthenticationFailed", nil);
    passwordFieldLabel.stringValue = ChickenVncFrameworkLocalizedString(@"Enter password to retry:", nil);
    buttonAuthCancel.title = ChickenVncFrameworkLocalizedString(@"Cancel", nil);
    buttonAuthReconnect.title = ChickenVncFrameworkLocalizedString(@"Reconnect", nil);
    reconnectingFieldLabel.stringValue = ChickenVncFrameworkLocalizedString(@"Reconnecting ...", nil);
    buttonReconnectingCancel.title = ChickenVncFrameworkLocalizedString(@"Cancel", nil);
}

- (void)dealloc
{
    if (_isFullscreen) {
        if (CGDisplayRelease(kCGDirectMainDisplay) != kCGErrorSuccess) {
            NSLog( @"Couldn't release the main display!" );
            /* If we can't release the main display, then we're probably about
             * to leave the computer in an unusable state. */
            //[NSApp terminate:self];
        }
        [self endFullscreenScrolling];
    }

    [connection setSession:nil];
	
	if (connection) {
		[connection release]; connection = nil;
	}
	
    [NSNotificationCenter.defaultCenter removeObserver:self];
	
	if (titleString) {
		[titleString release]; titleString = nil;
	}
	
	if (server_) {
		[(id)server_ release]; server_ = nil;
	}
	
	if (host) {
		[host release]; host = nil;
	}
	
	if (password) {
		[password release]; password = nil;
	}
	
	if (sshTunnel) {
		[sshTunnel close];
		[sshTunnel release]; sshTunnel = nil;
	}
    
	if (realDisplayName) {
		[realDisplayName release]; realDisplayName = nil;
	}
	
	if (_reconnectSheetTimer) {
		[_reconnectSheetTimer invalidate];
		[_reconnectSheetTimer release]; _reconnectSheetTimer = nil;
	}
	
	if (_reconnectWaiter) {
		[_reconnectWaiter cancel];
		[_reconnectWaiter release]; _reconnectWaiter = nil;
	}

	[newTitlePanel orderOut:self];
	[optionPanel orderOut:self];
	
	//[window close];
    [windowedWindow close];
	
	if (_connectionStartDate) {
		[_connectionStartDate release]; _connectionStartDate = nil;
	}
	
	if (_topLevelObjects) {
		[_topLevelObjects release]; _topLevelObjects = nil;
	}
	
    [super dealloc];
}

- (BOOL)viewOnly
{
    return [server_ viewOnly];
}

// FX EDIT
- (BOOL)scaling
{
    return [server_ scaling];
}

- (RFBConnection*)theConnection
{
    return connection;
}

- (NSView *)theView
{
    return rfbView;
}

/* Begin a reconnection attempt to the server. */
- (void)beginReconnect
{
    if (sshTunnel) {
        /* Reuse the same SSH tunnel if we have one. */
        _reconnectWaiter = [[SshWaiter alloc] initWithServer:server_
                                                    delegate:self
                                                      window:window
                                                   sshTunnel:sshTunnel];
    } else {
        _reconnectWaiter = [[ConnectionWaiter waiterForServer:server_
                                                     delegate:self
                                                       window:window] retain];
    }
	
    NSString *templ = ChickenVncFrameworkLocalizedString(@"NoReconnection", nil);
    NSString *err = [NSString stringWithFormat:templ, host];
    [_reconnectWaiter setErrorStr:err];
    [self startTimerForReconnectSheet];
}

- (void)startTimerForReconnectSheet
{
    _reconnectSheetTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
            target:self selector:@selector(createReconnectSheet:)
            userInfo:nil repeats:NO] retain];
}

//- (void)connectionTerminatedSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
//{
//	/* One might reasonably argue that this should be handled by the connection manager. */
//	switch (returnCode) {
//		case NSAlertDefaultReturn:
//			break;
//		case NSAlertAlternateReturn:
//            [self beginReconnect];
//            return;
//		default:
//			NSLog(@"Unknown alert returnvalue: %d", returnCode);
//			break;
//	}
//
//    if (delegate && [delegate respondsToSelector:@selector(serverClosed)])
//        [delegate serverClosed];
//}

- (void)connectionProblem
{
    [connection closeConnection];
    [connection release];
    connection = nil;
}

- (void)endSession
{
    [self endFullscreenScrolling];
    [sshTunnel close];
    
    if (delegate && [delegate respondsToSelector:@selector(serverClosed)])
        [delegate serverClosed];
}

/* Some kind of connection failure. Decide whether to try to reconnect. */
- (void)terminateConnection:(NSString*)aReason
{
    if (hasTerminated)
        return;
    
    NSLog(@"ChickenVNC: terminateConnection");
    
    hasTerminated = YES;
    
    if (!connection) {
        if(aReason) {
            if (delegate && [delegate respondsToSelector:@selector(serverClosedWithMessage:)])
                [delegate performSelector:@selector(serverClosedWithMessage:) withObject:aReason];
        } else {
            if (delegate && [delegate respondsToSelector:@selector(serverClosed)])
                [delegate performSelector:@selector(serverClosed)];
        }
        
        return;
    }

    [self connectionProblem];
    [self endFullscreenScrolling];
    
    //NSLog(@"ChickenVNC: terminateConnection 02");
    
    if(aReason) {
        if (delegate && [delegate respondsToSelector:@selector(serverClosedWithMessage:)]) {
            [delegate performSelector:@selector(serverClosedWithMessage:) withObject:aReason];
        }
    } else {
        if (delegate && [delegate respondsToSelector:@selector(serverClosed)])
            [delegate performSelector:@selector(serverClosed)];
    }
    
    /* if ([passwordSheet isVisible]) {
        //User is in middle of entering password.
        if ([server_ doYouSupport:CONNECT]) {
            NSLog(@"Will reconnect to server when password entered. Reason for disconnect was: %@", aReason);
            return;
        } else {
            //Server doesn't support reconnect, so we have to interrupt the
            //password sheet to show an error
            [NSApp endSheet:passwordSheet];

            NSBeginAlertSheet(ChickenVncFrameworkLocalizedString(@"ConnectionTerminated", nil),
                    ChickenVncFrameworkLocalizedString(@"Okay", nil), nil, nil, window, self,
                    @selector(connectionTerminatedSheetDidEnd:returnCode:contextInfo:),
                    nil, nil, aReason);
        }
    } else {
        if(aReason) {
            //NSLog(@"ChickenVNC: terminateConnection 03");
            
            NSTimeInterval timeout = [[PrefController sharedController] intervalBeforeReconnect];
            BOOL supportReconnect = [server_ doYouSupport:CONNECT];

            [_reconnectReason setStringValue:aReason];
			if (supportReconnect
                    && -[_connectionStartDate timeIntervalSinceNow] > timeout) {
                NSLog(@"Automatically reconnecting to server.  The connection was closed because: \"%@\".", aReason);
				// begin reconnect
                [self beginReconnect];
			}
			else {
                //NSLog(@"ChickenVNC: terminateConnection 04");
				// Ask what to do
				NSString *header = ChickenVncFrameworkLocalizedString( @"ConnectionTerminated", nil );
				NSString *okayButton = ChickenVncFrameworkLocalizedString( @"Okay", nil );
				NSString *reconnectButton =  ChickenVncFrameworkLocalizedString( @"Reconnect", nil );
				NSBeginAlertSheet(header, okayButton, supportReconnect ? reconnectButton : nil, nil, window, self, @selector(connectionTerminatedSheetDidEnd:returnCode:contextInfo:), nil, nil, aReason);
			}
        } else {
            //NSLog(@"ChickenVNC: terminateConnection 05");
            
            if (delegate && [delegate respondsToSelector:@selector(serverClosed)])
                [delegate serverClosed];
        }
    } */
}

/* Authentication failed: give the user a chance to re-enter password. */
- (void)authenticationFailed:(NSString *)aReason
{
    NSLog(@"ChickenVNC: authenticationFailed");
    
    if (connection == nil)
        return;

    if (![server_ doYouSupport:CONNECT])
        [self terminateConnection:ChickenVncFrameworkLocalizedString(@"AuthenticationFailed", nil)];

    [self connectionProblem];
    [authHeader setStringValue:ChickenVncFrameworkLocalizedString(@"AuthenticationFailed", nil)];
    [authMessage setStringValue: aReason];
    [[passwordSheet defaultButtonCell] setTitle:ChickenVncFrameworkLocalizedString(@"Reconnect",
            nil)];
    [self displayPasswordSheet];
}

- (void)authenticationFailedFx:(NSString *)aReason
{
    if (hasTerminated)
        return;
    
    NSLog(@"ChickenVNC: authenticationFailedFx");
    
    hasTerminated = YES;
    
    if (delegate && [delegate respondsToSelector:@selector(authenticationFailed:)]) {
        [delegate performSelector:@selector(authenticationFailed:) withObject:aReason];
    }
}

- (void)promptForPassword
{
    NSLog(@"ChickenVNC: promptForPassword");
    
    [authHeader setStringValue:ChickenVncFrameworkLocalizedString(@"AuthenticationRequired", nil)];
    [authMessage setStringValue:@""];
    [[passwordSheet defaultButtonCell] setTitle:ChickenVncFrameworkLocalizedString(@"Connect", nil)];
    [self displayPasswordSheet];
}

- (void)displayPasswordSheet
{
    if ([server_ respondsToSelector:@selector(setRememberPassword:)])
        [rememberNewPassword setState: [server_ rememberPassword]];
    else
        [rememberNewPassword setHidden:YES];
	
	__weak Session* weakSelf = self;
	
	[window beginSheet:passwordSheet completionHandler:^(NSModalResponse returnCode) {
		[weakSelf passwordEnteredFor:passwordSheet
						  returnCode:returnCode
						 contextInfo:nil];
	}];
}

/* User entered new password */
- (IBAction)reconnectWithNewPassword:(id)sender
{
    [password release];
    password = [[passwordField stringValue] retain];
    if ([rememberNewPassword state])
        [server_ setPassword: password];
    if ([server_ respondsToSelector:@selector(setRememberPassword:)]) {
        [server_ setRememberPassword: [rememberNewPassword state]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ServerChangeMsg
                                                            object:server_];
    }

    [_reconnectReason setStringValue:@""];
    if (connection)
        [connection setPassword:password];
    else
        [self beginReconnect];
    [NSApp endSheet:passwordSheet];
}

/* User cancelled chance to enter new password */
- (IBAction)dontReconnect:(id)sender
{
    [NSApp endSheet:passwordSheet];
    [self connectionProblem];
    [self endSession];
}

- (void)passwordEnteredFor:(NSWindow *)window
				returnCode:(NSModalResponse)retCode
			   contextInfo:(void *)info
{
    [passwordSheet orderOut:self];
}

/* Close the connection and then reconnect */
- (IBAction)forceReconnect:(id)sender
{
    if (connection == nil)
        return;

    [self connectionProblem];
    [_reconnectReason setStringValue:@""];

    // Force ourselves to use a new SSH tunnel
    [sshTunnel close];
    [sshTunnel release];
    sshTunnel = nil;

    [self beginReconnect];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
    if ([item action] == @selector(forceReconnect:))
        // we only enable Force Reconnect menu item if server supports it
        return [server_ doYouSupport:CONNECT];
    else
        return [self respondsToSelector:[item action]];
}

- (void)setSize:(NSSize)aSize
{
    _maxSize = aSize;
}

- (NSSize)contentSize {
    return rfbView.frame.size;
}

/* Returns the maximum possible size for the window. Also, determines whether or
 * not the scrollbars are necessary. */
// FX EDIT
//- (NSSize)_maxSizeForWindowSize:(NSSize)aSize;
//{
//    if (self.scaling) {
//        horizontalScroll = verticalScroll = NO;
//
//        return aSize;
//    } else {
//        NSRect  winframe;
//        NSSize	maxviewsize;
//        BOOL usesFullscreenScrollers = [PrefController.sharedController fullscreenHasScrollbars];
//
//        horizontalScroll = verticalScroll = NO;
//
//        maxviewsize = [NSScrollView frameSizeForContentSize:rfbView.frame.size
//                                      hasHorizontalScroller:horizontalScroll
//                                        hasVerticalScroller:verticalScroll
//                                                 borderType:NSNoBorder];
//
//        if (!_isFullscreen || usesFullscreenScrollers) {
//            if(aSize.width < maxviewsize.width) {
//                horizontalScroll = YES;
//            }
//            if(aSize.height < maxviewsize.height) {
//                verticalScroll = YES;
//            }
//        }
//
//        maxviewsize = [NSScrollView frameSizeForContentSize:rfbView.frame.size
//                                      hasHorizontalScroller:horizontalScroll
//                                        hasVerticalScroller:verticalScroll
//                                                 borderType:NSNoBorder];
//        winframe = window.frame;
//        winframe.size = maxviewsize;
//        winframe = [NSWindow frameRectForContentRect:winframe styleMask:window.styleMask];
//
//        return winframe.size;
//    }
//}

/* Sets up window. */
- (void)setupWindow
{
    NSRect wf;
	NSRect screenRect;

	screenRect = NSScreen.mainScreen.visibleFrame;
    wf.origin.x = wf.origin.y = 0;
	
	NSSize size = [NSScrollView frameSizeForContentSize:_maxSize
								horizontalScrollerClass:nil
								  verticalScrollerClass:nil
											 borderType:NSNoBorder
											controlSize:NSControlSizeRegular
										  scrollerStyle:NSScrollerStyleLegacy];
	
	wf.size = size;
	
    wf = [NSWindow frameRectForContentRect:wf styleMask:window.styleMask];
	
	if (NSWidth(wf) > NSWidth(screenRect)) {
		horizontalScroll = YES;
		wf.size.width = NSWidth(screenRect);
	}
	
	if (NSHeight(wf) > NSHeight(screenRect)) {
		verticalScroll = YES;
		wf.size.height = NSHeight(screenRect);
	}
	
	// According to the Human Interace Guidelines, new windows should be "visually centered"
	// If screenRect is X1,Y1-X2,Y2, and wf is x1,y1 -x2,y2, then
	// the origin (bottom left point of the rect) for wf should be
	// Ox = ((X2-X1)-(x2-x1)) * (1/2)    [I.e., one half screen width less window width]
	// Oy = ((Y2-Y1)-(y2-y1)) * (2/3)    [I.e., two thirds screen height less window height]
	// Then the origin must be offset by the "origin" of the screen rect.
	// Note that while Rects are floats, we seem to have an issue if the origin is
	// not an integer, so we use the floor() function.
	wf.origin.x = floor((NSWidth(screenRect) - NSWidth(wf))/2 + NSMinX(screenRect));
	wf.origin.y = floor((NSHeight(screenRect) - NSHeight(wf))*2/3 + NSMinY(screenRect));
	
    // :TOFIX: this doesn't work for unnamed servers
	/* serverName = [server_ name];
	if(![window setFrameUsingName:serverName]) {
		// NSLog(@"Window did NOT have an entry: %@\n", serverName);
		[window setFrame:wf display:NO];
	}
	[window setFrameAutosaveName:serverName]; */

    [scrollView reflectScrolledClipView:scrollView.contentView];
    
    if (self.scaling) {
        horizontalScroll = verticalScroll = NO;
    }

    [connection installMouseMovedTrackingRect];
    
    /* [window makeFirstResponder:rfbView];
	[self windowDidResize: nil];
    [window makeKeyAndOrderFront:self];
    [window display]; */
    
	if (delegate && [delegate respondsToSelector:@selector(sessionResized)]) {
        [delegate sessionResized];
	}
}

- (void)setNewTitle:(id)sender
{
	if (titleString) {
		[titleString release]; titleString = nil;
	}
	
    titleString = [[newTitleField stringValue] copy];

    [window setTitle:titleString];
    [newTitlePanel orderOut:self];
}

- (void)setDisplayName:(NSString*)aName
{
	if (realDisplayName) {
		[realDisplayName release]; realDisplayName = nil;
	}
	
    realDisplayName = [aName copy];
	
	if (titleString) {
		[titleString release]; titleString = nil;
	}
	
	titleString = [realDisplayName copy]; // [[[RFBConnectionManager sharedManager] translateDisplayName:realDisplayName forHost:host] retain];
	
    [window setTitle:titleString];
}

- (void)frameBufferUpdateComplete
{
    if (optionPanel &&
        [optionPanel isVisible]) {
        [statisticField setStringValue:[connection statisticsString]];
    }
}

- (void)resize:(NSSize)size
{
//    NSSize  maxSize;
//    NSRect  frame;
    
    if (delegate && [delegate respondsToSelector:@selector(sessionResized)]) {
        [delegate sessionResized];
    }

    // resize window, if necessary
    
//    // FX EDIT
//    if (!self.scaling) {
//        maxSize = [self _maxSizeForWindowSize:[[window contentView] frame].size];
//        frame = [window frame];
//
//		if (frame.size.width > maxSize.width) {
//            frame.size.width = maxSize.width;
//		}
//
//		if (frame.size.height > maxSize.height) {
//            frame.size.height = maxSize.height;
//		}
//
//        [window setFrame:frame display:YES];
//    }
//
//    [self windowDidResize:nil]; // setup scroll bars if necessary
}

- (void)requestFrameBufferUpdate:(id)sender
{
    [connection requestFrameBufferUpdate:sender];
}

- (void)sendCmdOptEsc: (id)sender
{
    [connection sendKeyCode: XK_Alt_L pressed: YES];
    [connection sendKeyCode: XK_Meta_L pressed: YES];
    [connection sendKeyCode: XK_Escape pressed: YES];
    [connection sendKeyCode: XK_Escape pressed: NO];
    [connection sendKeyCode: XK_Meta_L pressed: NO];
    [connection sendKeyCode: XK_Alt_L pressed: NO];
    [connection writeBuffer];
}

- (void)sendCtrlAltDel: (id)sender
{
    [connection sendKeyCode: XK_Control_L pressed: YES];
    [connection sendKeyCode: XK_Alt_L pressed: YES];
    [connection sendKeyCode: XK_Delete pressed: YES];
    [connection sendKeyCode: XK_Delete pressed: NO];
    [connection sendKeyCode: XK_Alt_L pressed: NO];
    [connection sendKeyCode: XK_Control_L pressed: NO];
    [connection writeBuffer];
}

- (void)sendPauseKeyCode: (id)sender
{
    [connection sendKeyCode: XK_Pause pressed: YES];
    [connection sendKeyCode: XK_Pause pressed: NO];
    [connection writeBuffer];
}

- (void)sendBreakKeyCode: (id)sender
{
    [connection sendKeyCode: XK_Break pressed: YES];
    [connection sendKeyCode: XK_Break pressed: NO];
    [connection writeBuffer];
}

- (void)sendPrintKeyCode: (id)sender
{
    [connection sendKeyCode: XK_Print pressed: YES];
    [connection sendKeyCode: XK_Print pressed: NO];
    [connection writeBuffer];
}

- (void)sendExecuteKeyCode: (id)sender
{
    [connection sendKeyCode: XK_Execute pressed: YES];
    [connection sendKeyCode: XK_Execute pressed: NO];
    [connection writeBuffer];
}

- (void)sendInsertKeyCode: (id)sender
{
    [connection sendKeyCode: XK_Insert pressed: YES];
    [connection sendKeyCode: XK_Insert pressed: NO];
    [connection writeBuffer];
}

- (void)sendDeleteKeyCode: (id)sender
{
    [connection sendKeyCode: XK_Delete pressed: YES];
    [connection sendKeyCode: XK_Delete pressed: NO];
    [connection writeBuffer];
}

- (void)paste:(id)sender
{
    [connection pasteFromPasteboard:[NSPasteboard generalPasteboard]];
}

- (void)sendPasteboardToServer:(id)sender
{
    [self sendPasteboardToServer:sender automaticallyAllowingLossyConversion:NO];
}

- (void)sendPasteboardToServer:(id)sender automaticallyAllowingLossyConversion:(BOOL)automaticallyAllowLossyConversion
{
    [connection sendPasteboardToServer:[NSPasteboard generalPasteboard] automaticallyAllowingLossyConversion:automaticallyAllowLossyConversion];
}

/* --------------------------------------------------------------------------------- */
- (void)openNewTitlePanel:(id)sender
{
    [newTitleField setStringValue:titleString];
    [newTitlePanel makeKeyAndOrderFront:self];
}

/* --------------------------------------------------------------------------------- */
- (BOOL)hasKeyWindow
{
    return [window isKeyWindow];
}

/* Window delegate methods */

- (void)windowDidDeminiaturize:(NSNotification *)aNotification
{
    float s = [[PrefController sharedController] frontFrameBufferUpdateSeconds];

    [connection setFrameBufferUpdateSeconds:s];
	[connection installMouseMovedTrackingRect];
}

- (void)windowDidMiniaturize:(NSNotification *)aNotification
{
    float s = [[PrefController sharedController] maxPossibleFrameBufferUpdateSeconds];

    [connection setFrameBufferUpdateSeconds:s];
	[connection removeMouseMovedTrackingRect];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    // dealloc closes the window, so we have to null it out here
    // The window will autorelease itself when closed.  If we allow terminateConnection
    // to close it again, it will get double-autoreleased.  Bummer.
    window = NULL;
    //[self endSession];
}

// FX EDIT
//- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
//{
//    if (self.scaling) {
//        return proposedFrameSize;
//    } else {
//        NSSize max = [self _maxSizeForWindowSize:proposedFrameSize];
//
//        max.width = proposedFrameSize.width > max.width
//			? max.width
//			: proposedFrameSize.width;
//
//        max.height = proposedFrameSize.height > max.height
//			? max.height
//			: proposedFrameSize.height;
//
//        return max;
//    }
//}

- (void)windowDidResize:(NSNotification *)aNotification
{
    // FX EDIT
    if (self.scaling) {
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setHasVerticalScroller:NO];
    } else {
        [scrollView setHasHorizontalScroller:horizontalScroll];
        [scrollView setHasVerticalScroller:verticalScroll];
    }
    
//    if (_isFullscreen) {
//        [self removeFullscreenTrackingRects];
//        [self installFullscreenTrackingRects];
//    }
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    if (!_isFullscreen) {
        /* If the user sets and uses a keyboard shortcut, then they can make us
         * key while another window is in fullscreen mode. Because of this
         * possibility, we need to make the other connections windowed. */
        if (![window isKeyWindow]) {
            /* If some other window was in fullscreen mode, it will become key,
             * so we need to make our own window key again. Then this method
             * will be called again, so we can return from this invocation. */
            [window makeKeyWindow];
            return;
        }
    }
	[connection installMouseMovedTrackingRect];
	[connection setFrameBufferUpdateSeconds: [[PrefController sharedController] frontFrameBufferUpdateSeconds]];
    [rfbView setTint:[[connection profile] tintWhenFront:YES]];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[connection removeMouseMovedTrackingRect];
	[connection setFrameBufferUpdateSeconds: [[PrefController sharedController] otherFrameBufferUpdateSeconds]];
    [rfbView setTint:[[connection profile] tintWhenFront:NO]];
	
	//Reset keyboard state on remote end
	[[connection eventFilter] clearAllEmulationStates];
}

- (void)tintChanged:(NSNotification *)notif
{
    [rfbView setTint:[[connection profile] tintWhenFront:[window isKeyWindow]]];
}

- (void)openOptions:(id)sender
{
    [infoField setStringValue: [connection infoString]];
    [statisticField setStringValue:[connection statisticsString]];
    [optionPanel setTitle:titleString];
    [optionPanel makeKeyAndOrderFront:self];
}

//- (IBAction)makeConnectionWindowed: (id)sender {
//	_isFullscreen = NO;
//	[scrollView retain];
//	[scrollView removeFromSuperview];
//	[window setDelegate:nil];
//	[window close];
//	if (CGDisplayRelease( kCGDirectMainDisplay ) != kCGErrorSuccess) {
//		NSLog( @"Couldn't release the main display!" );
//	}
//    window = windowedWindow;
//    windowedWindow = nil;
//    [window orderFront:nil];
//	[window setDelegate:self];
//	[window setContentView: scrollView];
//	[scrollView release];
//	[self _maxSizeForWindowSize:window.contentView.frame.size];
//	[window setTitle:titleString];
//	[window makeFirstResponder:rfbView];
//	[self windowDidResize:nil];
//	[window makeKeyAndOrderFront:nil];
//	[connection viewFrameDidChange: nil];
//    [rfbView setTint:[[connection profile] tintWhenFront:YES]];
//}

- (void)mouseEntered:(NSEvent *)theEvent {
	NSTrackingRectTag trackingNumber = [theEvent trackingNumber];

    if (trackingNumber == _leftTrackingTag)
        _horizScrollFactor = -1;
    else if (trackingNumber == _topTrackingTag)
        _vertScrollFactor = +1;
    else if (trackingNumber == _rightTrackingTag)
        _horizScrollFactor = +1;
    else if (trackingNumber == _bottomTrackingTag)
        _vertScrollFactor = -1;
    else
        NSLog(@"Unknown trackingNumber %ld", (long)trackingNumber);
}

- (void)mouseDragged:(NSEvent *)theEvent {
	
}

- (void)mouseExited:(NSEvent *)theEvent {
	NSTrackingRectTag trackingNumber = [theEvent trackingNumber];

    if (trackingNumber == _leftTrackingTag
            || trackingNumber == _rightTrackingTag) {
        _horizScrollFactor = 0;
        if (_vertScrollFactor == 0)
            [self endFullscreenScrolling];
    } else {
        _vertScrollFactor = 0;
        if (_horizScrollFactor == 0)
            [self endFullscreenScrolling];
    }
}

- (void)setFrameBufferUpdateSeconds: (float)seconds
{
    // miniaturized windows should keep update seconds set at maximum
    if (![window isMiniaturized])
        [connection setFrameBufferUpdateSeconds:seconds];
}

- (void)endFullscreenScrolling {
	[_autoscrollTimer invalidate];
	[_autoscrollTimer release];
	_autoscrollTimer = nil;
}

/* Reconnection attempts */

- (void)createReconnectSheet:(id)sender
{
	__weak Session* weakSelf = self;
	
	[window beginSheet:_reconnectPanel completionHandler:^(NSModalResponse returnCode) {
		if (!weakSelf) {
			return;
		}
		
		Session* strongSelf = weakSelf;
		
		[strongSelf->_reconnectPanel orderOut:strongSelf];
	}];
	
    [_reconnectIndicator startAnimation:self];

    [_reconnectSheetTimer release];
    _reconnectSheetTimer = nil;
}

- (void)reconnectCancelled:(id)sender
{
    [_reconnectWaiter cancel];
    [_reconnectWaiter release];
    _reconnectWaiter = nil;
    [NSApp endSheet:_reconnectPanel];
    [self endSession];
}

- (void)connectionPrepareForSheet
{
    [NSApp endSheet:_reconnectPanel];
    [_reconnectSheetTimer invalidate];
    [_reconnectSheetTimer release];
    _reconnectSheetTimer = nil;
}

- (void)connectionSheetOver
{
    [self startTimerForReconnectSheet];
}

/* Reconnect attempt has failed */
- (void)connectionFailed
{
    [self endSession];
}

/* Reconnect attempt has succeeded */
- (void)connectionSucceeded:(RFBConnection *)newConnection
{
    [NSApp endSheet:_reconnectPanel];
    [_reconnectSheetTimer invalidate];
    [_reconnectSheetTimer release];
    _reconnectSheetTimer = nil;

//    if (_isFullscreen)
//        [self makeConnectionWindowed:self];

    connection = [newConnection retain];
    [connection setSession:self];
    [connection setRfbView:rfbView];
    [connection setPassword:password];
    [connection installMouseMovedTrackingRect];
    if (sshTunnel == nil)
        sshTunnel = [[connection sshTunnel] retain];

    [_connectionStartDate release];
    _connectionStartDate = [[NSDate alloc] init];

    [_reconnectWaiter release];
    _reconnectWaiter = nil;
}

- (IBAction)showProfileManager:(id)sender
{
    [[ProfileManager sharedManager] showWindowWithProfile:
        [[server_ profile] profileName]];
}

@end

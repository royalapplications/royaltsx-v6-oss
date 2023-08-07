#import "AppDelegate.h"

#import "SolidColorView.h"

@interface AppDelegate ()

@property (assign) IBOutlet NSWindow *windowFirst;
@property (assign) IBOutlet SolidColorView *placeholderViewFirstLeft;
@property (assign) IBOutlet SolidColorView *placeholderViewFirstRight;

@property (assign) IBOutlet NSWindow *windowSecond;
@property (assign) IBOutlet SolidColorView *placeholderViewSecondLeft;
@property (assign) IBOutlet SolidColorView *placeholderViewSecondRight;

@property (assign) IBOutlet NSWindow *windowThird;
@property (assign) IBOutlet SolidColorView *placeholderViewThirdLeft;
@property (assign) IBOutlet SolidColorView *placeholderViewThirdRight;

@property (assign) IBOutlet NSWindow *windowScreenshot;
@property (assign) IBOutlet NSImageView *imageViewScreenshot;

@property (strong) NSMutableArray *createdWindows;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    iTermLibController.sharedController.delegate = self;
    
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"FocusOnRightOrMiddleClick"]; // kPreferenceKeyFocusOnRightOrMiddleClick
    
    self.createdWindows = NSMutableArray.array;
    
    NSColor *colorLeftPlaceholder = NSColor.greenColor;
    NSColor *colorLeftTerminal = [colorLeftPlaceholder shadowWithLevel:0.9];
    
    NSColor *colorRightPlaceholder = NSColor.blueColor;
    NSColor *colorRightTerminal = [colorRightPlaceholder shadowWithLevel:0.9];
    
    self.placeholderViewFirstLeft.color = NSColor.clearColor;
    self.placeholderViewFirstRight.color = colorRightPlaceholder;
    
    self.placeholderViewSecondLeft.color = colorLeftPlaceholder;
    self.placeholderViewSecondRight.color = colorRightPlaceholder;
    
    self.placeholderViewThirdLeft.color = colorLeftPlaceholder;
    self.placeholderViewThirdRight.color = colorRightPlaceholder;
    
    iTermLibSessionController* firstSession = [self createSessionInParentView:self.placeholderViewFirstLeft withName:@"Session 01" andBackgroundColor:colorLeftTerminal transparency:0.5];
    [self createSessionInParentView:self.placeholderViewFirstRight withName:@"Session 02" andBackgroundColor:colorRightTerminal transparency:0];
    
    [self createSessionInParentView:self.placeholderViewSecondLeft withName:@"Session 03" andBackgroundColor:colorLeftTerminal transparency:0];
    [self createSessionInParentView:self.placeholderViewSecondRight withName:@"Session 04" andBackgroundColor:colorRightTerminal transparency:0];
    
    [self.windowThird makeKeyAndOrderFront:nil];
    [self.windowSecond makeKeyAndOrderFront:nil];
    [self.windowFirst makeKeyAndOrderFront:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [firstSession focus];
    });
}

- (iTermLibSessionController*)createSessionInParentView:(NSView*)parentView withName:(NSString*)name andBackgroundColor:(NSColor*)backgroundColor transparency:(float)transparency
{
    // Just to ensure we're seeing the black scrollback bug (see TextViewWrapper.m scrollViewDidScroll:)
    parentView.wantsLayer = YES;
    
    NSMutableDictionary* profileTemp = iTermLibSessionController.defaultProfile.mutableCopy;
    
    [profileTemp setObject:name forKey:KEY_NAME];
    
    // For testing logging:
    // [profileTemp setObject:@YES forKey:KEY_AUTOLOG];
    // [profileTemp setObject:@"/Users/fx/Downloads/iTermLogs" forKey:KEY_LOGDIR];
    
    [profileTemp setObject:[ITAddressBookMgr encodeColor:backgroundColor] forKey:KEY_BACKGROUND_COLOR];
    // iTermLib TODO: Will be required again when updating to a new iTerm release
    // [profileTemp setObject:@(iTermTitleComponentsSessionName | iTermTitleComponentsJob) forKey:KEY_TITLE_COMPONENTS];
    [profileTemp setObject:[NSNumber numberWithFloat:transparency] forKey:KEY_TRANSPARENCY];
    
    if (transparency > 0) {
        parentView.window.opaque = NO;
        
        // TODO: Seems like the only way to get transparency in a NSView at the moment is to set the window background color to clearColor
        // This however causes problems with ITPSMTabBarControl's rendering and likely other views
        // TODO: Is there no other way?!
        parentView.window.backgroundColor = NSColor.clearColor;
    }
    
    // For testing font ligatures:
    //[profileTemp setObject:@"JetBrainsMono-Regular 11" forKey:KEY_NORMAL_FONT];
    //[profileTemp setObject:@YES forKey:KEY_ASCII_LIGATURES];
    
    [profileTemp setObject:@YES forKey:KEY_SET_LOCALE_VARS];
    [profileTemp setObject:@YES forKey:KEY_UNLIMITED_SCROLLBACK];
//    [profileTemp setObject:@YES forKey:KEY_BLINKING_CURSOR];
    
    Profile* profile = profileTemp.copy;
    
    iTermLibSessionController* session = [iTermLibController.sharedController createSessionWithProfile:profile command:ITAddressBookMgr.standardLoginCommand initialSize:parentView.bounds.size];
    
    session.view.frame = NSMakeRect(0, 0, parentView.bounds.size.width, parentView.bounds.size.height);
    session.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable | NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin;
    
    [parentView addSubview:session.view];
    
    return session;
}

- (iTermLibSessionController*)createSessionInNewWindow
{
    // TODO: Sessions create via this method are never deallocated
    
    NSWindow* win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 700, 400) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable backing:NSBackingStoreBuffered defer:NO];
    
    win.tabbingMode = NSWindowTabbingModePreferred;
    
    [win center];
    
    NSString* name = [NSString stringWithFormat:@"Custom Session %lu", self.createdWindows.count + 1];
    
    iTermLibSessionController* session = [self createSessionInParentView:win.contentView withName:name andBackgroundColor:NSColor.blackColor transparency:0];
    
    [self.createdWindows addObject:win];
    
    win.title = name;
    
    [win makeKeyAndOrderFront:nil];
    
    [session focus];
    
    return session;
}




#pragma mark iTermLibControllerDelegate

- (void)controllerRequestsShowPreferences:(iTermLibController *)controller
{
    NSLog(@"Should show preferences");
}

- (void)controller:(iTermLibController *)controller shouldRemoveSessionView:(iTermLibSessionController *)session
{
    NSView* sessionView = session.view;
    [sessionView removeFromSuperview];
    
    NSLog(@"Session View was removed");
}

- (void)controller:(iTermLibController *)controller sessionDidClose:(iTermLibSessionController *)session
{
    NSLog(@"Session did Close");
}

- (void)controller:(iTermLibController *)controller nameOfSession:(iTermLibSessionController *)session didChangeTo:(NSString *)newName
{
    NSLog(@"Session name changed to '%@'", newName);
}




#pragma mark Menu Items

- (IBAction)newDocument:(id)sender
{
    [self createSessionInNewWindow];
}

- (IBAction)menuItemFakeInput_action:(id)sender
{
    iTermLibSessionController* session = iTermLibController.sharedController.activeSession;
    
    [session sendKeyCode:0 characters:@"a" modifierFlags:0 isDown:YES];
}

- (IBAction)menuItemShowFindPanel_action:(id)sender
{
    [iTermLibController.sharedController.activeSession showFindPanel];
}

- (IBAction)menuItemFindCursor_action:(id)sender
{
    [iTermLibController.sharedController.activeSession findCursor];
}

- (IBAction)menuItemHighlightCursorLine_action:(id)sender
{
    NSMenuItem *menuItem = sender;
    
    iTermLibSessionController* session = iTermLibController.sharedController.activeSession;
    
    session.highlightCursorLine = !session.highlightCursorLine;
    
    menuItem.state = session.highlightCursorLine ? NSControlStateValueOn : NSControlStateValueOff;
}

- (IBAction)menuItemShowTimestamps_action:(id)sender
{
    NSMenuItem *menuItem = sender;
    
    iTermLibSessionController* session = iTermLibController.sharedController.activeSession;
    
    session.showTimestamps = !session.showTimestamps;
    
    menuItem.state = session.showTimestamps ? NSControlStateValueOn : NSControlStateValueOff;
}

- (IBAction)menuItemBroadcastInput_action:(id)sender
{
    NSMenuItem *menuItem = sender;
    
    iTermLibController.sharedController.broadcasting = !iTermLibController.sharedController.broadcasting;
    
    menuItem.state = iTermLibController.sharedController.broadcasting ? NSControlStateValueOn : NSControlStateValueOff;
}

- (IBAction)menuItemPaste_action:(id)sender
{
    [iTermLibController.sharedController.activeSession paste];
}

- (IBAction)menuItemPasteSlowly_action:(id)sender
{
    [iTermLibController.sharedController.activeSession pasteSlowly];
}

- (IBAction)menuItemPasteEscapingSpecialCharacters_action:(id)sender
{
    [iTermLibController.sharedController.activeSession pasteEscapingSpecialCharacters];
}

- (IBAction)menuItemPasteAdvanced_action:(id)sender
{
    [iTermLibController.sharedController.activeSession pasteAdvanced];
}

- (IBAction)menuItemClearBuffer_action:(id)sender
{
    [iTermLibController.sharedController.activeSession clearBuffer];
}

- (IBAction)menuItemClearScrollbackBuffer_action:(id)sender
{
    [iTermLibController.sharedController.activeSession clearScrollbackBuffer];
}

- (IBAction)menuItemOpenAutocomplete_action:(id)sender
{
    [iTermLibController.sharedController.activeSession openAutocomplete];
}

- (IBAction)menuItemSetMark_action:(id)sender
{
    [iTermLibController.sharedController.activeSession setMark];
}

- (IBAction)menuItemJumpToMark_action:(id)sender
{
    [iTermLibController.sharedController.activeSession jumpToMark];
}

- (IBAction)menuItemJumpToNextMark_action:(id)sender
{
    [iTermLibController.sharedController.activeSession jumpToNextMark];
}

- (IBAction)menuItemJumpToPreviousMark_action:(id)sender
{
    [iTermLibController.sharedController.activeSession jumpToPreviousMark];
}

- (IBAction)menuItemJumpToSelection_action:(id)sender
{
    [iTermLibController.sharedController.activeSession jumpToSelection];
}

- (IBAction)menuItemToggleLogging_action:(id)sender
{
    iTermLibController.sharedController.activeSession.logging = !iTermLibController.sharedController.activeSession.logging;
}

- (IBAction)menuItemSelectAll_action:(id)sender
{
    [iTermLibController.sharedController.activeSession selectAll];
}

- (IBAction)menuItemSelectOutputOfLastCommand_action:(id)sender
{
    [iTermLibController.sharedController.activeSession selectOutputOfLastCommand];
}

- (IBAction)menuItemSelectCurrentCommand_action:(id)sender
{
    [iTermLibController.sharedController.activeSession selectCurrentCommand];
}

- (IBAction)menuItemMakeTextBigger_action:(id)sender
{
    [iTermLibController.sharedController.activeSession increaseFontSize];
}

- (IBAction)menuItemMakeTextNormalSize_action:(id)sender
{
    [iTermLibController.sharedController.activeSession restoreFontSize];
}

- (IBAction)menuItemMakeTextSmaller_action:(id)sender
{
    [iTermLibController.sharedController.activeSession decreaseFontSize];
}

- (IBAction)menuItemShowAnnotations_action:(id)sender
{
    [iTermLibController.sharedController.activeSession toggleShowAnnotations];
    
    NSMenuItem* menuItem = sender;
    
    menuItem.state = iTermLibController.sharedController.activeSession.showAnnotations ? NSControlStateValueOn : NSControlStateValueOff;
}

- (IBAction)menuItemAddAnnotationAtCursor_action:(id)sender
{
    [iTermLibController.sharedController.activeSession addAnnotationAtCursor];
}

- (IBAction)menuItemInstallShellIntegration_action:(id)sender
{
    [iTermLibController.sharedController.activeSession tryToRunShellIntegrationInstallerWithPromptCheck:NO];
}





- (IBAction)menuItemMoveTerminalsInFirstWindowToThirdWindow_action:(id)sender
{
    NSView* sessionViewFirstLeft = self.placeholderViewFirstLeft.subviews[0];
    NSView* sessionViewFirstRight = self.placeholderViewFirstRight.subviews[0];
    
    [sessionViewFirstLeft removeFromSuperview];
    
    [self.placeholderViewThirdLeft addSubview:sessionViewFirstLeft];
    sessionViewFirstLeft.frame = self.placeholderViewThirdLeft.bounds;
    
    [sessionViewFirstRight removeFromSuperview];
    
    [self.placeholderViewThirdRight addSubview:sessionViewFirstRight];
    sessionViewFirstRight.frame = self.placeholderViewThirdRight.bounds;
    
    [self.windowFirst close];
    
    [self.windowThird makeKeyAndOrderFront:self];
}

- (IBAction)menuItemTakeScreenshot_action:(id)sender
{
    NSImage* screenshot = iTermLibController.sharedController.activeSession.screenshot;
    
    if (screenshot) {
        [self.windowScreenshot makeKeyAndOrderFront:self];
        self.imageViewScreenshot.image = screenshot;
    }
}

@end

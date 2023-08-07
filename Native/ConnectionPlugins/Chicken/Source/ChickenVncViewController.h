//
//  ChickenVncViewController.h
//  Chicken
//
//  Created by Felix Deimel on 23.10.12.
//
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "RoyalTsxNativeConnectionControllerProtocol.h"
#import "ConnectionStatusArguments.h"
#import "ConnectionWaiter.h"
#import "SessionDelegate.h"
#import "LMPasteboardMonitor.h"

@class Session, ChickenVncOptions;

NSObject* getViewControllerForRoyalTsxPlugin(NSObject<RoyalTsxManagedConnectionControllerProtocol> *parentController, NSWindow *mainWindow);

@interface ChickenVncViewController : NSObject<ConnectionWaiterDelegate, SessionDelegate, RoyalTsxNativeConnectionControllerProtocol, LMPasteboardMonitorDelegate> {
    BOOL m_released;
    
    NSWindow *mainWindow;
    NSView *sessionView;
    Session *vncSession;
    ConnectionWaiter *waiter;
    
    NSObject<RoyalTsxManagedConnectionControllerProtocol> *parentController;
}

@property (nonatomic, retain) NSView *sessionView;
@property (nonatomic, retain) Session *vncSession;
@property (nonatomic, assign) NSObject *parentController;

@property (nonatomic, retain) LMPasteboardMonitor *pasteboardMonitor;

- (id<RoyalTsxNativeConnectionControllerProtocol>)initWithParentController:(NSObject<RoyalTsxManagedConnectionControllerProtocol>*)parent andMainWindow:(NSWindow*)window;

- (void)connectionStatusChanged:(rtsConnectionStatus)newStatus;
- (void)connectionStatusChanged:(rtsConnectionStatus)newStatus andMessage:(NSString*)message;
- (void)connectionStatusChanged:(rtsConnectionStatus)newStatus andMessage:(NSString*)message andErrorNumber:(int)errorNumber;
- (void)sessionResized;
- (void)connectWithOptions:(NSDictionary*)options;
- (void)disconnect;
- (void)focusSession;
- (void)refreshScreen;
- (NSImage*)getScreenshot;
- (void)sendKeys:(NSString*)keys;
- (void)sendKeyCode:(unsigned short)keyCode characters:(NSString*)characters down:(BOOL)down;
- (void)sendModifierFlags:(NSEventModifierFlags)modifierFlags;
- (void)pasteToServer;
- (void)sendPasteboardContentsToServer;
- (NSSize)contentSize;

- (NSArray*)performAppleRemoteDesktopAuthenticationWithPrime:(NSData*)prime
												   generator:(NSData*)generator
													 peerKey:(NSData*)peerKey
												   keyLength:(NSInteger)keyLength;

- (NSArray*)performUltraVNCMSLogonIIAuthenticationWithGenerator:(NSData*)generator
															mod:(NSData*)mod
														   resp:(NSData*)resp;

@end

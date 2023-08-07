#import <Cocoa/Cocoa.h>

#import "FxView.h"
#import "RoyalTsxManagedConnectionControllerProtocol.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, RoyalTsxManagedConnectionControllerProtocol> {
    IBOutlet NSWindow *window;
	IBOutlet NSTextField *textFieldHostname;
	IBOutlet NSTextField *textFieldPort;
	IBOutlet NSTextField *textFieldUsername;
	IBOutlet NSSecureTextField *textFieldPassword;
	IBOutlet FxView *viewSession;
	IBOutlet NSTextField *textFieldStatus;
	IBOutlet NSButton *checkBoxScaling;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *textFieldHostname;
@property (assign) IBOutlet NSTextField *textFieldPort;
@property (assign) IBOutlet NSTextField *textFieldUsername;
@property (assign) IBOutlet NSSecureTextField *textFieldPassword;
@property (assign) IBOutlet FxView *viewSession;
@property (assign) IBOutlet NSTextField *textFieldStatus;
@property (assign) IBOutlet NSButton *buttonConnect;
@property (assign) IBOutlet NSButton *checkBoxScaling;

- (IBAction)buttonConnect_Action:(id)sender;

@end

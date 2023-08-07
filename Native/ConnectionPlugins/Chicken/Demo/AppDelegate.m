#import "AppDelegate.h"
#import "ConnectionStatusArguments.h"
#import "ChickenVncViewController.h"

@interface AppDelegate ()

@property (copy) NSString* hostname;
@property NSInteger port;
@property (copy) NSString* username;
@property (copy) NSString* password;

@end

@implementation AppDelegate

@synthesize window;
@synthesize textFieldHostname;
@synthesize textFieldPort;
@synthesize textFieldUsername;
@synthesize textFieldPassword;
@synthesize viewSession;
@synthesize textFieldStatus;
@synthesize checkBoxScaling;

ChickenVncViewController *ctrl;
rtsConnectionStatus status;

- (void)dealloc {
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    status = rtsConnectionClosed;
	
	[self restoreDefaults];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self saveDefaults];
}

- (void)awakeFromNib {
    viewSession.delegate = self;
}

- (NSString*)hostname {
	return textFieldHostname.stringValue.copy;
}
- (void)setHostname:(NSString*)hostname {
	textFieldHostname.stringValue = hostname.copy;
}

- (NSInteger)port {
	return textFieldPort.integerValue;
}
- (void)setPort:(NSInteger)port {
	textFieldPort.integerValue = port;
}

- (NSString*)username {
	return textFieldUsername.stringValue.copy;
}
- (void)setUsername:(NSString*)username {
	textFieldUsername.stringValue = username.copy;
}

- (NSString*)password {
	return textFieldPassword.stringValue.copy;
}
- (void)setPassword:(NSString*)password {
	textFieldPassword.stringValue = password.copy;
}

- (BOOL)enableScaling {
	return checkBoxScaling.state == NSControlStateValueOn;
}
- (void)setEnableScaling:(BOOL)enableScaling {
	checkBoxScaling.state = enableScaling ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)saveDefaults {
	NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
	
	[defaults setObject:self.hostname forKey:@"Hostname"];
	[defaults setInteger:self.port forKey:@"Port"];
	[defaults setObject:self.username forKey:@"Username"];
	[defaults setObject:[[self.password dataUsingEncoding:NSUTF8StringEncoding] base64EncodedDataWithOptions:0] forKey:@"Password"];
	[defaults setBool:self.enableScaling forKey:@"Scaling"];
}

- (void)restoreDefaults {
	NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
	
	NSString* hostname = [defaults stringForKey:@"Hostname"];
	self.hostname = hostname != nil ? hostname : @"";
	
	NSNumber* portNumber = [defaults objectForKey:@"Port"];
	NSInteger port = 5900;
	
	if (portNumber) {
		port = portNumber.integerValue;
	}
	
	self.port = port;
	
	NSString* username = [defaults stringForKey:@"Username"];
	self.username = username != nil ? username : @"";
	
	NSData* passwordData = [defaults dataForKey:@"Password"];
	NSString* password = @"";
	
	if (passwordData) {
		NSData* decodedPasswordData = [[[NSData alloc] initWithBase64EncodedData:passwordData options:0] autorelease];
		
		if (decodedPasswordData) {
			password = [[[NSString alloc] initWithData:decodedPasswordData encoding:NSUTF8StringEncoding] autorelease];
		}
	}
	
	self.password = password != nil ? password : @"";
	
	NSNumber* scalingNumber = [defaults objectForKey:@"Scaling"];
	BOOL scaling = YES;
	
	if (scalingNumber) {
		scaling = scalingNumber.boolValue;
	}
	
	self.enableScaling = scaling;
}

- (IBAction)buttonConnect_Action:(id)sender {
    [self connectOrDisconnect];
}

- (void)connectOrDisconnect {
    if (!ctrl) {
        ctrl = (ChickenVncViewController*)getViewControllerForRoyalTsxPlugin(self, self.window);
    }
    
    if (status == rtsConnectionClosed) {
        [self connect];
    } else {
        [self disconnect];
    }
}

- (void)connect {
    NSMutableDictionary *opts = [NSMutableDictionary dictionary];
	
    opts[@"Hostname"] = self.hostname;
    opts[@"Port"] = [NSNumber numberWithInteger:self.port];
    opts[@"Password"] = self.password;
    opts[@"ViewOnly"] = [NSNumber numberWithBool:NO];
    opts[@"SharedConnection"] = [NSNumber numberWithBool:NO];
    opts[@"LimitTo256Colors"] = [NSNumber numberWithBool:NO];
    opts[@"EnableCopyRectEncoding"] = [NSNumber numberWithBool:NO];
    opts[@"EnableJpegEncoding"] = [NSNumber numberWithBool:NO];
    opts[@"SshTunnelEnabled"] = [NSNumber numberWithBool:NO];
    opts[@"SshTunnelHost"] = @"";
    opts[@"KeyboardMode"] = [NSNumber numberWithInt:1];
    opts[@"Scaling"] = [NSNumber numberWithBool:self.enableScaling];
    
    [ctrl connectWithOptions:[[opts copy] autorelease]];
}

- (void)disconnect {
    [ctrl disconnect];
}

- (void)sessionStatusChanged:(ConnectionStatusArguments*)args {
    status = args.status;
    
    if (status == rtsConnectionConnecting) {
        textFieldStatus.stringValue = @"Connecting";
		
        self.buttonConnect.enabled = NO;
    } else if (status == rtsConnectionConnected) {
        textFieldStatus.stringValue = @"Connected";
		
        self.buttonConnect.title = @"Disconnect";
        self.buttonConnect.enabled = YES;
        
        ctrl.sessionView.frame = self.viewSession.frame;
        ctrl.sessionView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable;
        
        //[ctrl.sessionView scaleUnitSquareToSize:NSMakeSize(0.5, 0.5)];
        
        [self.viewSession addSubview:ctrl.sessionView];
        
        /* [(NSScrollView*)ctrl.sessionView setHasHorizontalScroller:NO];
        [(NSScrollView*)ctrl.sessionView setHasVerticalScroller:NO]; */
        
        //[self.viewSession setBounds:NSMakeRect(0, 0, 500, 500)];
        
        [ctrl focusSession];
    } else if (status == rtsConnectionDisconnecting) {
        textFieldStatus.stringValue = @"Disconnecting";
		
        self.buttonConnect.enabled = NO;
    } else if (status == rtsConnectionClosed) {
        textFieldStatus.stringValue = @"Closed";
		
        self.buttonConnect.title = @"Connect";
        self.buttonConnect.enabled = YES;
		
		if (ctrl.sessionView) {
			[ctrl.sessionView removeFromSuperview];
			[ctrl.sessionView release];
		}
		
        [ctrl release]; ctrl = nil;
        
        NSAlert* alert = [[NSAlert new] autorelease];
        alert.messageText = @"Connection closed";
        alert.informativeText = [NSString stringWithFormat:@"%@", args.errorMessage];
        [alert addButtonWithTitle:@"OK"];
        
        [alert beginSheetModalForWindow:window completionHandler:nil];
    }
}

- (void)viewDidEndLiveResize {
    [self sessionResized];
}

- (void)sessionResized {
    /* NSScrollView* scrollView = (NSScrollView*)ctrl.sessionView;
    
    NSSize contentSize = [ctrl contentSize];
    NSSize containerSize = self.viewSession.frame.size;
    
    NSSize scale = NSMakeSize(containerSize.width / contentSize.width,
                              containerSize.height / contentSize.height);
    
    [scrollView scaleUnitSquareToSize:scale];
    [scrollView setNeedsDisplay:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setHasVerticalScroller:NO]; */
}

- (NSArray *)appleRemoteDesktopAuthenticationCredentials {
	return self.credentials;
}

- (NSArray *)ultraVNCMSLogonIIAuthenticationCredentials {
	return self.credentials;
}

- (NSArray *)credentials {
	NSString* username = self.username;
	NSString* password = self.password;
	
	if (!username ||
		!password) {
		return nil;
	}
	
	NSArray* result = @[
		username,
		password
	];
	
	return result;
}

@end

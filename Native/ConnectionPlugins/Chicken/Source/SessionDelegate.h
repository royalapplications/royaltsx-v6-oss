#ifndef SessionDelegate_h
#define SessionDelegate_h

@protocol SessionDelegate <NSObject>

- (void)serverClosedWithMessage:(NSString*)aMessage;
- (void)serverClosed;
- (void)authenticationFailed:(NSString*)aMessage;
- (void)sessionResized;

@end

#endif /* SessionDelegate_h */

// Caution: This file is linked in to FreeRDP and Chicken projects!

#import <Foundation/Foundation.h>

typedef enum _rtsConnectionStatus {
    rtsConnectionClosed = 0,
    rtsConnectionConnecting = 1,
    rtsConnectionConnected = 2,
    rtsConnectionDisconnecting = 3
} rtsConnectionStatus;

typedef enum _rtsConnectingSubStatus {
    rtsConnecting = 0,
    rtsPreConnectOpeningTunnel = 1,
    rtsPreConnectResolvingCredentials = 2
} rtsConnectingSubStatus;

@interface ConnectionStatusArguments : NSObject {
    rtsConnectionStatus status;
    NSInteger errorNumber;
    NSString *errorMessage;
}

@property (nonatomic, readwrite) rtsConnectionStatus status;
@property (nonatomic, readwrite) NSInteger errorNumber;
@property (nonatomic, copy) NSString *errorMessage;

+ (ConnectionStatusArguments*)argumentsWithStatus:(rtsConnectionStatus)aStatus;
+ (ConnectionStatusArguments*)argumentsWithStatus:(rtsConnectionStatus)aStatus andErrorNumber:(NSInteger)aErrorNumber;
+ (ConnectionStatusArguments*)argumentsWithStatus:(rtsConnectionStatus)aStatus errorNumber:(NSInteger)aErrorNumber andErrorMessage:(NSString*)aErrorMessage;

- (instancetype)init;
- (instancetype)initWithStatus:(rtsConnectionStatus)aStatus;
- (instancetype)initWithStatus:(rtsConnectionStatus)aStatus andErrorNumber:(NSInteger)aErrorNumber;
- (instancetype)initWithStatus:(rtsConnectionStatus)aStatus andErrorNumber:(NSInteger)aErrorNumber andErrorMessage:(NSString*)aErrorMessage;

@end

@interface ConnectingSubStatusArguments : NSObject {
    rtsConnectingSubStatus connectingSubStatus;
}

@property (nonatomic, readwrite) rtsConnectingSubStatus connectingSubStatus;

- (instancetype)init;
- (instancetype)initWithConnectingSubStatus:(rtsConnectingSubStatus)aStatus;

+ (instancetype)argumentsWithConnectingSubStatus:(rtsConnectingSubStatus)aStatus;

@end

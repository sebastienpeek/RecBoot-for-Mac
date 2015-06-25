//
//  RecBootAppDelegate.m
//  RecBoot
//
//  Created by Sebastien Peek on 23/12/10.
//  Copyright 2010 sebby.net. All rights reserved.
//

#import "RecBootAppDelegate.h"

static RecBootAppDelegate *classPointer;
struct am_device* device;
struct am_device_notification *notification;

void notification_callback(struct am_device_notification_callback_info *info, int cookie) {	
	if (info->msg == ADNCI_MSG_CONNECTED) {
		NSLog(@"Device connected.");
		device = info->dev;
		AMDeviceConnect(device);
		AMDeviceIsPaired(device);
		AMDeviceValidatePairing(device);
		AMDeviceStartSession(device);
		[classPointer populateData];
	} else if (info->msg == ADNCI_MSG_DISCONNECTED) {
		NSLog(@"Device disconnected.");
		[classPointer dePopulateData];
	} else {
		NSLog(@"Received device notification: %d", info->msg);
	}
}

void recovery_connect_callback(struct am_recovery_device *rdev) {
	[classPointer recoveryCallback];
}

void recovery_disconnect_callback(struct am_recovery_device *rdev) {
	[classPointer dePopulateData];
}

@interface RecBootAppDelegate ()

@property (nonatomic, strong) IBOutlet NSButton *exitRecButton;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *loadingIndicator;

@property (nonatomic, strong) IBOutlet NSTextField *connectedDeviceLbl;
@property (nonatomic, strong) IBOutlet NSTextField *deviceNameLbl;
@property (nonatomic, strong) IBOutlet NSTextField *deviceModelLbl;
@property (nonatomic, strong) IBOutlet NSTextField *deviceFirmwareLbl;
@property (nonatomic, strong) IBOutlet NSTextField *deviceSerialLbl;

@property BOOL recoveryDeviceIsConnected;

- (void)loadingProgress;
- (void)enterRecovery;
- (NSString *)getDeviceValue:(NSString *)value;

@end

@implementation RecBootAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	classPointer = self;
	AMDeviceNotificationSubscribe(notification_callback, 0, 0, 0, &notification);
	AMRestoreRegisterForDeviceNotifications(recovery_disconnect_callback, recovery_connect_callback, recovery_disconnect_callback, recovery_disconnect_callback, 0, NULL);
	
    if (self.recoveryDeviceIsConnected) {
        [self.exitRecButton setEnabled:YES];
    } else {
        [self.exitRecButton setEnabled:NO];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (IBAction)enterRec:(id)pId {
	[self enterRecovery];
	[self dePopulateData];
	[self loadingProgress];
}

- (void)enterRecovery {
	AMDeviceConnect(device);
	AMDeviceEnterRecovery(device);
}

- (IBAction)exitRec:(id)pId {
    
    self.recoveryDeviceIsConnected = NO;
	
	[self loadingProgress];
	//Allow the user to exit recovery mode through the application.
	
	//Makes recoverset the NSTask to be used.
	NSTask *recoverset = [[NSTask alloc] init];
	
	//Sets launch path.
	[recoverset setLaunchPath: [[NSBundle mainBundle] pathForResource:@"irecovery" ofType:nil]];
	//Sends the following command to irecovery.
	[recoverset setArguments:[NSArray arrayWithObjects:@"-c", @"setenv auto-boot true",nil]];
	[recoverset launch];
	[recoverset waitUntilExit];
	
	//Makes recoversave the NSTask to be used.
	NSTask *recoversave = [[NSTask alloc] init];
	//Sets launch path.
	[recoversave setLaunchPath: [[NSBundle mainBundle] pathForResource:@"irecovery" ofType:nil]];
	//Sends the following command to irecovery.
	[recoversave setArguments:[NSArray arrayWithObjects:@"-c", @"saveenv",nil]];
	[recoversave launch];
	[recoversave waitUntilExit];
	
	//Makes recoverreboot the NSTask to be used.
	NSTask *recoverreboot = [[NSTask alloc] init];
	//Sets launch path.
	[recoverreboot setLaunchPath: [[NSBundle mainBundle] pathForResource:@"irecovery" ofType:nil]];
	//Sends the following command to irecovery.
	[recoverreboot setArguments:[NSArray arrayWithObjects:@"-c", @"reboot",nil]];
	[recoverreboot launch];
}

- (void)recoveryCallback {
	[self.connectedDeviceLbl setStringValue:@"Recovery Device Connected"];
    self.recoveryDeviceIsConnected = YES;

    [self.exitRecButton setEnabled:YES];
	[self.loadingIndicator setHidden:YES];
    
    [self.deviceNameLbl setHidden:YES];
    [self.deviceModelLbl setHidden:YES];
    [self.deviceFirmwareLbl setHidden:YES];
    [self.deviceSerialLbl setHidden:YES];
    
}

- (void)populateData {
    
    if (!self.recoveryDeviceIsConnected) {
        
        [self.loadingIndicator setHidden:YES];
    
        [self.deviceNameLbl setHidden:NO];
        [self.deviceModelLbl setHidden:NO];
        [self.deviceFirmwareLbl setHidden:NO];
        [self.deviceSerialLbl setHidden:NO];
        
        [self.connectedDeviceLbl setStringValue:@"Device Connected"];
    
        [self.deviceNameLbl setStringValue:[self getDeviceValue:@"DeviceName"]];
        [self.deviceModelLbl setStringValue:[self getDeviceValue:@"ProductType"]];
        [self.deviceFirmwareLbl setStringValue:[NSString stringWithFormat:@"iOS%@", [self getDeviceValue:@"ProductVersion"]]];
        [self.deviceSerialLbl setStringValue:[self getDeviceValue:@"SerialNumber"]];
        
    }
    
}

- (void)dePopulateData {
	[self.connectedDeviceLbl setStringValue:@""];
	[self.exitRecButton setEnabled:NO];
}

- (void)loadingProgress {
	[self.loadingIndicator setHidden:NO];
	[self.loadingIndicator startAnimation: self];
}

- (NSString *)getDeviceValue:(NSString *)value {
	return (NSString *)AMDeviceCopyValue(device, 0, (CFStringRef)value);
}

@end

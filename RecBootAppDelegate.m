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
		AMDevicePair(device);
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

@implementation RecBootAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	classPointer = self;
	AMDeviceNotificationSubscribe(notification_callback, 0, 0, 0, &notification);
	AMRestoreRegisterForDeviceNotifications(recovery_disconnect_callback, recovery_connect_callback, recovery_disconnect_callback, recovery_disconnect_callback, 0, NULL);
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (IBAction)enterRec:(id)pId {
	AMDeviceConnect(device);
	AMDeviceEnterRecovery(device);
	[classPointer dePopulateData];
}

- (IBAction)exitRec:(id)pId {
	
	NSString *foundValue = [deviceDetails stringValue];
	
	if ([foundValue isEqualToString:@"Recovery Device Connected"]) {
	
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
	
	else {
		
		//Probably should find a way to make this more user friendly and display that it won't work...
		//Or maybe people should actually check it out first, then they'd know...
		NSLog(@"Man, why can't people actually read if their device is in recovery mode or not?");
	}

}

- (void)recoveryCallback {
	[deviceDetails setStringValue:@"Recovery Device Connected"];
}

- (void)populateData {
	NSString *serialNumber = [self getDeviceValue:@"SerialNumber"];
	NSString *modelNumber = [self getDeviceValue:@"ModelNumber"];
	NSString *deviceString = [self getDeviceValue:@"ProductType"];
	NSString *firmwareVersion = [self getDeviceValue:@"ProductVersion"];
	
	if ([deviceString isEqualToString:@"iPod1,1"]) {
		deviceString = @"iPod Touch 1G";
	} else if ([deviceString isEqualToString:@"iPod2,1"]) {
		deviceString = @"iPod Touch 2G";
	} else if ([deviceString isEqualToString:@"iPod3,1"]) {
		deviceString = @"iPod Touch 3G";
	} else if ([deviceString isEqualToString:@"iPhone1,1"]) {
		deviceString = @"iPhone 2G";
	} else if ([deviceString isEqualToString:@"iPhone1,2"]) {
		deviceString = @"iPhone 3G";
	} else if ([deviceString isEqualToString:@"iPhone2,1"]) {
		deviceString = @"iPhone 3G[S]";
	} else if ([deviceString isEqualToString:@"iPhone3,1"]) {
		deviceString = @"iPhone 4";
	} else if ([deviceString isEqualToString:@"iPad1,1"]) {
		deviceString = @"iPad 1G";
	} else {
		deviceString = @"Unknown";
	}
	
	if (deviceString == @"Unknown") {
		NSString *completeString = [NSString stringWithFormat:@"%@ Mode/Device Detected",deviceString];
		[deviceDetails setStringValue:completeString];
	} else {
		NSString *completeString = [NSString stringWithFormat:@"%@ Connected, %@, %@, %@", deviceString, modelNumber, firmwareVersion, serialNumber];
		[deviceDetails setStringValue:completeString];
	}
	
}

- (void)dePopulateData {
	[deviceDetails setStringValue:@""];
	
}

- (NSString *)getDeviceValue:(NSString *)value {
	return AMDeviceCopyValue(device, 0, value);
}

@end

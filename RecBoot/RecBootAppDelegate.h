//
//  RecBootAppDelegate.h
//  RecBoot
//
//  Created by Sebastien Peek on 23/12/10.
//  Copyright 2010 sebby.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MobileDevice.h"

@interface RecBootAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) IBOutlet NSWindow *window;

- (void)populateData;
- (void)dePopulateData;
- (void)recoveryCallback;

@end

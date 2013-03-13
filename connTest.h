//
//  connTest.h
//  SimpleSSHProxy_beta1
//
//  Created by ivan on 11-5-14.
//  Copyright 2011 ivansays.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Cocoa/Cocoa.h>
@class AsyncSocket;  //AsyncSocket类前向引用声明

@interface connTest : NSObject {
	BOOL connTestIsRunning;
	id delegate;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (void) initConnTest;
- (void) stopConnTest;

@end

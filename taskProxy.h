//
//  taskProxy.h
//  SimpleSSHProxy_beta1
//
//  Created by ivan on 11-5-30.
//  Copyright 2011 ivansays.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface taskProxy : NSObject {
	NSArray * taskArguments;
	NSTask * taskSSH;
	NSTask * taskPolipo;
}
@property (readwrite, assign) NSArray * taskArguments;

- (void) taskStart;
- (void) taskStop;

@end

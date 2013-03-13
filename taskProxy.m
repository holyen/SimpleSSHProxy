//
//  taskProxy.m
//  SimpleSSHProxy_beta1
//
//  Created by ivan on 11-5-30.
//  Copyright 2011 ivansays.com. All rights reserved.
//

#import "taskProxy.h"
@interface taskProxy (PrivateAPI)
- (void) getTaskArgs;
- (void) launchTaskSSH;
- (void) launchTaskPolipo;
@end

@implementation taskProxy

int allowAllAccess, localSocksPort, localHTTPPort, sshPort, usePasswordFlag;
NSString * sshServer;
NSString * sshUsername;
NSString * sshPassword;

@synthesize taskArguments;

- (void) taskStart
{
	[self getTaskArgs];
	if (![taskSSH isRunning]) {
		[self launchTaskSSH];
	}
	if (![taskPolipo isRunning]) {
		[self launchTaskPolipo];
	}
}

- (void) taskStop
{
	if ([taskSSH isRunning])
	{
		[taskSSH terminate];
		[taskSSH waitUntilExit];
	}
	if ([taskPolipo isRunning]) {
		[taskPolipo terminate];
		[taskPolipo waitUntilExit];
	}
}

- (void) getTaskArgs
{
	id checkboxAllowAllAccess, fieldLocalSocksPort, fieldLocalHTTPPort, fieldSSHServer,
	fieldSSHPort, fieldSSHUsername, checkboxUsePassword, fieldSSHPassword;
	
	checkboxAllowAllAccess = [taskArguments objectAtIndex:0];
	fieldLocalSocksPort = [taskArguments objectAtIndex:1];
	fieldLocalHTTPPort = [taskArguments objectAtIndex:2];
	fieldSSHServer = [taskArguments objectAtIndex:3];
	fieldSSHPort = [taskArguments objectAtIndex:4];
	fieldSSHUsername = [taskArguments objectAtIndex:5];
	checkboxUsePassword = [taskArguments objectAtIndex:6];
	fieldSSHPassword = [taskArguments objectAtIndex:7];
	
	allowAllAccess = [checkboxAllowAllAccess state];
	localSocksPort = [fieldLocalSocksPort intValue];
	localHTTPPort = [fieldLocalHTTPPort intValue];
	sshPort = [fieldSSHPort intValue];
	usePasswordFlag = [checkboxUsePassword state];
	sshServer = [fieldSSHServer stringValue];
	sshUsername = [ fieldSSHUsername stringValue];
	sshPassword = [ fieldSSHPassword stringValue];
	//NSLog(@"%@, %@, %@ \n", sshServer, sshUsername, sshPassword);
	
}

- (void) launchTaskSSH
{
	//NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"taskSSH alloc");
	taskSSH = [[NSTask alloc] init];
	[taskSSH setLaunchPath:@"/usr/bin/ssh"];
	NSMutableDictionary * sshEnvironment = [NSMutableDictionary dictionaryWithDictionary:
											[[NSProcessInfo processInfo] environment]];
	//remove ssh-agent support
	[sshEnvironment removeObjectForKey:@"SSH_AGENT_PID"];
	[sshEnvironment removeObjectForKey:@"SSH_AUTH_SOCK"];
	if (usePasswordFlag) {
		//set up $SSH_ASKPASS and $DISPLAY, see getPass.sh for more information
		[sshEnvironment setObject: [[NSBundle mainBundle] pathForResource:@"getPass" ofType:@"sh"] forKey:@"SSH_ASKPASS"];
		[sshEnvironment setObject:@":0" forKey:@"DISPLAY"];
		[sshEnvironment setObject:sshPassword forKey: @"PASS"];
	}
	[taskSSH setEnvironment:sshEnvironment];
	//set up ssh arguments
	NSMutableArray *sshArgs = [NSMutableArray arrayWithObjects:@"-N",@"-L",@"20010:127.0.0.1:20010",
							   @"-R",@"20010:127.0.0.1:20011",@"-D",nil];
	if (allowAllAccess) {
		[sshArgs addObject:[NSString stringWithFormat:@"0.0.0.0:%d",localSocksPort]];
	}
	else {
		[sshArgs addObject:[NSString stringWithFormat:@"127.0.0.1:%d",localSocksPort]];
	}
	[sshArgs addObject:@"-p"];
	[sshArgs addObject:[NSString stringWithFormat:@"%d",sshPort]];  //ssh port
	[sshArgs addObject:@"-l"];
	[sshArgs addObject:sshUsername];
	[sshArgs addObject:sshServer];
	//automaticlly add unknown/new host to ~/.ssh/known_hosts
	[sshArgs addObject:@"-o"];
	[sshArgs addObject:@"StrictHostKeyChecking=no"];
	[taskSSH setArguments:sshArgs];
	[taskSSH launch];
	//[pool drain];
}

- (void) launchTaskPolipo
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"taskPolipo alloc");
	taskPolipo = [[NSTask alloc] init];
	NSString *resourcePathString = [[NSBundle mainBundle] resourcePath];
	[taskPolipo setLaunchPath:[resourcePathString stringByAppendingPathComponent:@"polipo"]];
	//set polipo arguments
	NSMutableArray *polipoArgs = [NSMutableArray arrayWithObjects:@"proxyName=\"polipo\"", nil];
	[polipoArgs addObject:[NSString stringWithFormat:@"proxyPort=%d",localHTTPPort]];
	[polipoArgs addObject:[NSString stringWithFormat:@"socksParentProxy=127.0.0.1:%d",localSocksPort]];
	if (allowAllAccess) {
		[polipoArgs addObject:@"proxyAddress=0.0.0.0"];
	}
	[taskPolipo setArguments:polipoArgs];
	[taskPolipo launch];
	[pool drain];
}

- (void) dealloc
{
	NSLog(@"taskProxy dealloc is called");
	[taskPolipo release];
	[taskSSH release];
	[super dealloc];
}

@end
//
//  AppController.m
//  SimpleSSHProxy_beta1
//
//  Created by ivan on 11-5-30.
//  Copyright 2011 ivansays.com. All rights reserved.
//

#import "AppController.h"

@interface AppController (PrivateAPI)
- (void) loadLocalizedData;
- (void) showMenuIcon;
- (void) setupPasswordInKeychain;
- (void) setupConnTestStatus;

@end

@implementation AppController


NSStatusItem * statusItem;
EMGenericKeychainItem * keychainItem;
NSUserDefaults * sspDefaults;
taskProxy * myTaskProxy;
connTest * myConnTest;
BOOL taskProxyIsRunning = NO;

NSThread * connTestThread;

- (void) awakeFromNib
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	myTaskProxy = nil;
	myConnTest = nil;
	[self loadLocalizedData];
	sspDefaults = [NSUserDefaults standardUserDefaults];
	[self showMenuIcon];  //显示状态菜单图标
	[preferenceWindow setLevel: NSStatusWindowLevel];  //设置偏好设置窗口等级
	[preferenceWindow setDelegate:self];
	int port = [sspDefaults integerForKey:@"localSocksPort"];
	if (port != 0)
    {	//偏好设置存在
		[self setupPasswordInKeychain];
		[self setupConnTestStatus];
    }
    else
    {	/* 没有偏好设置（第一次运行） */
        /* 设置偏好默认值 */
        [sspDefaults setInteger: 8580 forKey: @"localSocksPort"];
		[sspDefaults setInteger: 8118 forKey: @"localHTTPPort"];
		[sspDefaults setInteger: 22 forKey: @"SSHPort"];
		[self setupPasswordInKeychain];
		[self setupConnTestStatus];
		[self showPreferences:nil];
    }
	/* 更新文本框的可编辑状态 */
	[self checkboxUsePasswordChanged: nil];
	/* 检查是否自动开始连接 */
	if ([checkboxAutoStart state] == NSOnState ) {
		[self startProxy:nil];
	}
	[pool drain];
}

- (void) loadLocalizedData  //载入本地化数据
{
	[preferenceWindow setTitle:NSLocalizedString(@"preferenceWindowTitle", )];
	[tabGeneral setLabel:NSLocalizedString(@"tabGeneral", )];
	[tabSSH setLabel:NSLocalizedString(@"tabSSH", )];
	[tabAdvanced setLabel:NSLocalizedString(@"tabAdvanced", )];

	[menuItemAboutSSP setTitle:NSLocalizedString(@"menuItemAboutSSP", )];
	[menuItemShowPref setTitle:NSLocalizedString(@"menuItemShowPref", )];
	[menuItemProxyStart setTitle:NSLocalizedString(@"menuItemProxyStart", )];
	[menuItemProxyStop setTitle:NSLocalizedString(@"menuItemProxyStop", )];
	[menuItemProxyRestart setTitle:NSLocalizedString(@"menuItemProxyRestart", )];
	[menuItemExitSSP setTitle:NSLocalizedString(@"menuItemExitSSP", )];

	[labelOnAppStart setStringValue:NSLocalizedString(@"labelOnAppStart", )];
	[checkboxAutoStart setTitle:NSLocalizedString(@"checkboxAutoStart", )];
	[labelProxyFor setStringValue:NSLocalizedString(@"labelProxyFor", )];
	[checkboxAllowAllAccess setTitle:NSLocalizedString(@"checkboxAllowAllAccess", )];
	[labelProxyListeningPorts setStringValue:NSLocalizedString(@"labelProxyListeningPorts", )];
	[labelSocksPort setStringValue:NSLocalizedString(@"labelSocksPort", )];
	[labelHTTPPort setStringValue:NSLocalizedString(@"labelHTTPPort", )];
	
	[labelSSHServer setStringValue:NSLocalizedString(@"labelSSHServer", )];
	[labelSSHPort setStringValue:NSLocalizedString(@"labelSSHPort", )];
	[labelSSHUsername setStringValue:NSLocalizedString(@"labelSSHUsername", )];
	[checkboxUsePassword setTitle:NSLocalizedString(@"checkboxUsePassword", )];
	[checkboxUseConnTest setTitle:NSLocalizedString(@"checkboxUseConnTest", )];
	[labelUseConnTest setStringValue:NSLocalizedString(@"labelUseConnTest", )];
}	

- (void) showMenuIcon
{
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:
				   NSVariableStatusItemLength] retain];
	//	[statusItem setImage:[NSImage imageNamed:@"StatusIconRed"]];
	[statusItem setHighlightMode:YES];
	[statusItem setTitle:@"N"];
	[statusItem setEnabled:YES];
	[statusItem setToolTip:@""];
	[statusItem setMenu:menuStatusBar];
}

- (void) showAboutPanel: (id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:sender];
	
}

- (IBAction) showPreferences: (id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[preferenceWindow makeKeyAndOrderFront:self];
}

- (IBAction) startProxy: (id)sender
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	if (!taskProxyIsRunning) {
		NSArray * taskArgs = [NSArray arrayWithObjects:checkboxAllowAllAccess,
							  fieldLocalSocksPort,
							  fieldLocalHTTPPort,
							  fieldSSHServer,
							  fieldSSHPort,
							  fieldSSHUsername,
							  checkboxUsePassword,
							  fieldSSHPassword,
							  nil];
		if (myTaskProxy == nil) {
			myTaskProxy = [[taskProxy alloc] init];  //实例化myTaskProxy
		}
		[myTaskProxy setTaskArguments:taskArgs];
		[myTaskProxy taskStart];
		[statusItem setTitle:@"Y"];
		taskProxyIsRunning = YES;
		if ([checkboxUseConnTest state] == NSOnState) {
			// use connTest
			NSLog(@"init myConnTest...");
			if (myConnTest==nil) {
				myConnTest=[[connTest alloc] init];
				[myConnTest setDelegate:self];
			}
			NSLog(@"myConnTest... inited.");
			if (connTestThread==nil) {
				connTestThread = [[NSThread alloc] initWithTarget:myConnTest selector:@selector(initConnTest) object:nil];
				[connTestThread start];
			}
		}
	}
	[pool drain];
}

- (IBAction) stopProxy: (id)sender
{
	if (taskProxyIsRunning) {
		[myTaskProxy taskStop];
		[statusItem setTitle:@"N"];
		taskProxyIsRunning = NO;
		if (connTestThread!=nil) {
			// stop and release connTest
			NSLog(@"releasing myConnTest...");
			[myConnTest performSelector:@selector(stopConnTest) onThread:connTestThread withObject:nil waitUntilDone:NO];
			[myConnTest release];
			[connTestThread release];
			myConnTest=nil;
			connTestThread=nil;
			NSLog(@"myConnTest released.");
		}
	}
}

- (IBAction) restartProxy: (id)sender
{
	NSLog(@"restarting proxy...");
	[self stopProxy:nil];
	[self startProxy:nil];
}

- (IBAction) quitSimpleSSHProxy: (id)sender
{
	[self stopProxy:nil];
	if (myTaskProxy!=nil) {
		[myTaskProxy release];
	}
	keychainItem.password = [fieldSSHPassword stringValue];
	[sspDefaults synchronize];  //退出时保存数据
	[sspDefaults release];
	[keychainItem release];
	[statusItem release];
	[NSApp terminate:nil];
}

- (IBAction) checkboxUsePasswordChanged: (id)sender
{
	if ([checkboxUsePassword state] == NSOnState) 
	{ [fieldSSHPassword setEnabled:YES]; }
	else 
	{ [fieldSSHPassword setEnabled:NO]; }
}

- (BOOL) windowShouldClose: (id)sender  //偏好设置窗口委托方法
{
	keychainItem.password = [fieldSSHPassword stringValue];
	[sspDefaults synchronize];  //关闭窗口时保存数据
	return YES;
}

- (void) setupPasswordInKeychain
{
	if ([sspDefaults objectForKey:@"password"]!=nil) { // 如果配置文件中有以前保存的明文密码
		if ([EMGenericKeychainItem genericKeychainItemForService:@"SimpleSSHProxy"
													withUsername:@"SimpleSSHProxy" ] == nil) {
			//如果keychain中没有SimpleSSHProxy项，则新建项，将密码保存在keychain中
			[EMGenericKeychainItem addGenericKeychainItemForService:@"SimpleSSHProxy"
													   withUsername:@"SimpleSSHProxy"
														   password:[sspDefaults valueForKey:@"password"]];
			//将keychainItem指向SimpleSSHProxy的项
			keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"SimpleSSHProxy"
																   withUsername:@"SimpleSSHProxy" ];
		} else {  //如果keychain中已有SimpleSSHProxy项，更改之
			keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"SimpleSSHProxy"
																   withUsername:@"SimpleSSHProxy" ];
			keychainItem.password = [sspDefaults valueForKey:@"password"];
		}
		[sspDefaults removeObjectForKey:@"password"];  //删除明文保存的密码
	} else {  //配置文件中没有明文保存密码
		if ([EMGenericKeychainItem genericKeychainItemForService:@"SimpleSSHProxy"
													withUsername:@"SimpleSSHProxy" ] == nil) {
			//keychain中也没有保存密码
			[EMGenericKeychainItem addGenericKeychainItemForService:@"SimpleSSHProxy"
													   withUsername:@"SimpleSSHProxy"
														   password:[NSString string]];
		}
		keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"SimpleSSHProxy"
															   withUsername:@"SimpleSSHProxy" ];
	}
	[keychainItem retain];
	[fieldSSHPassword setStringValue:(keychainItem.password)];
}

- (void) setupConnTestStatus
{
	if ([sspDefaults objectForKey:@"useConnTest"]==nil) {
		// if this key doesn't exist
		[sspDefaults setBool:TRUE forKey:@"useConnTest"];
	}
}
@end
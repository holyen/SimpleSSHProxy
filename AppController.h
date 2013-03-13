//
//  AppController.h
//  SimpleSSHProxy_beta1
//
//  Created by ivan on 11-5-30.
//  Copyright 2011 ivansays.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EMKeychainItem.h"
#import "taskProxy.h"
#import "connTest.h"

@interface AppController : NSObject {

	IBOutlet id menuStatusBar;  //状态菜单
	IBOutlet id preferenceWindow;  //偏好设置窗口
	
	IBOutlet id menuItemAboutSSP;  //菜单项
	//-----------------------------
	IBOutlet id menuItemShowPref;
	//-----------------------------
	IBOutlet id menuItemProxyStart;
	IBOutlet id menuItemProxyStop;
	IBOutlet id menuItemProxyRestart;
	//-----------------------------
	IBOutlet id menuItemExitSSP;
	
	IBOutlet id tabGeneral;  //偏好设置窗口的3个tab
	IBOutlet id tabSSH;
	IBOutlet id tabAdvanced;
	
	IBOutlet id labelOnAppStart;
	IBOutlet id checkboxAutoStart;
	//-----------------------------
	IBOutlet id labelProxyFor;
	IBOutlet id checkboxAllowAllAccess;
	//-----------------------------
	IBOutlet id labelProxyListeningPorts;
	IBOutlet id labelSocksPort;
	IBOutlet id labelHTTPPort;
	IBOutlet id fieldLocalSocksPort;
	IBOutlet id fieldLocalHTTPPort;
	//-----------------------------
	IBOutlet id labelSSHServer;
	IBOutlet id fieldSSHServer;
	//-----------------------------
	IBOutlet id labelSSHPort;
	IBOutlet id fieldSSHPort;
	//-----------------------------
	IBOutlet id labelSSHUsername;
	IBOutlet id fieldSSHUsername;
	//-----------------------------
	IBOutlet id checkboxUsePassword;
	IBOutlet id fieldSSHPassword;
	//-----------------------------
	IBOutlet id checkboxUseConnTest;
	IBOutlet id labelUseConnTest;
}

- (void) awakeFromNib;

- (IBAction) showAboutPanel: (id)sender;
- (IBAction) showPreferences: (id)sender;
- (IBAction) startProxy: (id)sender;
- (IBAction) stopProxy: (id)sender;
- (IBAction) restartProxy: (id)sender;
- (IBAction) quitSimpleSSHProxy: (id)sender;
- (IBAction) checkboxUsePasswordChanged: (id)sender;

@end

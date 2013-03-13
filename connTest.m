//
//  connTest.m
//  SimpleSSHProxy_beta1
//
//  Created by ivan on 11-5-13.
//  Copyright 2011 ivansays.com. All rights reserved.
//

//  ssh -L 20010:127.0.0.1:20010 -R 20010:127.0.0.1:20011 建立测试回路，向20010端口写数据，检测20011端口输出

#import "connTest.h"
#import "AsyncSocket.h"
#define TIME_INTERVAL 4
#define TEST_TIMEOUT 2

@interface connTest (PrivateAPI)  //私有方法声明
- (void) initSockets;
- (void) releaseSockets;
@end

@implementation connTest

NSRunLoop * myRunloop;
AsyncSocket *listenSocket;
AsyncSocket *writeSocket;

NSTimer * timerWithInt;
BOOL connIsAlive=NO;  //全局变量
BOOL connTestNeedsInit=YES;

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

- (void) initConnTest
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"Init NSTimer...");
	connTestNeedsInit=YES;
	timerWithInt = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL
													target: self
												  selector: @selector(timerTimeout:)
												  userInfo: nil
												   repeats: YES];  //初始化一个间隔n秒的计时器
	[timerWithInt retain];
	NSLog(@"NSTimer inited.");
	myRunloop = [NSRunLoop currentRunLoop];
	[myRunloop retain];
	[myRunloop run];
	[pool drain];
}

- (void) initAll
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"Init connection test... (sockets)");
	listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	[listenSocket acceptOnPort:20011 error:nil];  //初始化监听sock，设置运行循环，设置监听端口20011
	NSLog(@"Listening...");
	writeSocket = [[AsyncSocket alloc] initWithDelegate:self];  //初始化写sock
	[writeSocket connectToHost:@"127.0.0.1" onPort:20010 error:nil];  //连接20010端口，准备写数据
	connTestIsRunning=YES;
	NSLog(@"Sockets inited.");
	[pool drain];
}

- (void) releaseSockets
{
	if(!connTestNeedsInit) {
		NSLog(@"Releasing sockets...");
		[listenSocket setDelegate:nil];
		[listenSocket disconnect];
		[listenSocket release];
		[writeSocket setDelegate:nil];
		[writeSocket disconnect];
		[writeSocket release];
		connTestIsRunning=NO;
		NSLog(@"Sockets released.");
	}
}

//写sock连接远程端口成功 或 监听端口已连接
- (void) onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{	
	if ([sock connectedPort] == 20010) { //连接本地20010端口成功
		NSLog(@"Connected to write...");
	} else {  //本地监听端口已连接
		[sock readDataToData:[AsyncSocket LFData] withTimeout:100 tag:0];  //开始读取LF格式数据
		NSLog(@"Port 20011 connected with remote port %d", port);
	}
}

//监听端口读取数据完成
- (void) onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 1)];
	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"-(%@)Ahh!",msg);
	connIsAlive = YES;  //连接正常
	[sock readDataToData:[AsyncSocket LFData] withTimeout:100 tag:0];  //开始读取LF格式数据
	[pool drain];
}

//写sock端口完成
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:tag
{
	NSLog(@"Write done!");
	//[writeSocket disconnect];  //关闭sock
}

- (BOOL)testConnection
{
	NSLog(@"Awake now");
	if (connIsAlive) {
		NSLog(@"Connection is good!");
	} else {
		NSLog(@"Connection losted!");
		[self releaseSockets];
		NSLog(@"All conncections closed");
		NSLog(@"Restarting ssh...");
		[delegate performSelectorOnMainThread:@selector(restartProxy:) withObject:self waitUntilDone:NO];
		connTestNeedsInit=YES;
	}
	return connIsAlive;
}

- (void) timerTimeout: (NSTimer *) timer
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"=============Tick!=============");
	if (connTestNeedsInit) {
		[self initAll];
		connTestNeedsInit=NO;
	}
	connIsAlive = NO;  //暂时设置为NO
	NSString *myMsg = @"Paa!\n";
	NSData *myMsgData = [myMsg dataUsingEncoding:NSUTF8StringEncoding];
	if (writeSocket==nil) {
		NSLog(@"Nothing to do with write...");
	} else {
		[writeSocket writeData:myMsgData withTimeout:TIME_INTERVAL tag:0];  //向端口写数据
	}
	NSLog(@"Sleeping...");
	[self performSelector:@selector(testConnection) withObject:nil afterDelay:TEST_TIMEOUT];  //n秒后检测连接状态
	[pool drain];
}

- (void) stopConnTest
{
	[self setDelegate:nil];
	NSLog(@"Disabling NSTimer...");
	[timerWithInt invalidate];
	NSLog(@"NSTimer disabled.");
	NSLog(@"cancelPreviousPerformRequestsWithTarget:self...");
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	NSLog(@"cancelPreviousPerformRequestsWithTarget:self cancelled.");
	[timerWithInt release];
	[self releaseSockets];
	[myRunloop release];
	[NSThread exit];
}

@end

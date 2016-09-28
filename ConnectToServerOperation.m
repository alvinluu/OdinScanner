//
//  ConnectToPrefServerOperation.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/6/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "ConnectToServerOperation.h"
#import "MysqlServer.h"
#import "MBProgressHUD.h"

@interface ConnectToServerOperation ()

@property (nonatomic, weak) MysqlServer *serverToConnect;

@end

@implementation ConnectToServerOperation


@synthesize serverToConnect;

-(id) initWithServer:(MysqlServer *)server
{
	self = [super init];
	if(self)
	{
		self.serverToConnect = server;
	}
	return self;
}


-(void) main
{	
	NSLog(@"Connecting to Server: %@",[serverToConnect description]);	
	
	MysqlConnection *sqlConnection = nil;		
	int connectionAttempts = 2;
	
	while ((sqlConnection == nil) 
		   && (connectionAttempts > 0))
	{		
		sqlConnection = [MysqlConnection connectToServer:serverToConnect];
		connectionAttempts--;
		
		if (sqlConnection)
			NSLog(@"Connected to Server!");
		
		else
			NSLog(@"retrying, connection attempts left: %i",connectionAttempts);
		
	}
	
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate setConnection:sqlConnection];	
}

@end

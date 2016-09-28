//
//  ConnectToPrefServerOperation.h
//  OdinScanner
//
//  Created by Ben McCloskey on 2/6/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConnectToServerOperation : NSOperation <UIApplicationDelegate, MBProgressHUDDelegate>

-(void) main;
-(id) initWithServer:(MysqlServer *)server;

@end

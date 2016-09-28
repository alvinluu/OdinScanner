//
//  AuthenticationStation.h
//  OdinScanner
//
//  Created by Ben McCloskey on 3/16/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LastUpdates+Methods.h"
/*
 Stores current authentication status as well as last known good credentials
Used to check if the app needs to go through the authentication process again
assumes that if it was authenticated once at boot, and no credentials have changed, auth is still good 
(without running it against the server)
 */
@interface AuthenticationStation : NSObject
{
	NSURL *portableServicePath;

}
@property (nonatomic, strong, getter = getSerialNumber) NSString *serialNumber; 
@property (nonatomic, strong) NSString *uid;
@property (nonatomic, getter = isAuthenticated) BOOL isAuthenticated;
@property (nonatomic, setter = setIsOnline:) BOOL isOnline;

@property (nonatomic) BOOL * isLoopingTimer;
@property (nonatomic, strong, getter = syncData) NSDictionary *syncData;

@property (nonatomic) BOOL isPosting;

@property (nonatomic, getter = didInitialSync) BOOL didInitialSync;
@property (nonatomic) BOOL isSyncing; //On = prevent checking student balance
@property (nonatomic) BOOL isStudentConnectionRetry;  //this will trigger resync to re-run student update
@property (nonatomic) BOOL isStudentChecking;
@property (nonatomic) BOOL isTransactionChecking;

@property (nonatomic, strong) NSDate *LastUpdateTransaction;
@property (nonatomic, strong) NSArray* responseData;

//AuthenticationStation uses a singleton instance: sharedHandler
+(AuthenticationStation *) sharedHandler;

//resent the singleton back to the default
//use this when the device is start off deactivated and need to reinitate
-(void) reset;

//returns the current serial number of the attached Linea Scanner
-(NSString *) getSerialNumber;

//returns the device status
-(BOOL) isScannerDeactive;

//returns the domain of the MSSQL server
-(NSString *) getDomain;

//returns authentication status
-(BOOL) isAuthenticated;
//forces the Auth process
-(NSArray*) doAuth;

//setter/getter for path to WebService Host
-(NSURL *) portableServicePath;
-(NSURL *) portableServicePathAFN;
-(void) setPortableServicePath:(NSURL *)portableServicePath;
-(void) startAuth;
-(void) endAuth;
@end

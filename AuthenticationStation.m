//
//  AuthenticationStation.m
//  OdinScanner
//
//  Created by Ben McCloskey on 3/16/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "AuthenticationStation.h"
#import "SynchronizationOperation.h"
#import "StudentUpdate.h"
#import "Linea.h"
#import "A0SimpleKeychain.h"
//#import "UICKeyChainStore.h"

@interface AuthenticationStation()

-(BOOL)haveCredentialsChanged:(LastUpdates *)lastUpdate;
-(BOOL)hasAuthedRecently:(LastUpdates *)lastUpdate;

@end

@implementation AuthenticationStation

@synthesize serialNumber, uid, isAuthenticated;
@synthesize isPosting;
@synthesize isOnline;
@synthesize isSyncing;
@synthesize isStudentChecking, isTransactionChecking;
@synthesize didInitialSync;
@synthesize isLoopingTimer;
@synthesize syncData;
@synthesize responseData;
DTDevices *dtdev2;

static AuthenticationStation *sharedHandler = nil;


+(AuthenticationStation *)sharedHandler
{
    @synchronized(self)
    {
        if (sharedHandler == nil)
            sharedHandler = [[AuthenticationStation alloc] init];
    }
    return sharedHandler;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedHandler == nil) {
            sharedHandler = [super allocWithZone:zone];
            return sharedHandler;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(id) init
{
    if (!serialNumber)
        serialNumber = [self getSerialNumber];
    
    
    if (!uid)
        uid = [[SettingsHandler sharedHandler] uid];
    //gets same default path as authServer. Can change during to auth process
    if (!portableServicePath)
    {
        if ([[SettingsHandler sharedHandler] portablePath])
        {
            portableServicePath = [[SettingsHandler sharedHandler] portablePath];
        }
        else
            portableServicePath = [[SettingsHandler sharedHandler] basePath];
    }
    if (!isOnline)
        isOnline = TRUE;
    
    
    return self;
}
//this will be the same as the init function
-(void) reset
{
    if (!serialNumber)
        serialNumber = [self getSerialNumber];
    
    
    if (!uid)
        uid = [[SettingsHandler sharedHandler] uid];
    [[SettingsHandler sharedHandler] setIsItemSuccessReSync:NO];
    [[SettingsHandler sharedHandler] setIsStudentSuccessReSync:NO];
    
    //gets same default path as authServer. Can change during to auth process
    NSLog(@"reseting to current path %@", [portableServicePath absoluteString]);
    if (!portableServicePath)
    {
        if ([[SettingsHandler sharedHandler] portablePath])
        {
            portableServicePath = [[SettingsHandler sharedHandler] portablePath];
        }
        else
        {
            portableServicePath = [[SettingsHandler sharedHandler] basePath];
        }
    } else //reset the path back to basePath if portableServicePath not nil
    {
        [self setPortableServicePath:[[SettingsHandler sharedHandler] basePath]];
        NSLog(@"reset to basePath to %@", [[SettingsHandler sharedHandler].portablePath absoluteString]);
        
    }
    
    //if (!isOnline)
    //	isOnline = TRUE;
}
//returns the serial number for the linea device
//returns "no device" if there's....no device
-(NSString *)getSerialNumber
{
#ifdef DEBUG
    NSLog(@"get serialnumber");
    //    return @"AP74001EA325B8";
#endif
    
#if TARGET_IPHONE_SIMULATOR
    return @"NTK016704UN0214";
#elif TARGET_IPAD_SIMULATOR
    return @"NTK016704UN0214";
#endif
    SettingsHandler* setting = [SettingsHandler sharedHandler];
    if (setting.useLineaDevice) {
        serialNumber = setting.serialNumber;
        if ([serialNumber hasPrefix:@"NTH"] || [serialNumber hasPrefix:@"MSC"]) {
            
        } else {
#ifdef DEBUG
            NSLog(@"use Linea serialnumber");
#endif
            if (dtdev2 == nil) { dtdev2 = [DTDevices sharedDevice]; }
            
            
            //        if ([dtdev isPresent:DEVICE_TYPE_LINEA]) {
            
            if (dtdev2 == nil) {
                
#ifdef DEBUG
                NSLog(@"device isn't present");
#endif
            } else {
                if ([dtdev2 isPresent:DEVICE_TYPE_LINEA]) {
                    serialNumber = dtdev2.serialNumber;
                } else {
                    serialNumber = @"no device";
                }
#ifdef DEBUG
                NSLog(@"device is present");
#endif
            }
            
            
            if (serialNumber) {
                
#ifdef DEBUG
                NSLog(@"device is present, serial = %@", serialNumber);
#endif
            } else {
                serialNumber = nil;
#ifdef DEBUG
                NSLog(@"device isn't present, serial = %@", serialNumber);
#endif
            }
            //        } else {
            //            serialNumber = setting.serialNumber;
            //            if ([serialNumber hasPrefix:@"AP"]) {
            //                serialNumber = @"no device";
            //            }
            //        }
        }
    } else {
#ifdef DEBUG
        NSLog(@"get ios serialnumber");
#endif
        //check serial key exist
        //        NSString* KEY_ODINAPPS = @"OdinApps";
        NSString* SERAIL_KEY = @"OdinApps";
        //        NSString* bundleid = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppIdentifierPrefix"];//[self bundleSeedID];
        
#ifdef DEBUG
        //        NSLog(@"get bundleid %@",bundleid);
#endif
        //        NSString* ACCESS_GROUP = [NSString stringWithFormat:@"%@group.Odin.apps",bundleid];
        //        A0SimpleKeychain * keychain = [A0SimpleKeychain keychainWithService:KEY_ODINAPPS accessGroup:ACCESS_GROUP];
        //        keychain.useAccessControl = false;
        //        serialNumber = [keychain stringForKey:KEY_ODINAPPS];
        //        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:KEY_ODINAPPS accessGroup:ACCESS_GROUP];
        serialNumber = setting.serialNumber;
        if ([serialNumber hasPrefix:@"AP"]) {
            
        } else {
            
            
            A0SimpleKeychain* keychain = [[SettingsHandler sharedHandler] getKeychain];
            
            serialNumber = [keychain stringForKey:SERAIL_KEY];
#ifdef DEBUG
            NSLog(@"retrieve serial %@ with key %@ group %@",serialNumber,SERAIL_KEY, keychain.accessGroup);
#endif
            if (serialNumber ==  nil) {
                //-- create a new serial number
                
                NSString* data = [[UIDevice currentDevice] identifierForVendor].UUIDString;
                NSArray* dataArray = [data componentsSeparatedByString:@"-"];
                if (dataArray.count > 3) {
                    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:2];
                    [array addObject:@"AP"];
                    [array addObject:[dataArray objectAtIndex:4]];
                    serialNumber = [array componentsJoinedByString:@""];
#ifdef DEBUG
                    NSLog(@"set key %@",serialNumber);
#endif
                    [keychain setString:serialNumber forKey:SERAIL_KEY];
                }
            }
        }
        
    }
    // N0SN NSData* dataSerial;
    //DTDevices *dtdev;
    
    if (serialNumber == nil ||
        [serialNumber isEqualToString:@"temp254"] ||
        [serialNumber isEqualToString:@"N0snversion"] ||
        [serialNumber isEqualToString:@"no device"])
    {
        serialNumber = @"no device";
    }
    
#ifdef DEBUG
    NSLog(@"retrieved Serial Number: %@", serialNumber);
#endif
    
    //serialNumber = @"N0snversion";
    [setting setSerialNumber:serialNumber];
    return serialNumber;
}

- (NSString *)bundleSeedID {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)kSecClass,
                           @"bundleSeedID", kSecAttrAccount,
                           @"", kSecAttrService,
                           (id)kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound)
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status != errSecSuccess)
        return nil;
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *bundleSeedID = [[components objectEnumerator] nextObject];
    CFRelease(result);
    return bundleSeedID;
}

-(BOOL) isScannerDeactive
{
    return [[self getSerialNumber] isEqualToString: @"no device"];
}


-(NSURL *)portableServicePath
{
    
#ifdef DEBUG
    NSLog(@"check for device in portableServicePath");
#endif
    
    
    
    NSString *portablePathString = [[[SettingsHandler sharedHandler] portablePath] description];
    portableServicePath = [NSURL URLWithString:portablePathString];
    
    return portableServicePath;
}
-(NSURL *)portableServicePathAFN
{
    //return [[SettingsHandler sharedHandler] portablePathAFN];
    
    NSString *portablePathString = [[[SettingsHandler sharedHandler] portablePath] description];
    portablePathString = [portablePathString stringByAppendingString:@"/Items"];
    return [NSURL URLWithString:portablePathString];
}

-(void)setPortableServicePath:(NSURL *)newPortableServicePath
{
    NSString *newPortablePath = [newPortableServicePath description];
    [[SettingsHandler sharedHandler] setPortablePath:newPortablePath];
}

-(NSString *)getDomain
{
    NSString *serverString = [[SettingsHandler sharedHandler] serverHost];
    NSRange rangeOfSlash = [serverString rangeOfString:@"\\"];
    
    if 	(rangeOfSlash.location == NSNotFound)
        return nil;
    else
        return [serverString substringToIndex:rangeOfSlash.location];
}

-(NSDictionary *)syncData
{
    //	if (syncData)
    //		return syncData;
    
    //	else
    NSDictionary * downloadData = [WebService getAuthStatus];
    if (downloadData) {
        return downloadData;
    }
    return syncData;
}

-(void)startAuth
{
#ifdef DEBUG
    NSLog(@"startAuth");
#endif
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"startAuth" object:self];
    [self cancelAllOperations];
}
-(void) endAuth
{
#ifdef DEBUG
    NSLog(@"hideAuth");
#endif
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideAuth" object:self];
    [self startStudentUpdates];
}
-(NSArray*)doAuth
{
#ifdef DEBUG
    NSLog(@"do Auth");
#endif
    NSArray* connection_status = [TestIf appCanUseSchoolServerAFN];
    if (connection_status && connection_status.count > 0) {
        id status = [connection_status objectAtIndex:0];
        if ([status isKindOfClass:[NSDictionary class]]) {
            if (![[status valueForKey:@"response_code" ]  isEqualToString:@"200"])
            {
                //NSString* serialNumber = [AuthenticationStation sharedHandler].serialNumber;
                
                //use Web Service to get auth status/data
                syncData = [WebService getAuthStatus];  //this will update when server make any setting change
                if (![[AuthenticationStation sharedHandler] syncData])
                {
                    //since we cannot connect, check there's an error with UID/serial and prompt to enter the UID
                    //ONLY DO THIS DURING RESYNC
                    //COMMENT OUT IN ODINVIEWCONTROLLER SINCE IT IS NO LONGER IN USE
                    /*if (![SettingsHandler sharedHandler].uid) {
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"show uid alert" object:self];
                     //[self showAlertViewToEnterUID];
                     }*/
                    return connection_status;
                }
                else
                {
                    return connection_status;
                }
            }
            
        }
        
    }
    
    
    return connection_status;
}


//checks for authentication
-(BOOL)isAuthenticated
{
#ifdef DEBUG
    NSLog(@"isAuthenticated");
#endif
    //[TestIf appCanUseSchoolServerAFN];
    if (isOnline == FALSE)
        return TRUE;
    
    //check if we have previously authed
    BOOL needToAuth = FALSE;
    NSManagedObjectContext *mainMoc = [CoreDataService getMainMOC];
    
    //if it doesn't exist, we haven't done an initial sync
    LastUpdates *lastUpdate = [LastUpdates getLastUpdatefromMOC:[CoreDataService getMainMOC]];
#ifdef DEBUG
    NSLog([[lastUpdate asDictionary] description]);
#endif
    //attempts to determine whether authenticating is necessary, and then tries to do it
    //if lastAuth was in the distant future, we have not authed ever before, and must auth
    //we need to re-auth if: we've never authed before
    //or any credentials have changed
    //or it hasn't been long enough
    if ([lastUpdate.lastAuth isEqualToDate:[NSDate distantFuture]]){
        needToAuth = TRUE;
    }else{
        //if we've done an initial sync, check on the status
        BOOL previouslyAuthed = [self didInitialSync];
        //if yes, check if credentials have changed
        if(previouslyAuthed){
            if([self haveCredentialsChanged:lastUpdate])
                needToAuth = TRUE;
            if(![self hasAuthedRecently:lastUpdate])
                needToAuth = TRUE;
        }
    }
    //we skip if we've authed recently and credentials haven't changed
    //that is, if authed before and if creds unchanged, needtoAuth will be false
    //otherwise need to auth and should try it
    if (needToAuth == TRUE)
    {
        [self startAuth];
        BOOL authStatus = [self doAuth];
        [self endAuth];
        return authStatus;
    }
    else
    {
#ifdef DEBUG
        NSLog(@"Previously Authed");
#endif
        return TRUE;
    }
}
-(void)cancelAllOperations {
#ifdef DEBUG
    NSLog(@"cancelAllOperations");
#endif
    [AuthenticationStation sharedHandler].isTransactionChecking = true;
    [AuthenticationStation sharedHandler].isStudentChecking = true;
    [SettingsHandler sharedHandler].isProcessingSale = true;
    [AuthenticationStation sharedHandler].isPosting = true;
}
-(void)startStudentUpdates {
#ifdef DEBUG
    NSLog(@"startStudentUpdates");
#endif
    
    [AuthenticationStation sharedHandler].isTransactionChecking = false;
    [AuthenticationStation sharedHandler].isStudentChecking = false;
    [SettingsHandler sharedHandler].isProcessingSale = false;
    [AuthenticationStation sharedHandler].isPosting = false;
}

-(BOOL)haveCredentialsChanged:(LastUpdates *)lastUpdate
{
    
    NSString *currentSerial = [self getSerialNumber];
    NSString *currentUID = [[SettingsHandler sharedHandler] uid];
    NSString *oldSerial = lastUpdate.lastSerial;
    NSString *oldUID = lastUpdate.lastUID;
#ifdef DEBUG
    NSLog(@"Serials:%@=%@. UIDs:%@=%@",currentSerial, oldSerial, currentUID, oldUID);
#endif
    if (([currentSerial isEqualToString:oldSerial] == FALSE)
        || ([currentUID isEqualToString:oldUID] == FALSE))
    {
        return TRUE;
    }
    return FALSE;
}

-(BOOL)didInitialSync
{
    
    //get the time of the last student update from
    LastUpdates *lastUpdate = [LastUpdates getLastUpdatefromMOC:[CoreDataService getMainMOC]];
#ifdef DEBUG
    NSLog((@"attempting didInitialSync"));
    //NSLog(@"%@",[[lastUpdate asDictionary] description]);
#endif
    
    NSDate *lastStudentUpdate = lastUpdate.lastStudentUpdate;
    //if it does not exist or it was set to distantFuture, do another initial sync
    if (lastStudentUpdate == [NSDate distantFuture])
        return FALSE;
    
    //all else return true
    return TRUE;
}

//Checks if the application has authenticated recently enough
-(BOOL)hasAuthedRecently:(LastUpdates *)lastUpdate
{
#ifdef DEBUG
    NSLog(@"hasAuthedRecently");
#endif
    //get time of last authentication
    //find how long it's been since the last auth
    //if > defined constant, return NO, else return YES
    
    NSManagedObjectContext *moc = [CoreDataHelper getMainMOC];
    
    NSDate *now = [NSDate localDate];
    NSDate *lastAuth = lastUpdate.lastAuth;
    
    //set to "save" auth for time definted in kAuthInterval
    NSDate *nextAuth = [[NSDate alloc] initWithTimeInterval:kAuthInverval sinceDate:lastAuth];
    NSTimeInterval timeSinceNextAuth = [now timeIntervalSinceDate:nextAuth];
    //checks if now is > nextAuth
    if (timeSinceNextAuth > 0.0)
    {
        return TRUE;
    }
    return FALSE;
}

- (void) setIsOnline:(BOOL)newOnlineStatus
{
#ifdef DEBUG
    NSLog(@"setisonline isOnline:%i newOnline:%i", isOnline, newOnlineStatus);
#endif
    
    if (isOnline == newOnlineStatus)
    {
        if ([NetworkConnection isInternetOffline]) {
            //[ErrorAlert noInternetConnection];
            isOnline = FALSE;
        } else if ([[AuthenticationStation sharedHandler] isScannerDeactive]) {
            //[ErrorAlert noScannerToOfflineMode];
            isOnline = FALSE;
        }
        return;
    }
    
    //going from offline to online
    //if there is no scanner give error and don't connect
    /*if ((isOnline == FALSE) && (newOnlineStatus == TRUE)) {
     if ([[AuthenticationStation sharedHandler] isScannerDeactive]) {
     [ErrorAlert noScannerToOfflineMode];
     return;
     } else if ([NetworkConnection isInternetOffline])
     {
     [ErrorAlert noInternetConnection];
     }
     }*/
    
    //Online to Offline
    if ((isOnline == TRUE) && (newOnlineStatus == FALSE))
    {
        NSLog(@"switch to offline mode activate");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switched to offline mode" object:self];
        //[[SettingsHandler sharedHandler] setHoldTransactions:YES];
//        [ErrorAlert switchedToOfflineMode];
    }
    else if ((isOnline == FALSE) && (newOnlineStatus == TRUE) &&
             (![TestIf appCanUseSchoolServerAFN]))
        
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"failed switch to online mode" object:self];
        isOnline = FALSE;
    }
    isOnline = newOnlineStatus;
}
@end

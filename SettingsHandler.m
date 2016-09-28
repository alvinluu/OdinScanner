//
//  SettingsHandler.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/16/12.
//
//

#import "SettingsHandler.h"
#import "DTDevices+buttonControls.h"

@interface SettingsHandler()
-(id)handleNilValueFor:(id)object;
@end

@implementation SettingsHandler

@synthesize isAlertDisplay, isItemSuccessReSync, isStudentSuccessReSync, isProcessingSale;
@synthesize ccdigitToVoid, processingRef, keychain, numberOfUploadTransaction;

static SettingsHandler *sharedHandler = nil;
#define REF_NUM @"ReferenceNum"
#define REG_CODE @"ReferenceCode"

+(SettingsHandler *)sharedHandler
{
	@synchronized(self)
	{
		if (sharedHandler == nil)
			sharedHandler = [[SettingsHandler alloc] init];
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
	prefs = [NSUserDefaults standardUserDefaults];
	isAlertDisplay = NO;
	isProcessingSale = false;
	return self;
}

- (void) setDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"2.5",@"version",
								 @"",@"uid",
								 @"YES",@"holdTransactions",
								 @"I",@"registerCode",
								 @"1",@"refNumber",
								 @"NO",@"useExportID",
								 @"NO",@"useBarcode",
								 @"YES",@"checkBalance",
								 @"NO",@"isMSSQL",
								 @"https://msdata.co/Portable",@"serverHost",
								 @"3306",@"serverPort",
								 @"odin",@"serverSchema",
								 @"",@"school",
								 @"https://",@"basePrefix",
//                                 @"https://10.1.10.180/Portable",@"testPath",
                                 @"http://10.1.10.180/Portable",@"testPath",
								 @"https://msdata.co/Portable",@"basePath",
                                 @"https://msdata.co/Portable",@"portablePath",
								 //@"http:myspending.info/mksservice/mksservice.dll/wsdl",@"basePath",
								 //@"http:myspending.info/mksservice/mksservice.dll/wsdl",@"portablePath",
								 @"",@"supplemental",
								 @"",@"receiptLine1",
								 @"",@"receiptLine2",
								 @"",@"receiptLine3",
								 @"",@"receiptLine4",
								 @"",@"receiptLine5",
								 @"NO",@"showOperator",
								 @"YES",@"showTranId",
								 @"NO",@"showApprovedCode",
								 @"YES",@"showTimestamp",
								 @"",@"merchantName",
								 @"",@"merchantLogin",
								 @"",@"merchantPassword",
								 @"",@"serialNumber",
                                 @"YES",@"useLineaDevice",
								 nil];
	[defaults registerDefaults:appDefaults];
	[defaults synchronize];
}
#pragma mark - Getters
-(NSMutableArray*)getReceiptHeader
{
	NSMutableArray* array = [[NSMutableArray alloc] init];
	NSString* line = [prefs objectForKey:@"receiptLine1"];
	if (line) {
		[array addObject:line];
	}
	line = [prefs objectForKey:@"receiptLine2"];
	if (line) {
		[array addObject:line];
	}
	line = [prefs objectForKey:@"receiptLine3"];
	if (line) {
		[array addObject:line];
	}
	line = [prefs objectForKey:@"receiptLine4"];
	if (line) {
		[array addObject:line];
	}
	line = [prefs objectForKey:@"receiptLine5"];
	if (line) {
		[array addObject:line];
	}
	return array;
}
-(NSDictionary*)getReceiptHeaderInDictionary
{
	NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
	NSString* line = [prefs objectForKey:@"receiptLine1"];
	if (line) {
		[dict setValue:line forKey:@"line1"];
	}
	line = [prefs objectForKey:@"receiptLine2"];
	if (line) {
		[dict setValue:line forKey:@"line2"];
	}
	line = [prefs objectForKey:@"receiptLine3"];
	if (line) {
		[dict setValue:line forKey:@"line3"];
	}
	line = [prefs objectForKey:@"receiptLine4"];
	if (line) {
		[dict setValue:line forKey:@"line4"];
	}
	line = [prefs objectForKey:@"receiptLine5"];
	if (line) {
		[dict setValue:line forKey:@"line5"];
	}
	return [NSDictionary dictionaryWithDictionary:dict];
}
-(BOOL) showReceiptOperator
{
	return [prefs boolForKey:@"showOperator"];
}
-(BOOL) showReceiptTranID
{
	return [prefs boolForKey:@"showTranID"];
}
-(BOOL) showReceiptApprovedCode
{
	return [prefs boolForKey:@"showApprovedCode"];
}
-(BOOL) showReceiptTimestamp
{
	return [prefs boolForKey:@"showTimestamp"];
}
-(void) incrementReference
{
	int newRefNumber = (([[prefs objectForKey:@"refNumber"]intValue]) + 1);
    NSString* refstring = [NSString stringWithFormat:@"%i",newRefNumber];
	[prefs setObject:refstring forKey:@"refNumber"];
    [self.keychain setString:refstring forKey:REF_NUM];
	[prefs synchronize];
    
}
-(void) decrementReference
{
    int newRefNumber = (([[prefs objectForKey:@"refNumber"]intValue]) - 1);
    NSString* refstring = [NSString stringWithFormat:@"%i",newRefNumber];
    [prefs setObject:refstring forKey:@"refNumber"];
    [self.keychain setString:refstring forKey:REG_CODE];
    [prefs synchronize];
}
-(NSString*) serialNumber
{
	return [prefs objectForKey:@"serialNumber"];
}
-(NSString*) headerLine1
{
	return [prefs objectForKey:@"receiptLine1"];
}
-(NSString*) headerLine2
{
	return [prefs objectForKey:@"receiptLine2"];
}
-(NSString*) headerLine3
{
	return [prefs objectForKey:@"receiptLine3"];
}
-(NSString*) headerLine4
{
	return [prefs objectForKey:@"receiptLine4"];
}
-(NSString*) headerLine5
{
	return [prefs objectForKey:@"receiptLine5"];
}
-(NSString*) referenceCode
{
    return [self.keychain stringForKey:REG_CODE];
}
-(NSString*) referenceNum
{
    return [self.keychain stringForKey:REF_NUM];
}
-(NSString*) currentReference
{
    
//    NSString* nextRef = [SettingsHandler sharedHandler].referenceNum;
//    int nextNum = [nextRef intValue];
//    nextNum -= 1;
//    NSString* currentRef = [NSString stringWithFormat:@"%@%i",[SettingsHandler sharedHandler].referenceCode, nextNum];
//    return currentRef;
    return processingRef;
}
-(NSString *) getReference
{
    
    //--read keychain
    NSString* refnum = [self referenceNum];
    NSString* regcode = [self referenceCode];
    NSString* refstring = @"";
    
    //--use setting if keychain is nil
    if (regcode == nil) { regcode = [prefs objectForKey:@"registerCode"]; }
    if (refnum == nil) { refnum = [prefs objectForKey:@"refNumber"]; }
    
    //--save to return value
    if ([regcode length] == 1) {
        refstring = [NSString stringWithFormat:@"%@ %@",regcode, refnum];
    } else {
        refstring = [NSString stringWithFormat:@"%@%@",regcode, refnum];
    }
    
    //--save to keychain
    [self.keychain setString:regcode forKey:REG_CODE];
    [self.keychain setString:refnum forKey:REF_NUM];
    
    return refstring;
}

-(NSString *) uid
{
	return [prefs objectForKey:@"uid"];
}

-(NSURL *) basePath
{
#if DEBUG
    NSLog(@"using testPath");
//    return [NSURL URLWithString:[prefs objectForKey:@"testPath"]];
#endif
	return [NSURL URLWithString:[prefs objectForKey:@"basePath"]];
}

-(NSURL *) portablePath
{
	return [NSURL URLWithString:[prefs objectForKey:@"portablePath"]];
}
//-(NSString *) basePathAFN
//{
//	return [prefs objectForKey:@"basePath"];
//}
-(NSString *) portablePathAFN
{
	return [prefs objectForKey:@"portablePath"];
}
-(NSString *) serverHost
{
	NSLog(@"serverhost %@",[prefs objectForKey:@"serverHost"]);
	return [prefs objectForKey:@"serverHost"];
}

-(NSString *)location
{
	return [prefs objectForKey:@"location"];
}

-(NSString *)operator
{
	return [prefs objectForKey:@"operator"];
}

-(NSString *)school
{
	return [prefs objectForKey:@"school"];
}

-(NSString *)serverUsername
{
	return [prefs objectForKey:@"serverUsername"];
}

-(NSString *) serverSchema
{
	return [prefs objectForKey:@"serverSchema"];
}

-(NSString *) basePrefix
{
	return [prefs objectForKey:@"basePrefix"];
}
-(NSString *) merchantName
{
	return [prefs objectForKey:@"merchantName"];
}
-(NSString *) merchantLogin
{
	return [prefs objectForKey:@"merchantLogin"];
}
-(NSString *) merchantPassword
{
	return [prefs objectForKey:@"merchantPassword"];
}
/*-(NSMutableArray *) getMultiTransactions
{
	if (transactions)
		return transactions;
	
	return [[NSMutableArray alloc]init];
}*/
-(int) serverPort
{
	return [[prefs objectForKey:@"serverPort"] intValue];
}

-(int) idStart
{
	return [[prefs objectForKey:@"idStart"] intValue];
}

-(int) idStop
{
	return [[prefs objectForKey:@"idStop"] intValue];
}

-(BOOL) holdTransactions
{
	return [prefs boolForKey:@"holdTransactions"];
}

-(BOOL) checkBalance
{
	return [prefs boolForKey:@"checkBalance"];
}

-(BOOL) allowOverride
{
    return [prefs boolForKey:@"allowOverride"];
}

-(BOOL) isMSSQL
{
	return [prefs boolForKey:@"isMSSQL"];
}
-(BOOL) useBarcode
{
	return [[prefs objectForKey:@"useBarcode"] boolValue];
}
-(BOOL) useExportID
{
	return [[prefs objectForKey:@"useExportID"] boolValue];
}
-(BOOL) isAlertDisplay
{
	return isAlertDisplay;
}

-(BOOL) isItemSuccessReSync
{
	return isItemSuccessReSync;
}
-(BOOL) isStudentSuccessReSync
{
	return isStudentSuccessReSync;
}
-(BOOL) isResyncButtonClicked
{
	return isStudentSuccessReSync;
}
-(BOOL) useLineaDevice
{
    return [[prefs objectForKey:@"useLineaDevice"] boolValue];
}


-(BOOL)isSupplemental
{
	NSString *value = [prefs objectForKey:@"supplemental"];
	return ([value isEqualToString:@"1"])? TRUE : FALSE;
}
-(NSString*) ccdigitToVoid
{
	if (ccdigitToVoid) {
		return ccdigitToVoid;
	}
	return @"";
}
///////////////////////////////////setters\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#pragma mark - Setters
-(id)handleNilValueFor:(id)object
{
	if (object == nil)
		return [NSNull null];
	else
		return object;
}

-(void) setUID:(NSString *)newUID
{
	if ([newUID isEqualToString:[self uid]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newUID]
			  forKey:@"uid"];
	[prefs synchronize];
	
#ifdef DEBUG
	NSLog(@"New UID: %@",[SettingsHandler sharedHandler].uid);
#endif
}

-(void) setPortablePath:(NSString *)newPortablePath
{
	NSString *string = [[self portablePath] description];
	if ([newPortablePath isEqualToString:string])
		return;
	
	[prefs setObject:[self handleNilValueFor:newPortablePath]
			  forKey:@"portablePath"];
	[prefs synchronize];
}

-(void) setHoldTransactions:(BOOL)newHoldTransactions
{
	if (newHoldTransactions == [self holdTransactions])
		return;
	
	/*if ((newHoldTransactions == FALSE) && ([[AuthenticationStation sharedHandler] isOnline] == FALSE))
	{
		[UIAlertView showBasicAlertWithTitle:@"Unable to turn off Hold Transactions" andMessage:@"Transactions must be held while in offline mode"];
		newHoldTransactions = FALSE;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"holdTransactionSwitchOn" object:nil];
		return;
	}*/
	
	[prefs setObject:[self handleNilValueFor:[NSNumber numberWithBool:newHoldTransactions]]
			  forKey:@"holdTransactions"];
	[prefs synchronize];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"holdTransactionsChanged" object:nil];
}

-(void) setIsMSSQL:(BOOL)newMSSQL
{
	if (newMSSQL == [self isMSSQL])
		return;
	
	[prefs setObject:[self handleNilValueFor:[NSNumber numberWithBool:newMSSQL]]
			  forKey:@"isMSSQL"];
	[prefs synchronize];
}

-(void) setServerHost:(NSString *)newServerHost
{
	if ([newServerHost isEqualToString:[self serverHost]])
		return;
	[prefs setObject:[self handleNilValueFor:newServerHost]
			  forKey:@"serverHost"];
	[prefs synchronize];
}

-(void) setServerUsername:(NSString *)newUsername
{
	if ([newUsername isEqualToString:[self serverUsername]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newUsername]
			  forKey:@"serverUsername"];
	[prefs synchronize];
}

-(void) setServerSchema:(NSString *)newSchema
{
	if ([newSchema isEqualToString:[self serverSchema]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newSchema]
			  forKey:@"serverSchema"];
	[prefs synchronize];
}

-(void) setSchool:(NSString *)newSchool
{
	if ([newSchool isEqualToString:[self school]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newSchool]
			  forKey:@"school"];
	[prefs synchronize];
}

-(void) setServerPort:(int)newPort
{
	if (newPort == [self serverPort])
		return;
	
	[prefs setObject:[self handleNilValueFor:[NSNumber numberWithInt:newPort]]
			  forKey:@"serverPort"];
	[prefs synchronize];
}

-(void) setUseBarcode:(BOOL)newScanBarcode
{
	if (newScanBarcode == [self useBarcode])
		return;
	
	[prefs setObject:[self handleNilValueFor:[NSNumber numberWithBool:newScanBarcode]]
			  forKey:@"useBarcode"];
	[prefs synchronize];
}

-(void) setUseExportID:(BOOL)newUseExportID
{
#if DEBUG
    NSLog(@"setUseExportID %@", [NSNumber numberWithBool:newUseExportID]);
#endif
	if (newUseExportID == [self useExportID])
		return;
	
	[prefs setObject:[self handleNilValueFor:[NSNumber numberWithBool:newUseExportID]]
			  forKey:@"useExportID"];
	[prefs synchronize];
}

-(void) setUseLineaDevice:(BOOL)newValue
{
#if DEBUG
    NSLog(@"setUseExportID %@", [NSNumber numberWithBool:newValue]);
#endif
    if (newValue == [self useExportID])
        return;
    
    [prefs setObject:[self handleNilValueFor:[NSNumber numberWithBool:newValue]]
              forKey:@"useLineaDevice"];
    [prefs synchronize];
}

-(void) setCheckBalance:(BOOL)newCheckBalance
{
	if (newCheckBalance == [self checkBalance])
		return;
	
	[prefs setObject:[self handleNilValueFor:[NSNumber numberWithBool:newCheckBalance]]
			  forKey:@"checkBalance"];
	[prefs synchronize];
}

-(void) setAllowOverride:(BOOL)newValue
{
    if (newValue == [self allowOverride])
        return;
    
    [prefs setObject:[self handleNilValueFor:[NSNumber numberWithBool:newValue]]
              forKey:@"allowOverride"];
    [prefs synchronize];
}
-(void) setIsAlertDisplay:(BOOL)newIsAlertDisplay
{
	isAlertDisplay = newIsAlertDisplay;
}
-(void) setIsItemSuccessReSync:(BOOL)newIsItemSuccessReSync
{
	isItemSuccessReSync = newIsItemSuccessReSync;
}
-(void) setIsStudentSuccessResync:(BOOL)newIsStudentSuccessResync
{
	isStudentSuccessReSync = newIsStudentSuccessResync;
}
-(void) setReference:(int) num {
    NSString* newref = [NSString stringWithFormat:@"%i",num];
	[prefs setObject:newref forKey:@"refNumber"];
    [self.keychain setString:newref forKey:REF_NUM];
    
}
-(void) setRegisterCode:(NSString*) code {
    [prefs setObject:code forKey:@"registerCode"];
    [self.keychain setString:code forKey:REG_CODE];
    
}
-(void) setSupplemental:(BOOL)newSupplemental
{
	if (newSupplemental == [self isSupplemental])
		return;
	[prefs setObject:[self handleNilValueFor:[NSString stringWithFormat:@"%i", newSupplemental]]
			  forKey:@"supplemental"];
	[prefs synchronize];
}

-(void) setReceiptLine1:(NSString*) newLine
{
	
	if ([newLine isEqualToString:[prefs objectForKey:@"receiptLine1"]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newLine]
			  forKey:@"receiptLine1"];
	[prefs synchronize];
}
-(void) setReceiptLine2:(NSString*) newLine
{
	
	if ([newLine isEqualToString:[prefs objectForKey:@"receiptLine2"]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newLine]
			  forKey:@"receiptLine1"];
	[prefs synchronize];
}
-(void) setReceiptLine3:(NSString*) newLine
{
	
	if ([newLine isEqualToString:[prefs objectForKey:@"receiptLine3"]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newLine]
			  forKey:@"receiptLine1"];
	[prefs synchronize];
}
-(void) setReceiptLine4:(NSString*) newLine
{
	
	if ([newLine isEqualToString:[prefs objectForKey:@"receiptLine4"]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newLine]
			  forKey:@"receiptLine1"];
	[prefs synchronize];
}
-(void) setReceiptLine5:(NSString*) newLine
{
	
	if ([newLine isEqualToString:[prefs objectForKey:@"receiptLine5"]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newLine]
			  forKey:@"receiptLine1"];
	[prefs synchronize];
}
-(void) setCCdigitToVoid:(NSString*) digit
{
	ccdigitToVoid = digit;
}
-(void) setMerchantName:(NSString*) newLine
{
	
	if ([newLine isEqualToString:[prefs objectForKey:@"merchantName"]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newLine]
			  forKey:@"merchantName"];
	[prefs synchronize];
}
-(void) setMerchantLogin:(NSString*) newLine
{
	
	if ([newLine isEqualToString:[prefs objectForKey:@"merchantLogin"]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newLine]
			  forKey:@"merchantLogin"];
	[prefs synchronize];
}
-(void) setMerchantPassword:(NSString*) newLine
{
	
	if ([newLine isEqualToString:[prefs objectForKey:@"merchantPassword"]])
		return;
	
	[prefs setObject:[self handleNilValueFor:newLine]
			  forKey:@"merchantPassword"];
	[prefs synchronize];
}
-(void) setSerialNumber:(NSString*) newLine
{
	
	if ([newLine isEqualToString:[prefs objectForKey:@"serialNumber"]])
		return;
	if (newLine && ![newLine isEqualToString:@"no device"]) {
		
		[prefs setObject:[self handleNilValueFor:newLine] forKey:@"serialNumber"];
		
	}
	[prefs synchronize];
}

-(void) processingSaleStart {
#ifdef DEBUG
	NSLog(@"process sale start");
#endif
	isProcessingSale = true;
	//[[DTDevices sharedDevice] disableButton];
}


-(void) processingSaleEnd {
#ifdef DEBUG
	NSLog(@"process sale end");
#endif
	isProcessingSale = false;
	//[[DTDevices sharedDevice] enableButton];
}
-(A0SimpleKeychain*)getKeychain {
    if (keychain == nil) {
        NSString* KEY_ODINAPPS = @"OdinApps";
        NSString* bundleid = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppIdentifierPrefix"];//[self bundleSeedID];
        NSString* ACCESS_GROUP = [NSString stringWithFormat:@"%@group.Odin.apps",bundleid];
#ifdef DEBUG
        NSLog(@"create new keychain with bundleid:%@ and groupid:%@",bundleid,ACCESS_GROUP);
#endif
        keychain = [A0SimpleKeychain keychainWithService:KEY_ODINAPPS accessGroup:ACCESS_GROUP];
        float osversion = [UIDevice currentDevice].systemVersion.floatValue;
        if (osversion >= 8.0) {
            
#ifdef DEBUG
            NSLog(@"iOS 8.0 or later");
#endif
            keychain.useAccessControl = false;
            keychain.defaultAccessiblity = A0SimpleKeychainItemAccessibleAfterFirstUnlockThisDeviceOnly;
        }
        
    }
    return keychain;
}
@end
/*
 -(void) updateServerSettingsFromData:(NSDictionary *)serverData
 {
 NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
 NSLog(@"%@",serverData);
 if ([serverData objectForKey:@"server"])
 {
 NSString *serverHost = [serverData objectForKey:@"server"];
 [prefs setValue:serverHost forKey:@"serverHost"];
 }
 if ([serverData objectForKey:@"user"])
 {
 NSString *serverUsername = [serverData objectForKey:@"user"];
 [prefs setValue:serverUsername forKey:@"serverUsername"];
 }
 if ([serverData objectForKey:@"db"])
 {
 NSString *serverSchema = [serverData objectForKey:@"db"];
 [prefs setValue:serverSchema forKey:@"serverSchema"];
 }
 if ([serverData objectForKey:@"port"])
 {
 NSString *serverPort = [serverData objectForKey:@"port"];
 [prefs setValue:serverPort forKey:@"serverPort"];
 }
 if ([serverData objectForKey:@"MSSQL"])
 {
 NSNumber *isMSSQL = [serverData objectForKey:@"MSSQL"];
 [prefs setValue:isMSSQL forKey:@"isMSSQL"];
 }
 [prefs synchronize];
 #ifdef DEBUG
 NSLog(@"Saved Server Settings");
 #endif
 }
 
 -(void) updatePreferencesFromData:(NSDictionary *)prefData
 {
 NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
 if ([prefData objectForKey:@"scan_barcode"])
 {
 NSNumber *useBarcode = [prefData objectForKey:@"scan_barcode"];
 [prefs setValue:useBarcode forKey:@"useBarcode"];
 }
 if ([prefData objectForKey:@"scan_exportid"])
 {
 NSNumber *useExportID = [prefData objectForKey:@"scan_exportid"];
 [prefs setValue:useExportID forKey:@"useExportID"];
 }
 if ([prefData objectForKey:@"school"])
 {
 NSString *school = [prefData objectForKey:@"school"];
 [prefs setValue:school forKey:@"school"];
 }
 if ([prefData objectForKey:@"check_balance"])
 {
 NSNumber *checkBalance = [prefData objectForKey:@"check_balance"];
 [prefs setValue:checkBalance forKey:@"checkBalance"];
 }
 if ([prefData objectForKey:@"PHPpath"])
 {
 NSString *phpPath = [prefData objectForKey:@"PHPpath"];
 NSString *basePrefix = [prefs objectForKey:@"basePrefix"];
 if (([phpPath hasPrefix:basePrefix] == false) && !([[phpPath substringWithRange:NSMakeRange(0,4)] isEqualToString:@"http"]))
 phpPath = [NSString stringWithFormat:@"%@%@",basePrefix, phpPath];
 
 NSURL *portablePath = [NSURL URLWithString:phpPath];
 [[AuthenticationStation sharedHandler] setPortableServicePath:portablePath];
 }
 
 [prefs synchronize];
 #ifdef DEBUG
 NSLog(@"Saved School Settings");
 #endif
 }

*/
//
//  SettingsHandler.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/16/12.
//
//

#import <Foundation/Foundation.h>
#import "OdinTransaction.h"
#import "A0SimpleKeychain+KeyPair.h"

@interface SettingsHandler : NSObject
{
	NSUserDefaults *prefs;

}
@property (nonatomic) BOOL isAlertDisplay;
@property (nonatomic) BOOL isItemSuccessReSync;
@property (nonatomic) BOOL isStudentSuccessReSync;
@property (nonatomic) BOOL isSupplemental;
@property (nonatomic, strong) NSString* ccdigitToVoid;
@property (nonatomic) BOOL isProcessingSale;
@property (nonatomic, strong) NSString* processingRef;
@property (nonatomic) int numberOfUploadTransaction;
@property (nonatomic, strong) A0SimpleKeychain* keychain;
//@property (nonatomic) NSString* ProcessingRef;
//returns singleton instance of SettingsHandler
+(SettingsHandler *)sharedHandler;
//sets initial default values for application settings
-(void) setDefaults;
-(NSMutableArray*)getReceiptHeader;
-(NSDictionary*)getReceiptHeaderInDictionary;
-(BOOL)showReceiptOperator;
-(BOOL) showReceiptTranID;
-(BOOL) showReceiptApprovedCode;
-(BOOL) showReceiptTimestamp;
//increments the reference number
-(NSString*) headerLine1;
-(NSString*) headerLine2;
-(NSString*) headerLine3;
-(NSString*) headerLine4;
-(NSString*) headerLine5;
-(NSString*) referenceCode;
-(NSString*) referenceNum;
-(NSString*) currentReference;
-(void) incrementReference;
-(void) decrementReference;
//returns the reference number
-(NSString *) getReference;
//basic gets
-(NSString *) uid;
-(NSURL *) basePath;
//-(NSString *) basePathAFN;
-(NSURL *) portablePath;
-(NSString *) portablePathAFN;
-(NSString *) serverHost;
-(NSString *) location;
-(NSString *) operator;
-(NSString *) school;
-(NSString *) serverUsername;
-(NSString *) serverSchema;
-(NSString *) basePrefix;
-(NSString *) merchantName;
-(NSString *) merchantLogin;
-(NSString *) merchantPassword;
-(NSString*) serialNumber;
-(A0SimpleKeychain*)getKeychain;
//-(NSMutableArray *) getMultiTransactions;
-(int) serverPort;
-(int) idStart;
-(int) idStop;
-(BOOL) holdTransactions;
-(BOOL) useExportID;
-(BOOL) checkBalance;
-(BOOL) allowOverride;
-(BOOL) isMSSQL;
-(BOOL) useBarcode;
-(BOOL) isAlertDisplay;
-(BOOL) isItemSuccessReSync;
-(BOOL) isStudentSuccessReSync;
-(BOOL) isSupplemental;
-(BOOL) useLineaDevice;
-(NSString*) ccdigitToVoid;

//basic sets
-(void) setUID:(NSString *)newUID;
-(void) setPortablePath:(NSString *)newPortablePath;
-(void) setHoldTransactions:(BOOL)newHoldTransactions;
-(void) setIsMSSQL:(BOOL)newMSSQL;
-(void) setServerHost:(NSString *)newServerHost;
-(void) setServerUsername:(NSString *)newUsername;
-(void) setServerSchema:(NSString *)newSchema;
-(void) setServerPort:(int)newPort;
-(void) setSchool:(NSString *)newSchool;
-(void) setUseBarcode:(BOOL)newScanBarcode;
-(void) setUseExportID:(BOOL)newUseExportID;
-(void) setUseLineaDevice:(BOOL)newValue;
-(void) setCheckBalance:(BOOL)newCheckBalance;
-(void) setAllowOverride:(BOOL)newValue;
-(void) setIsAlertDisplay:(BOOL)newIsAlertDisplay;
-(void) setIsItemSuccessReSync:(BOOL)newIsItemSuccessReSync;
-(void) setIsStudentSuccessReSync:(BOOL)newIsStudentSuccessReSync;
-(void) setReference:(int)num;
-(void) setRegisterCode:(NSString*) code;
-(void) setSupplemental:(BOOL)newSupplemental;

-(void) setReceiptLine1:(NSString*) newLine;
-(void) setReceiptLine2:(NSString*) newLine;
-(void) setReceiptLine3:(NSString*) newLine;
-(void) setReceiptLine4:(NSString*) newLine;
-(void) setReceiptLine5:(NSString*) newLine;
-(void) setCCdigitToVoid:(NSString*) digit;

-(void) setMerchantName:(NSString*) newLine;
-(void) setMerchantLogin:(NSString*) newLine;
-(void) setMerchantPassword:(NSString*) newLine;
-(void) setSerialNumber:(NSString*) newLine;

//functions
-(void) processingSaleStart;
-(void) processingSaleEnd;
@end

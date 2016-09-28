//
//  ErrorAlerts.h
//  OdinScanner
//
//  Created by Ben McCloskey on 1/31/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ErrorAlert : NSObject

+(void) emptyField;
+(void) invalidQuantity;
+(void) invalidRetail;
+(void) invalidTax;
+(void) studentNotFound:(NSString *)studentID;
+(void) studentNotFetch:(NSString *)studentID;
+(void) studentNotFetchToOfflineMode:(NSString *)studentID;
+(void) itemNotFound:(NSString *)itemID;
//+(void) studentCantAfford:(NSString *)studentID;
+(void) studentCantAfford:(NSString *)studentID funds:(NSNumber*)funds;
+(void) studentCantPurchaseFromLocation:(int)location;
+(void) emptyFieldError;
+(void) cardPresentAlert;
+(void) switchedToOfflineMode;
+(void) cannotUpdateInOffline;
+(void) cannotSwitchToOnline;

+(void) saveFailure;
+(void) noUploads;
+(void) synchedAlert;
+(void) noEmail;
+(void) noServer:(NSURL *)path;
+(void) noUIDmatch;
+(void) noSchoolServer;
+(void) noStudentConnection:(NSString*)id_number;
+(void) noStudentConnection:(NSString*)id_number error:(NSString*)error;
+(void) noItemConnection;
+(void) noSeverConnection;
+(void) noScanner;
+(void) noScannerToOfflineMode;
+(void) noInternetConnection;
+(void) appCannotUseSchoolServer;
+(void) noItem;
+(void) noItemSelected;
+(void)noStudentEntre;
+(void) noCost;
+(void) duplicateItem;
+(void) attendanceDenied;
+(void) cannotEditItem;
+(void) cannotEditItem:(NSString *)specifier;
+(void) appIsNotSynchronized;
+(void) errorUploadingData;
+(void) cannnotCheckBalance;



+(void)chargeDeclined;
+(void)failToPostToWebservice;
+(void)failToPostToEmailService;
//General
+(void) dismissAllAlert;
+(void) simpleAlertTitle:(NSString*)title message:(NSString*)msg;


//Testing
+(void) testAlert;
+(void) testAlert: (NSString*) serial_number;
@end

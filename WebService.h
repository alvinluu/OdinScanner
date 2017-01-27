//
//  WebService.h
//  OdinScanner
//
//  Created by Ben McCloskey on 5/1/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface WebService : NSObject <NSXMLParserDelegate>
@property (nonatomic, strong) NSString* responseString;
//--------------------------------------------------------------------------------------
+ (NSDictionary *)getAuthStatus;
+ (NSDictionary *)getDefaultParametersWithSync:(BOOL)sync;
//--------------------------------------------------------------------------------------
+ (int)fetchReferenceNumberAFN;
+ (void)fetchReferenceNumberAFNRecall;
+ (NSArray *)fetchItemList;
+ (NSDictionary *)fetchItemWithPLU:(NSString *)plu;
+ (NSDictionary *)fetchRegisterItemWithBarcodeAFN:(NSString *)barcode;
//--------------------------------------------------------------------------------------
+ (NSArray *)fetchStudentList;
+ (void)fetchStudentListRecall;
+ (NSDictionary *)fetchStudentWithID:(NSString *)id_number;
//+ (void)fetchStudentWithIDRecall:(NSString *)id_number;
+ (void)fetchStudentWithIDRecall:(NSString *)id_number andMoc:(NSManagedObjectContext*)moc;
//--------------------------------------------------------------------------------------
+ (NSString*)postTransactionAFN:(NSDictionary *)transaction;
+ (void)postTransactionAFNWithRecall:(NSDictionary *)transaction isBatch:(BOOL)batch;
+ (BOOL)postUploadedTransactionAFN:(NSDictionary *)transaction;
+ (void)postTransactionWithStringAFNWithTransaction:(OdinTransaction*)transaction;
+(NSString*)postTransactionWithStringAFN:(NSString*)xmlString;
//--------------------------------------------------------------------------------------
+ (AFHTTPRequestOperationManager*) createAFHTTPRequestWithPortableURL;
+ (AFHTTPSessionManager*) createAFHTTPSessionWithPortableURL;
+ (void)postError:(NSDictionary*)params;
@end

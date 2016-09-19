//
//  WebService.h
//  OdinScanner
//
//  Created by Ben McCloskey on 5/1/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebServiceASFHTTP : NSObject

//--------------------------------------------------------------------------------------
+ (NSDictionary *)getAuthStatus;
//--------------------------------------------------------------------------------------
+ (NSArray *)fetchItemList;
+ (NSDictionary *)fetchItemWithPLU:(NSString *)plu;
+ (NSDictionary *)fetchRegisterItemWithBarcode:(NSString *)barcode;
//--------------------------------------------------------------------------------------
+ (NSArray *)fetchStudentList;
+ (NSDictionary *)fetchStudentWithID:(NSString *)id_number;
//--------------------------------------------------------------------------------------
+ (BOOL)postTransaction:(NSDictionary *)transaction;
+ (BOOL)postUploadedTransaction:(NSDictionary *)transaction;
//--------------------------------------------------------------------------------------
+ (void)stayHereTillResponse;
@end

//
//  Temptran.h
//  OdinScanner
//
//  Created by Ben McCloskey on 1/25/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OdinTransaction.h"

@interface Temptran : NSObject

@property (strong) NSString *id_number;
@property (strong) NSString *location;
@property (strong) NSString *plu;
@property (strong) NSString *item;
@property (strong) NSString *payment;
@property (strong) NSString *reference;
@property (strong) NSString *operator;
@property (strong) NSString *qdate;
@property (strong) NSString *time;
@property (strong) NSNumber *glcode;
@property (strong) NSNumber *dept_code;
@property (strong) NSNumber *qty; 
@property (strong) NSNumber *amount;
@property (strong) NSNumber *tax_amount;
@property (strong) NSString *school;

+(NSString *)header;
-(NSString *)asString;
-(Temptran *)builtFromTransaction:(OdinTransaction *)transaction;

@end

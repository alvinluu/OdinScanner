//
//  OdinEvent.h
//  OdinScanner
//
//  Created by Ken Thomsen on 2/19/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


/*
 Known bug: dept_code define as NSString (supposedly NSNumber) because Transaction CoreData is defined as String
 */
@interface OdinEvent : NSManagedObject

@property (nonatomic, retain) NSNumber * allow_amount;
@property (nonatomic, retain) NSNumber * allow_edit;
@property (nonatomic, retain) NSNumber * allow_item;
@property (nonatomic, retain) NSNumber * allow_manual_id;
@property (nonatomic, retain) NSNumber * allow_qty;
@property (nonatomic, retain) NSNumber * allow_stock;
@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) NSNumber * chk_balance;
@property (nonatomic, retain) NSNumber * glcode;
@property (nonatomic, retain) NSString * dept_code;
@property (nonatomic, retain) NSString * item;
@property (nonatomic, retain) NSNumber * location;
@property (nonatomic, retain) NSNumber * lock_cfg;
@property (nonatomic, retain) NSString * operator;
@property (nonatomic, retain) NSString * plu;
@property (nonatomic, retain) NSNumber * qty;
@property (nonatomic, retain) NSString * school;
@property (nonatomic, retain) NSString * stock_name;
@property (nonatomic, retain) NSDecimalNumber * tax;
@property (nonatomic, retain) NSString * barcode;
@property (nonatomic, retain) NSNumber * taxable;
@property (nonatomic, retain) NSNumber * process_on_sync;

@end

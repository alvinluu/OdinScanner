//
//  OdinTransaction.h
//  OdinScanner
//
//  Created by Ken Thomsen on 2/19/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/*
 Known bug: dept_code define as NSString (supposedly NSNumber) because CoreData is defined as String
 */
@interface OdinTransaction : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) NSString * dept_code;
@property (nonatomic, retain) NSNumber * glcode;
@property (nonatomic, retain) NSString * id_number;
@property (nonatomic, retain) NSString * item;
@property (nonatomic, retain) NSNumber * location;
@property (nonatomic, retain) NSString * operator;
@property (nonatomic, retain) NSString * payment;
@property (nonatomic, retain) NSString * plu;
@property (nonatomic, retain) NSString * qdate;
@property (nonatomic, retain) NSNumber * qty;
@property (nonatomic, retain) NSString * reference;
@property (nonatomic, retain) NSString * school;
@property (nonatomic, retain) NSNumber * sync;
@property (nonatomic, retain) NSDecimalNumber * tax_amount;
@property (nonatomic, retain) NSString * time;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSNumber * process_on_sync;

//Credit card 2.6.0
@property (nonatomic, retain) NSNumber * cc_digit;
@property (nonatomic, retain) NSString * cc_tranid;
@property (nonatomic, retain) NSString * first;
@property (nonatomic, retain) NSString * last;
@property (nonatomic, retain) NSString * cc_approval;
@property (nonatomic, retain) NSString * cc_timeStamp;
@property (nonatomic, retain) NSString * cc_responsetext;

@property (nonatomic, retain) NSString * type;


@end

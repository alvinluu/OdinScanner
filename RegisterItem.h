//
//  RegisterItem.h
//  OdinScanner
//
//  Created by Ken Thomsen on 2/22/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RegisterItem : NSManagedObject

@property (nonatomic, retain) NSString * item;
@property (nonatomic, retain) NSDecimalNumber * retail;
@property (nonatomic, retain) NSNumber * taxable;
@property (nonatomic, retain) NSDecimalNumber * taxrate;
@property (nonatomic, retain) NSString * deptCode;
@property (nonatomic, retain) NSString * glCode;
@property (nonatomic, retain) NSNumber * location;
@property (nonatomic, retain) NSString * plu;
@property (nonatomic, retain) NSString * school;
@property (nonatomic, retain) NSString * barcode;

@end

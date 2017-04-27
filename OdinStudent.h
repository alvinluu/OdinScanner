//
//  OdinStudent.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/23/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface OdinStudent : NSManagedObject

@property (nonatomic, retain) NSString * accnt_type;
@property (nonatomic, retain) NSDecimalNumber * area_1;
@property (nonatomic, retain) NSDecimalNumber * area_2;
@property (nonatomic, retain) NSDecimalNumber * area_3;
@property (nonatomic, retain) NSDecimalNumber * area_4;
@property (nonatomic, retain) NSDecimalNumber * area_5;
@property (nonatomic, retain) NSDecimalNumber * area_6;
@property (nonatomic, retain) NSDecimalNumber * area_7;
@property (nonatomic, retain) NSDecimalNumber * area_8;
@property (nonatomic, retain) NSDecimalNumber * area_9;
@property (nonatomic, retain) NSString * exportid;
@property (nonatomic, retain) NSString * id_number;
@property (nonatomic, retain) NSString * last_name;
@property (nonatomic, retain) NSString * p_email;
@property (nonatomic, retain) NSString * s_email;
@property (nonatomic, retain) NSDate * last_update;
@property (nonatomic, retain) NSDecimalNumber * present;
@property (nonatomic, retain) NSDecimalNumber * threshold;
@property (nonatomic, retain) NSString * student;
@property (nonatomic, retain) NSString * studentuid;
@property (nonatomic, retain) NSString * time_1;
@property (nonatomic, retain) NSString * time_2;
@property (nonatomic, retain) NSString * time_3;
@property (nonatomic, retain) NSString * time_4;
@property (nonatomic, retain) NSString * time_5;
@property (nonatomic, retain) NSString * time_6;
@property (nonatomic, retain) NSString * time_7;
@property (nonatomic, retain) NSString * time_8;
@property (nonatomic, retain) NSString * time_9;

@end

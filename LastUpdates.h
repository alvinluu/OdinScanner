//
//  LastUpdates.h
//  OdinScanner
//
//  Created by Ben McCloskey on 3/26/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LastUpdates : NSManagedObject

@property (nonatomic, retain) NSDate * lastStudentUpdate;
@property (nonatomic, retain) NSDate * lastItemUpdate;
@property (nonatomic, retain) NSDate * lastAuth;
@property (nonatomic, retain) NSString * lastUID;
@property (nonatomic, retain) NSString * lastSerial;



@end

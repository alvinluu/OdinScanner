//
//  LastUpdates.m
//  OdinScanner
//
//  Created by Ben McCloskey on 3/26/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "LastUpdates.h"
#import "CoreDataHelper.h"

@implementation LastUpdates

@dynamic lastStudentUpdate;
@dynamic lastItemUpdate;
@dynamic lastAuth;
@dynamic lastUID;
@dynamic lastSerial;


- (id)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self == nil) {
        // Perform additional initialization.
		self.lastAuth = [NSDate distantFuture];
		self.lastStudentUpdate = [NSDate distantFuture];
		self.lastItemUpdate = [NSDate distantFuture];
		self.lastUID = @"N";
		self.lastSerial = @"N";
    }
    return self;
}
@end

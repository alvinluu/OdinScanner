//
//  CoreDataTests.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/15/12.
//
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

@interface CoreDataTests : XCTestCase{
    NSPersistentStoreCoordinator *coord;
    NSManagedObjectContext *ctx;
    NSManagedObjectModel *model;
    NSPersistentStore *store;
}

@end

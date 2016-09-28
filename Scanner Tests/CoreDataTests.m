//
//  CoreDataTests.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/15/12.
//
//

#import "CoreDataTests.h"

@implementation CoreDataTests

- (void)setUp
{
    model = [NSManagedObjectModel mergedModelFromBundles: nil];
    NSLog(@"model: %@", model);
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
    store = [coord addPersistentStoreWithType: NSInMemoryStoreType
                                configuration: nil
                                          URL: nil
                                      options: nil
                                        error: NULL];
    ctx = [[NSManagedObjectContext alloc] init];
    [ctx setPersistentStoreCoordinator: coord];
}

- (void)tearDown
{
    ctx = nil;
    NSError *error = nil;
    XCTAssertTrue([coord removePersistentStore: store error: &error],
                 @"couldn't remove persistent store: %@", error);
    store = nil;
    coord = nil;
    model = nil;
}

- (void)testThatEnvironmentWorks
{
    XCTAssertNotNil(store, @"no persistent store");
}

@end

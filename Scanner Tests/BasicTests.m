//
//  BasicTests.m
//  OdinScanner
//
//  Created by KenThomsen on 12/10/14.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface BasicTests : XCTestCase

@end

@implementation BasicTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testAlert
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Title" message:@"Hellow World" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
													 style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
							 {
								 NSLog(@"Cancel Action");
							 }];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
													 style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
							 {
								 NSLog(@"OK Action");
							 }];
	[alertController addAction:cancel];
	[alertController addAction:ok];
	//[self presentViewcontroller:alertController animated:YES completion:nil];
}


@end

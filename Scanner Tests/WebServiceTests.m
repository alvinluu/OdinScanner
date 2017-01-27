//
//  WebServiceTests.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/17/12.
//
//

#import "WebServiceTests.h"
#import "SBJson.h"
#import "SynchronizationOperation.h"
#import "CoreDataHelper.h"
#import "OdinStudent+Methods.h"
#import "OdinEvent+Methods.h"
#import "AFNetworking.h"


@implementation WebServiceTests

-(NSArray *)createKentStyleStudentReturn
{
	NSString *kentStyleStudent = @"[{\"id_number\":\"01-210-57025\",\"exportid\":\"01-210-57025\",	\"student\":\"01-210-57025\",	\"last_name\":\"GO SOCIETY\",	\"accnt_type\":\"D\",	\"area_1\":\".00\",	\"time_1\":\"N\",	\"area_2\":\".00\",	\"area_3\":\".00\",	\"area_4\":\".00\",	\"area_5\":\".00\",	\"area_6\":\".00\",	\"area_7\":\".00\",	\"area_8\":\".00\",	\"area_9\":\".00\",	\"time_2\":\"N\",	\"time_3\":\"D\",	\"time_4\":\"W\",	\"time_5\":\"T\",	\"time_6\":\"N\",	\"time_7\":\"N\",	\"time_8\":\"N\",	\"time_9\":\"N\",	\"present\":\".00\"}]";
	
	NSArray *studentArray = [kentStyleStudent JSONValue];
	return studentArray;
	
}

- (void)testStudentUpdateWithKentStyle
{
	NSArray *studentArray = [self createKentStyleStudentReturn];
	for (NSDictionary *studentDictionary in studentArray)
	{
        [OdinStudent updateThisStudentWith:studentDictionary andMOC:ctx sync:true];
	}
	[CoreDataHelper saveObjectsInContext:ctx];
	for (NSDictionary *studentDictionary in studentArray)
	{
		
		OdinStudent *studentToCheck;
		NSArray *studentCoreDataArray = [CoreDataHelper searchObjectsForEntity:@"OdinStudent"
																 withPredicate:[NSPredicate predicateWithFormat:@"id_number == %@",[studentDictionary objectForKey:@"id_number"]]
																	andSortKey:nil
															  andSortAscending:NO
																	andContext:ctx];
		if ([studentCoreDataArray count] > 0)
			studentToCheck = [studentCoreDataArray objectAtIndex:0];
		
		XCTAssertNotNil(studentToCheck, @"no student created");
		XCTAssertNotNil(studentDictionary, @"no student dictionary created");
		
		XCTAssertTrue([[studentToCheck id_number]isEqualToString:@"01-210-57025"], @"id_number does not match");
		XCTAssertTrue([[studentToCheck exportid]isEqualToString:@"01-210-57025"], @"exportid does not match");
		XCTAssertTrue([[studentToCheck student]isEqualToString:@"01-210-57025"], @"student does not match");
		XCTAssertTrue([[studentToCheck last_name]isEqualToString:@"GO SOCIETY"], @"last_name does not match");
		XCTAssertTrue([[studentToCheck accnt_type]isEqualToString:@"D"], @"accnt_type does not match");
		
		XCTAssertEqual([[studentToCheck area_1] doubleValue], 0.0, @"area_1 does not match");
		XCTAssertEqual([[studentToCheck area_2] doubleValue], 0.0, @"area_2 does not match");
		XCTAssertEqual([[studentToCheck area_3] doubleValue], 0.0, @"area_3 does not match");
		XCTAssertEqual([[studentToCheck area_4] doubleValue], 0.0, @"area_4 does not match");
		XCTAssertEqual([[studentToCheck area_5] doubleValue], 0.0, @"area_5 does not match");
		XCTAssertEqual([[studentToCheck area_6] doubleValue], 0.0, @"area_6 does not match");
		XCTAssertEqual([[studentToCheck area_7] doubleValue], 0.0, @"area_7 does not match");
		XCTAssertEqual([[studentToCheck area_8] doubleValue], 0.0, @"area_8 does not match");
		XCTAssertEqual([[studentToCheck area_9] doubleValue], 0.0, @"area_9 does not match");
		XCTAssertEqual([[studentToCheck present] doubleValue], 0.0, @"present does not match");
		
		XCTAssertTrue([[studentToCheck time_1]isEqualToString:@"N"], @"time_1 does not match");
		XCTAssertTrue([[studentToCheck time_2]isEqualToString:@"N"], @"time_2 does not match");
		XCTAssertTrue([[studentToCheck time_3]isEqualToString:@"D"], @"time_3 does not match");
		XCTAssertTrue([[studentToCheck time_4]isEqualToString:@"W"], @"time_4 does not match");
		XCTAssertTrue([[studentToCheck time_5]isEqualToString:@"T"], @"time_5 does not match");
		XCTAssertTrue([[studentToCheck time_6]isEqualToString:@"N"], @"time_6 does not match");
		XCTAssertTrue([[studentToCheck time_7]isEqualToString:@"N"], @"time_7 does not match");
		XCTAssertTrue([[studentToCheck time_8]isEqualToString:@"N"], @"time_8 does not match");
		XCTAssertTrue([[studentToCheck time_9]isEqualToString:@"N"], @"time_9 does not match");
	}
}

- (NSArray *)createRegularStudentReturn
{
	NSString *regularStudent = @"[{\"id_number\":\"01-210-57025\",\"exportid\":\"01-210-57025\",\"student\":\"01-210-57025\",\"last_name\":\"GO SOCIETY\",\"accnt_type\":\"D\",\"area_1\":0,\"time_1\":\"N\",\"area_2\":0,	\"area_3\":0,\"area_4\":0,\"area_5\":0,\"area_6\":0,\"area_7\":0,\"area_8\":0,\"area_9\":0,	\"time_2\":\"N\",\"time_3\":\"D\",\"time_4\":\"W\",\"time_5\":\"T\",\"time_6\":\"N\",\"time_7\":\"N\",\"time_8\":\"N\",\"time_9\":\"N\",\"present\":0}]";
	
	NSArray *studentArray = [regularStudent JSONValue];
	return studentArray;
}

- (void)testStudentUpdateWithRegularStyle
{
	NSArray *studentArray = [self createRegularStudentReturn];
	for (NSDictionary *studentDictionary in studentArray)
	{
        [OdinStudent updateThisStudentWith:studentDictionary andMOC:ctx sync:true];
	}
	[CoreDataHelper saveObjectsInContext:ctx];
	for (NSDictionary *studentDictionary in studentArray)
	{
		
		OdinStudent *studentToCheck;
		NSArray *studentCoreDataArray = [CoreDataHelper searchObjectsForEntity:@"OdinStudent"
																 withPredicate:[NSPredicate predicateWithFormat:@"id_number == %@",[studentDictionary objectForKey:@"id_number"]]
																	andSortKey:nil
															  andSortAscending:NO
																	andContext:ctx];
		if ([studentCoreDataArray count] > 0)
			studentToCheck = [studentCoreDataArray objectAtIndex:0];
		
		XCTAssertNotNil(studentToCheck, @"no student created");
		XCTAssertNotNil(studentDictionary, @"no student dictionary created");
		
		XCTAssertTrue([[studentToCheck id_number]isEqualToString:@"01-210-57025"], @"id_number does not match");
		XCTAssertTrue([[studentToCheck exportid]isEqualToString:@"01-210-57025"], @"exportid does not match");
		XCTAssertTrue([[studentToCheck student]isEqualToString:@"01-210-57025"], @"student does not match");
		XCTAssertTrue([[studentToCheck last_name]isEqualToString:@"GO SOCIETY"], @"last_name does not match");
		XCTAssertTrue([[studentToCheck accnt_type]isEqualToString:@"D"], @"accnt_type does not match");
		
		XCTAssertEqual([[studentToCheck area_1] doubleValue], 0.0, @"area_1 does not match");
		XCTAssertEqual([[studentToCheck area_2] doubleValue], 0.0, @"area_2 does not match");
		XCTAssertEqual([[studentToCheck area_3] doubleValue], 0.0, @"area_3 does not match");
		XCTAssertEqual([[studentToCheck area_4] doubleValue], 0.0, @"area_4 does not match");
		XCTAssertEqual([[studentToCheck area_5] doubleValue], 0.0, @"area_5 does not match");
		XCTAssertEqual([[studentToCheck area_6] doubleValue], 0.0, @"area_6 does not match");
		XCTAssertEqual([[studentToCheck area_7] doubleValue], 0.0, @"area_7 does not match");
		XCTAssertEqual([[studentToCheck area_8] doubleValue], 0.0, @"area_8 does not match");
		XCTAssertEqual([[studentToCheck area_9] doubleValue], 0.0, @"area_9 does not match");
		XCTAssertEqual([[studentToCheck present] doubleValue], 0.0, @"present does not match");
		
		XCTAssertTrue([[studentToCheck time_1]isEqualToString:@"N"], @"time_1 does not match");
		XCTAssertTrue([[studentToCheck time_2]isEqualToString:@"N"], @"time_2 does not match");
		XCTAssertTrue([[studentToCheck time_3]isEqualToString:@"D"], @"time_3 does not match");
		XCTAssertTrue([[studentToCheck time_4]isEqualToString:@"W"], @"time_4 does not match");
		XCTAssertTrue([[studentToCheck time_5]isEqualToString:@"T"], @"time_5 does not match");
		XCTAssertTrue([[studentToCheck time_6]isEqualToString:@"N"], @"time_6 does not match");
		XCTAssertTrue([[studentToCheck time_7]isEqualToString:@"N"], @"time_7 does not match");
		XCTAssertTrue([[studentToCheck time_8]isEqualToString:@"N"], @"time_8 does not match");
		XCTAssertTrue([[studentToCheck time_9]isEqualToString:@"N"], @"time_9 does not match");
	}
}

- (NSArray *) createItemReturn
{
	NSString *itemReturn = @"[{\"serial\":\"no device\",\"friendly\":\"Test\",\"location\":2,\"plu\":\"TEST\",\"item\":\"Test Item\",\"glcode\":999,\"qty\":1,\"amount\":20,\"allow_qty\":1,\"allow_amount\":1,\"chk_balance\":1,\"lock_cfg\":1,\"allow_edit\":1,\"allow_manual_id\":1,\"allow_stock\":0,\"stock_name\":\"stock\",\"school\":\"test\"}]";
	
	NSArray *itemArray = [itemReturn JSONValue];
	return itemArray;
}

- (void) testItemInput
{
	NSArray *itemArray = [self createItemReturn];
	NSDictionary *itemAsDictionary = [itemArray objectAtIndex:0];
	OdinEvent *itemBeingDownloaded = [CoreDataHelper insertObjectForEntity:@"OdinEvent" andContext:ctx];
	itemBeingDownloaded = [itemBeingDownloaded loadValuesFromDictionaryRepresentation:itemAsDictionary];	
	
	XCTAssertTrue(([[itemBeingDownloaded location] intValue] == 2), @"location did not load");
	XCTAssertTrue(([[itemBeingDownloaded glcode] intValue] == 999), @"description did not load");
	XCTAssertTrue(([[itemBeingDownloaded amount] intValue] == 20), @"amount did not load");
	XCTAssertTrue(([[itemBeingDownloaded qty] intValue] == 1), @"qty did not load");
	
	XCTAssertTrue(([[itemBeingDownloaded allow_amount] boolValue] == TRUE), @"allow_amount did not load");
	XCTAssertTrue(([[itemBeingDownloaded allow_qty] boolValue] == TRUE), @"allow_qty did not load");
	XCTAssertTrue(([[itemBeingDownloaded chk_balance] boolValue] == TRUE), @"chk_balance did not load");
	XCTAssertTrue(([[itemBeingDownloaded lock_cfg] boolValue] == TRUE), @"lock_cfg did not load");
	XCTAssertTrue(([[itemBeingDownloaded allow_edit] boolValue] == TRUE), @"allow_edit did not load");
	XCTAssertTrue(([[itemBeingDownloaded allow_manual_id] boolValue] == TRUE), @"allow_manual_id did not load");
	XCTAssertTrue(([[itemBeingDownloaded allow_stock] boolValue] == FALSE), @"allow_stock did not load");	
	
	XCTAssertTrue([[itemBeingDownloaded operator] isEqualToString:@"Test"], @"operator did not load properly");
	XCTAssertTrue([[itemBeingDownloaded plu] isEqualToString:@"TEST"], @"plu did not load");
	XCTAssertTrue([[itemBeingDownloaded school] isEqualToString:@"test"], @"school did not load");
	XCTAssertTrue([[itemBeingDownloaded stock_name] isEqualToString:@"stock"], @"plu did not load");
}


-(void)testAFN
{
	NSDictionary *requestParams = nil;
	
	//plu is optional, add to parameters if it exists
	
	//[requestParams setValue:@"VALHALLA" forKey:@"uid"];
	//[requestParams setValue:@"MSC120995UN11" forKey:@"serial"];
	//[requestParams setValue:[NSNumber numberWithBool:0] forKey:@"MSSQL"];
	[requestParams setValue:@"65bdd204-aff0-11e1-b86a-22000a1ca8d5" forKey:@"uid"];
	
	__block int responseCode = 0;
	__block NSArray* responseArray = nil;
	//AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
	NSURL* baseURL = [NSURL URLWithString:@"http://54.163.92.33/isapi/MKService.dll/wsdl/imks"];
	AFHTTPRequestOperationManager* manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
	manager.requestSerializer = [AFJSONRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
	manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	[manager POST:@"Items" parameters:requestParams
		  success:^(AFHTTPRequestOperation *task, id responseObject) {
			  NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
			  
			  responseArray = [responseString JSONValue];
#ifdef DEBUG
			  NSLog(@"Item Download: %@",[responseArray description] );
#endif
			  responseCode = [task.response statusCode];
			  
			  dispatch_semaphore_signal(semaphore);
			  
			  //NSMutableDictionary *itemResponseJSONasString = response;
			  //itemResponseArray = [itemResponseJSONasString allValues];
		  }
	 
		  failure:^(AFHTTPRequestOperation *task, NSError *error) {
			  
#ifdef DEBUG
			  NSLog(@"ITEM-ERROR %@", error);
#endif
			  responseCode = [task.response statusCode];
			  
			  //dispatch_semaphore_signal(semaphore);
		  }];
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}



@end

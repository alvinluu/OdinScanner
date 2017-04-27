//
//  Test.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/9/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "TestIf.h"
#import "SynchronizationOperation.h"
//#import "OdinEvent.h"
//#import "OdinTransaction.h"
#import "OdinStudent.h"
//#import "AuthenticationStation.h"
#import "CartItem.h"
#import "NSArray+Ext.h"

@implementation TestIf
-(double) totalPendingTransactionAmountWithID:(NSString*)idNumber {
    double pendingBalance = 0.0;
    NSArray *pendingTransactionsForStudent = [CoreDataService
                                              searchObjectsForEntity:@"OdinTransaction"
                                              withPredicate:[NSPredicate predicateWithFormat:@"id_number = %@ AND sync = false",idNumber]
                                              andSortKey:nil
                                              andSortAscending:NO
                                              andContext:[CoreDataService getMainMOC]];
    
    
    for (OdinTransaction *transaction in pendingTransactionsForStudent)
    {
        pendingBalance += transaction.amount.doubleValue;
    }
    
    
    return pendingBalance;
}
/*
 * Check student has enough funds after deducting pending transaction
 * It doesn't retrieve online fund
 */
+(BOOL) account:(NSDictionary *)student canPurchaseItem:(OdinEvent *)theItem forAmount:(NSNumber *)amount 
{
	if (!student) return FALSE;
	
#ifdef DEBUG
	NSLog(@"testif item %@",theItem.plu);
#endif
	NSString *idNumber = [student objectForKey:@"id_number"];
#ifdef DEBUG
	NSLog(@"testif id_number:%@ name:%@ %@",idNumber,[student objectForKey:@"student"], [student objectForKey:@"last_name"]);
#endif
	
	//Checks balance and restriction
	if ([theItem.chk_balance boolValue] == TRUE)
    {
        TestIf* testif = [[TestIf alloc] init];
        return [testif account:student canAffordAmounts:amount];
	}
	return YES;
}


+(BOOL) account:(NSDictionary *)student canPurchaseCart:(NSArray *)items forAmounts:(NSArray *)amounts moc:(NSManagedObjectContext*)moc
{
	if (!student) return FALSE;
	
#ifdef DEBUG
	NSLog(@"CanPurchaseCart %@",items);
#endif
    if ([items hasCheckBalanceInCart]) {
        
        TestIf* testif = [[TestIf alloc] init];
        return [testif account:student canAffordAmounts:[items totalAmountInCart]];
        
    }
    return true;
}

-(BOOL) account:(NSDictionary *)student canAffordAmounts:(NSNumber *)amount
{
    
    //removes amount of any pending transactions from available balance
    NSString *idNumber = [student objectForKey:@"id_number"];
    NSNumber *studentBalanceNumber = [student objectForKey:@"present"];
    NSNumber *thresholdNumber = [student objectForKey:@"threshold"];
    double charge = amount.doubleValue;
    double studentBalance = studentBalanceNumber.doubleValue;
    double threshold = thresholdNumber.doubleValue;
#ifdef DEBUG
    NSLog(@"student present %.2f amount %.2f",studentBalance,charge);
#endif
    TestIf* testif = [[TestIf alloc] init];
    //subtract pending balance from student's current balance
    studentBalance -= [self totalPendingTransactionAmountWithID:idNumber];
    
    //add threshold
    studentBalance += (-1 * threshold);
#ifdef DEBUG
    NSLog(@"student %.2f amount %.2f",studentBalance,charge );
#endif
    return (studentBalance >= charge);
    
    return false;
}

/*
 * removes amount of any pending transactions from available balance
 */
+(double)studentOfflineBalanceWithID:(NSString*)idNumber
{
    
    OdinStudent* student = [OdinStudent getStudentByIDnumber:idNumber];
    double studentBalance = student.present.doubleValue;
#ifdef DEBUG
    NSLog(@"student has balance %.2f",studentBalance);
#endif

    //subtract pending balance from student's current balance
    TestIf* testif = [[TestIf alloc] init];
    studentBalance -=  [testif totalPendingTransactionAmountWithID:idNumber];
#ifdef DEBUG
    NSLog(@"student new balance %.2f",studentBalance);
#endif
    return studentBalance;
}
//sends a quick get to the portable path, returns "YES" on http:200, "NO" on any other return code
+(NSArray*)appCanUseSchoolServerAFN
{
	
	__block NSArray* responseArray = [[NSArray alloc]init];
	
	if ([NetworkConnection isInternetOffline] || [[AuthenticationStation sharedHandler] isScannerDeactive]) {
		return responseArray;
	}
#ifdef DEBUG
	NSLog(@"run appCanUseSchoolServer");
#endif
	
	__block int responseCode = 0;
	__block BOOL weCanReachServer = NO;
	
	NSDictionary *requestParams = [WebService getDefaultParametersWithSync:true];
	
	
	AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
#ifdef DEBUG
	NSLog(@"CanUseSchoolServer param: %@ at address %@",requestParams,manager.baseURL);
#endif
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    manager.securityPolicy.allowInvalidCertificates = true;
    manager.securityPolicy.validatesDomainName = false;
	[manager POST:@"OdinAuth" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
#ifdef DEBUG
              NSLog(@"auth connected");
#endif
			  weCanReachServer = TRUE;
              NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
              
              responseArray = [[NSArray alloc] initWithObjects:@{@"response_code":[NSString stringWithFormat:@"%i",200],
                                                                 @"response_error":@"connected",
                                                                 @"response_string":responseString},
                               
                               nil];
              dispatch_semaphore_signal(semaphore);
          }
	 
		  failure:^(AFHTTPRequestOperation *task, NSError *error) {
			  
#ifdef DEBUG
			  NSLog(@"SERVER-ERROR %@", error);
#endif
			  
			  //[self noSeverConnection];
			  /*responseCode = [task.response statusCode];
			  NSString * suffix = [NSString stringWithFormat:@"%i",count];
			  NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			  NSString * message = [NSString stringWithFormat:@"%@ Attempt with Code: %i\nConnecting...",[suffix convertToNumberSuffix], responseCode];
			  [userInfo setObject:message forKey:@"errorMsg"];
			  [[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Status" object:self userInfo:userInfo];
			  */
              
              id responseObject = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
              NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
              
			  responseArray = [[NSArray alloc] initWithObjects:@{@"response_code":[NSString stringWithFormat:@"%ld",(long)[task.response statusCode]],
																 @"response_error":error,
                                                                 @"response_string":responseString},
							   nil];
			  
			  //[WebService stayHereTillResponse:semaphore];
			  dispatch_semaphore_signal(semaphore);
              
              [WebService postError:@{@"error":@"Testif Odin Auth",@"message":error.description}];
		  }];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	//} while ([AuthenticationStation sharedHandler].isStudentConnectionRetry);
	
#ifdef DEBUG
	NSLog(@"done %@",[responseArray description]);
#endif
	
//	if ([WebService getAuthStatus] && weCanReachServer)
//	{
//		weCanReachServer = YES;
//	} else
//		weCanReachServer = NO;
	return responseArray;
	//return [AuthenticationStation sharedHandler].responseData;
}
+(BOOL) appIsSynchronized
{
	BOOL isSynchronized = [[AuthenticationStation sharedHandler] isAuthenticated];
    
	return isSynchronized;
}

//checks if the transaction can be deleted
+(BOOL) canDeleteTransaction:(OdinTransaction *)transaction
{
	NSArray *possibleItems = [CoreDataService searchObjectsForEntity:@"OdinEvent"
													  withPredicate:[NSPredicate predicateWithFormat:@"plu == %@",transaction.plu]
														 andSortKey:nil
												   andSortAscending:NO
														 andContext:[CoreDataService getMainMOC]];
#ifdef DEBUG
	NSLog(@"items found with matching PLU: %lu", (unsigned long)[possibleItems count]);
#endif
	//[StreamInOut writeLogFileWithTransaction:[transaction preppedForWeb] Note:@"Delete Pending Transaction" ];
	//[StreamInOut deletePendingItemInFileWithTransaction:[transaction preppedForWeb]];
	
	if ([possibleItems count] >= 1)
	{
		OdinEvent *currentItemType = [possibleItems objectAtIndex:0];
        /* compare item name when there are item share PLU */
        if (possibleItems.count > 1) {
            for (OdinEvent* i in possibleItems) {
                if ([i.item isEqualToString:transaction.item]) {
                    currentItemType = i;
                    break;
                }
            }
        }
		//can't be deleted if it's already been uploaded
		if ([transaction.sync boolValue] == TRUE)
		{
			//[ErrorAlert synchedAlert];
			return NO;
		}
		//can't be deleted if "allow_edit" is false
		else if ([currentItemType.allow_edit boolValue] == FALSE)
		{
			//[ErrorAlert cannotEditItem:@"transactions"];
			return NO;
		}
	}
	return YES;
}

+(void) noSeverConnection
{
	[SettingsHandler sharedHandler].isAlertDisplay = NO;
	//[ErrorAlert noSeverConnection];
}


@end

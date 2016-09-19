//
//  WebServiceASFHTTP.m
//  OdinScanner
//
//  Created by Ben McCloskey on 5/1/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "WebServiceASFHTTP.h"
//#import "AuthenticationStation.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"
#import "NSString+hackXML.h"

@interface WebServiceASFHTTP ()

+(NSDictionary *)addDefaultParamsTo:(NSDictionary *)requestParams;
+(NSDictionary *)getDefaultParameters;
+(NSMutableData *)bodyAsJSONDataFromDict:(NSDictionary *)postParams;
+(ASIFormDataRequest *)createPOSTRequestWithResource:(NSString *)resourceComponent andParams:(NSDictionary *)postParams;

+(NSArray *)itemFetchMiddleman:(NSString *)plu;
+(NSArray *)studentFetchMiddleman:(NSString *)id_number;
@end

@implementation WebServiceASFHTTP

+(NSDictionary *)getDefaultParameters
{
	return [WebServiceASFHTTP addDefaultParamsTo:nil];
}

//adds the 3 default parameters that must be included in any web request to a given dictionary of parameters
+(NSDictionary *)addDefaultParamsTo:(NSDictionary *)requestParams
{
	if (requestParams == nil)
		requestParams = [[NSDictionary alloc] init];
	
	//get values for 3 default parameters
	NSString *uid = [[SettingsHandler sharedHandler] uid];
	NSString *serial = [[AuthenticationStation sharedAuth] getSerialNumber];
	BOOL MSSQL = [[SettingsHandler sharedHandler] isMSSQL];
	
	//create mutable dictionary and import parameters (if any)
	NSMutableDictionary *paramDict = [requestParams mutableCopy];
	
	//add the 3 default parameters
	[paramDict setValue:uid forKey:@"uid"];
	[paramDict setValue:serial forKey:@"serial"];
	[paramDict setValue:[NSNumber numberWithBool:MSSQL] forKey:@"MSSQL"];
	
	
	return [NSDictionary dictionaryWithDictionary:paramDict];
}

//turns dictionary of parameters to be POSTed and turns it into NSData in JSON format for the POSTing
+(NSMutableData *)bodyAsJSONDataFromDict:(NSDictionary *)postParams
{
	NSString *paramsAsJSON = [postParams JSONRepresentation];
	NSMutableData *paramsAsMutableData = [NSMutableData dataWithData:[paramsAsJSON dataUsingEncoding:NSUTF8StringEncoding]];
#ifdef DEBUG 
	NSLog(@"POST body: %@",paramsAsJSON);
#endif
	return paramsAsMutableData;
}

+(ASIFormDataRequest *)createPOSTRequestWithResource:(NSString *)resourceComponent andParams:(NSDictionary *)postParams
{
	//create NSURL resource to initiate request (based on compoenent passed in)
	NSURL *resource = [[[AuthenticationStation sharedAuth] portableServicePath] URLByAppendingPathComponent:resourceComponent];
#ifdef DEBUG
	NSLog(@"POSTing to %@",[resource description]);
#endif
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:resource];
	[request setRequestMethod:@"POST"];
	//we use self-signed SSL certificates
	[request setValidatesSecureCertificate:NO];
	[request setTimeOutSeconds:15];
	
	postParams = [WebServiceASFHTTP addDefaultParamsTo:postParams];
	
#ifdef DEBUG
	NSLog(@"POSTing param %@",[postParams description]);
#endif
	//[[SettingsHandler sharedHandler] setIsAlertDisplay:NO];
	[request setPostBody:[WebServiceASFHTTP bodyAsJSONDataFromDict:postParams]];
	
	return request;
}

+ (NSDictionary *)getAuthStatus
{
	//does not use default since it goes to Odin server always
    NSURL *authResource = [[[SettingsHandler sharedHandler] basePath] URLByAppendingPathComponent:@"OdinAuth"];
	
	
	ASIFormDataRequest *authRequest = [ASIFormDataRequest requestWithURL:authResource];
	[authRequest setRequestMethod:@"POST"];
	[authRequest setValidatesSecureCertificate:NO];
	//send default POST values
	[authRequest setPostBody:[WebServiceASFHTTP bodyAsJSONDataFromDict:[self getDefaultParameters]]];
	
	//execute request
    [authRequest setDelegate:self];
    [authRequest startSynchronous];
	
	//TODO:more stuff here to handle HTTP status codes?
	//currently bails if any code other than 200:OK
	
	
	
#ifdef DEBUG
	//NSLog(@"HTTP:%@",[authRequest responseStatusCode]);
#endif
	if ([authRequest responseStatusCode] != 200)
	{
		return nil;
	}
	
	NSString *returnedJSON = [authRequest responseString];
	if ([returnedJSON isEqualToString:@"Not Authenticated"])
	{
		return nil;
	}
	
    NSDictionary *responseDict = [returnedJSON JSONValue];	

#ifdef DEBUG
	NSLog(@"returned Auth Info:%@",[responseDict description]);
	NSLog(@"server detail :%@",[responseDict objectForKey:@"server"]);
#endif
	
    return responseDict;
}

//returns list of all items for this device as NSArray
+ (NSArray *)fetchItemList
{
	return [self itemFetchMiddleman:nil];
}

//sends PLU to web service, web service sends back matching item as NSDictionary
+ (NSDictionary *)fetchItemWithPLU:(NSString *)plu
{
	//middleman gives back an array, we return the first dictionary in the array
	//(should only be one item in array, so log an error if there are more than one)
	NSArray *itemArray = [self itemFetchMiddleman:plu];
	
#ifdef DEBUG
	if ([itemArray count] > 1)
		NSLog(@"ERROR: Multiple items returned with same PLU, returning only the first");	
#endif
	
	return [itemArray objectAtIndex:0];
}

//does the shared heavy lifting for preceding two methods
+(NSArray *)itemFetchMiddleman:(NSString *)plu;
{	
	NSDictionary *requestParams = nil;
	
	//plu is optional, add to parameters if it exists
    if (plu != nil)
		requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:plu,@"plu",nil];
	
	int responseCode = 0;
	int count = 0;
	
	//create Request and start it
	ASIFormDataRequest *itemRequest;
	itemRequest = [WebServiceASFHTTP createPOSTRequestWithResource:@"Items" andParams:requestParams];
	[itemRequest setDelegate:self];
	
	do {
		
		[itemRequest startSynchronous];
		
		NSLog(@"itemFetchMiddleman responseCode: %i", [itemRequest responseStatusCode]);
		//NSLog(@"studentFetchBody %@", [studentRequest responseString]);
		//TODO:more stuff here to handle HTTP status codes?
		responseCode = [itemRequest responseStatusCode];
		
		if (responseCode != 200) {
			
			//[ErrorAlert noStudentConnection];
			//TODO:add a alert for user to retry or cancel connection
			
			[self noItemConnection];
			
			NSString * suffix = [NSString stringWithFormat:@"%i",count];
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			NSString * message = [NSString stringWithFormat:@"%@ Attempt with Code: %i\nConnecting...",[suffix convertToNumberSuffix], responseCode];
			[userInfo setObject:message forKey:@"errorMsg"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Status" object:self userInfo:userInfo];
			
			//Stay here until user response to noItemConnection Alert
			[self stayHereTillResponse];
			
		} else {
			if ([AuthenticationStation sharedAuth].isSyncing) {
				NSString * suffix = [NSString stringWithFormat:@"%i",count];
				NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
				NSString * message = [NSString stringWithFormat:@"%@ Attempt with Code: %i\nConnected",[suffix convertToNumberSuffix], responseCode];
				[userInfo setObject:message forKey:@"errorMsg"];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Status" object:self userInfo:userInfo];
			}
		}
		
		count++;
	} while ([AuthenticationStation sharedAuth].isStudentConnectionRetry && responseCode != 200);
	
	
	if ([itemRequest responseStatusCode] != 200)
	{
		NSString *title = [NSString stringWithFormat:@"Unable to fetch items"];
		NSString *message =[NSString stringWithFormat:@"No connection established to retrieve items from %@",[itemRequest url]];
		[UIAlertView showBasicAlertWithTitle:title andMessage:message];
		return nil;
	}
	
	NSString *itemResponseJSONasString = [itemRequest responseString];
    NSArray *itemResponseArray = [itemResponseJSONasString JSONValue];
	
	return itemResponseArray;
}


+ (NSDictionary *)fetchRegisterItemWithBarcode:(NSString *)barcode
{
	
	NSDictionary *requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:TRUE],@"register",barcode,@"barcode",nil];
	requestParams = [self addDefaultParamsTo:requestParams];
	
	ASIFormDataRequest *itemRequest;
	
	itemRequest = [WebServiceASFHTTP createPOSTRequestWithResource:@"Items" andParams:requestParams];
	[itemRequest setDelegate:self];
	[itemRequest startSynchronous];
	
	//TODO:more stuff here to handle HTTP status codes?
	
	int	responseCode = [itemRequest responseStatusCode];
	
	if (responseCode != 200)
	{
		NSString *title = [NSString stringWithFormat:@"Unable to fetch register items"];
		NSString *message =[NSString stringWithFormat:@"No connection established to retrieve items with barcode from %@",[itemRequest url]];
		[UIAlertView showBasicAlertWithTitle:title andMessage:message];
		return nil;
	}
	
	NSString *itemResponseJSONasString = [itemRequest responseString];
    NSDictionary *itemResponseDictionary = [itemResponseJSONasString JSONValue];
	
	return itemResponseDictionary;
	
}

//returns list of all items for this device as NSArray
+ (NSArray *)fetchStudentList
{
	
#ifdef DEBUG
	NSLog(@"fetchStudentList");
#endif
	
	return [self studentFetchMiddleman:nil];
}

//does the shared heavy lifting for preceding two methods
+(NSArray *)studentFetchMiddleman:(NSString *)id_number
{
	
#ifdef DEBUG
	NSLog(@"studentFetchMiddleman with id: %@", id_number);
#endif
	//Don't check any student if it is waiting for user to respond for Alert
	if ([AuthenticationStation sharedAuth].isStudentConnectionRetry) {
		return nil;
	}
	
	//quit if there is no connection
	if ([[AuthenticationStation sharedAuth] isOnline] == FALSE)
	{
		[ErrorAlert noInternetConnection];
		return nil;
	}
	
	
	NSDictionary *requestParams = nil;
	
	//ID Number is optional, add to parameters if it exists to search for a particular ID
	//if ID is nil, the WebServiceASFHTTP will return all students
    if (id_number != nil)
		requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:id_number,@"id_number",nil];
	
	//create Request
	ASIFormDataRequest *studentRequest;
	
	int responseCode = 0;
	int count = 1;
	
	
	do {
		
		//create Request and start it
		studentRequest = [WebServiceASFHTTP createPOSTRequestWithResource:@"Students" andParams:requestParams];
		
		[studentRequest setDelegate:self];
		[studentRequest startSynchronous];
		
		NSLog(@"studentFetchMiddleman responseCode: %i", [studentRequest responseStatusCode]);
		//NSLog(@"studentFetchBody %@", [studentRequest responseString]);
		//TODO:more stuff here to handle HTTP status codes?
		responseCode = [studentRequest responseStatusCode];
		
		if (responseCode != 200) {
			
			//TODO:add a alert for user to retry or cancel connection
			NSLog(@"error in responseCode");
			
			NSString * suffix = [NSString stringWithFormat:@"%i",count];
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			NSString * message = [NSString stringWithFormat:@"%@ Attempt with Code: %i\nConnecting...",[suffix convertToNumberSuffix], responseCode];
			[userInfo setObject:message forKey:@"errorMsg"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Status" object:self userInfo:userInfo];
			
			[self noStudentConnectionWithID: id_number];
			//Stay here until user response to noStudentConnection Alert
			
			[self stayHereTillResponse];
		} else {
			if ([AuthenticationStation sharedAuth].isSyncing) {
				NSString * suffix = [NSString stringWithFormat:@"%i",count];
				NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
				NSString * message = [NSString stringWithFormat:@"%@ Attempt with Code: %i\nConnected",[suffix convertToNumberSuffix], responseCode];
				[userInfo setObject:message forKey:@"errorMsg"];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Status" object:self userInfo:userInfo];
			}
		}
		
#ifdef DEBUG
		NSLog(@"fetching Middle %i tries %i", count, responseCode);
#endif
		count++;
	} while ([AuthenticationStation sharedAuth].isStudentConnectionRetry && responseCode != 200);
	
		
	if ([studentRequest responseStatusCode] != 200)
	{
		if (([studentRequest responseStatusCode] == 204)
			&& (id_number != nil))
		{
			if ([[AuthenticationStation sharedAuth] isScannerDeactive]) {
				[ErrorAlert noScannerToOfflineMode];
			} else
			{
#ifdef DEBUG
				[ErrorAlert studentNotFound:id_number];
#endif
			}
			return nil;
		}
		else
		{
			//leave connection online if the device is connected
			if ([[AuthenticationStation sharedAuth] isScannerDeactive]) {
				[ErrorAlert noScannerToOfflineMode];
				[[AuthenticationStation sharedAuth] setIsOnline:NO];
				return nil;
			} else
			{
#ifdef DEBUG
				[ErrorAlert studentNotFetch:id_number];
#endif
			}
		}
	}
	[AuthenticationStation sharedAuth].isStudentConnectionRetry = NO;
	
	
	NSString *studentResponseJSONString = [studentRequest responseString];

    NSArray *studentResponseArray = [studentResponseJSONString JSONValue];
	
    NSDictionary *responseDict = [studentResponseJSONString JSONValue];
#ifdef DEBUG
	//NSLog(@"Authing to:%@ with POST Data:",[studentRequest responseString]);
#endif
	return studentResponseArray;
}

//sends PLU to web service, web service sends back matching item as NSDictionary
+ (NSDictionary *)fetchStudentWithID:(NSString *)id_number
{
	NSArray *studentArray = [self studentFetchMiddleman:id_number];
	
	if ([studentArray isKindOfClass:[NSDictionary class]])
	{
		NSDictionary *studentDict = (NSDictionary *)studentArray;
		return studentDict;
	}
	else if ([studentArray count] > 1)
	{
#ifdef DEBUG 
		NSLog(@"ERROR: Multiple students returned with ID %@, returning only the first",id_number);
#endif
	}
	else if ([studentArray count] <= 0)
		return nil;
	
	return [studentArray objectAtIndex:0];
}

//Sends account type to service, returns information from accntype
+ (NSDictionary *)fetchDataForAccountType:(NSString *)accnt_type
{	
	NSDictionary *requestParams = [NSDictionary dictionaryWithObjectsAndKeys:accnt_type, @"accnt_type", nil];
	
	ASIFormDataRequest *accntTypeRequest = [WebServiceASFHTTP createPOSTRequestWithResource:@"AccountType" andParams:requestParams];	
	
	[accntTypeRequest setDelegate:self];
	[accntTypeRequest startSynchronous];
	
	if ([accntTypeRequest responseStatusCode] != 200)
		return nil;
	
	NSString *accntResponseJSONString = [accntTypeRequest responseString];	
    NSArray *accntResponseArray = [accntResponseJSONString JSONValue];
	
	if ([accntResponseArray count] == 0)
		return nil;
	
	if ([accntResponseArray count] != 1)
	{
#ifdef DEBUG 
		NSLog(@"ERROR: Multiple values returned, defaulting to the first");
#endif
	}	
	return [accntResponseArray objectAtIndex:0];
}
//+ (NSString*)loadTransactionLogFile
//{
//	//create NSURL resource to initiate request (based on compoenent passed in)
//	NSURL *resource = [[[AuthenticationStation sharedAuth] portableServicePath] URLByAppendingPathComponent:@"TransactionLogLoad"];
//#ifdef DEBUG
//	NSLog(@"GETing to %@",[resource description]);
//#endif
//	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:resource];
//	[request setRequestMethod:@"POST"];
//	//we use self-signed SSL certificates
//	[request setValidatesSecureCertificate:NO];
//	[request setTimeOutSeconds:15];
//	
//	NSString *postBody = @"";
//	//convert NSString to NSMutableData
//	NSData *data = [postBody dataUsingEncoding:NSUTF8StringEncoding];
//	NSMutableData *body = [data mutableCopy];
//	[request setPostBody:body];
//	
//	[request setDelegate:self];
//	[request startSynchronous];
//	[AuthenticationStation sharedAuth].isPosting = FALSE;
//	if ([request responseStatusCode] == 200)
//	{
//#ifdef DEBUG
//		NSLog(@"SUCCESS load device transcation log file from PHP server");
//		NSLog(@"data: %@",[request responseString]);
//#endif
//		return [request responseString];
//	}
//	else
//	{
//#ifdef DEBUG
//		NSLog(@"FAILED load device transcation log file from PHP server");
//		NSLog(@". bad code %i ITEM:%@ MSG:%@",[request responseStatusCode],[request responseStatusMessage],[request responseString]);
//#endif
//		return nil;
//	}
//}
//+ (BOOL)postTransactionLogFile
//{
//	//TODO:save TransactionLogFile
//	
//	//NSData *transactionForDictionary = [[transaction JSONRepresentation] JSONValue];
//	//NSDictionary *requestParams = [NSDictionary dictionaryWithObjectsAndKeys:transactionForDictionary,@"transaction", nil];
//	//[self loadTransactionLogFile];
//	
//	
//	NSManagedObjectContext *managedObjectContext = [CoreDataHelper getMainMOC];
//	NSMutableArray *transactArray = [CoreDataHelper searchObjectsForEntity:@"OdinTransaction"
//															 withPredicate:[NSPredicate predicateWithFormat:@"sync == false || sync == true"]
//																andSortKey:@"timeStamp"
//														  andSortAscending:NO
//																andContext:managedObjectContext];
//	NSString *curTrans = @"";
//	for (OdinTransaction *transaction in transactArray)
//	{
//		curTrans = [curTrans stringByAppendingFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
//					[transaction amount]?[transaction amount]:@"",
//					[transaction dept_code]?[transaction dept_code]:@"",
//					[transaction glcode]?[transaction glcode]:@"",
//					[transaction id_number]?[transaction id_number]:@"",
//					[transaction item]?[transaction item]:@"",
//					[transaction location]?[transaction location]:@"",
//					[transaction operator]?[transaction operator]:@"",
//					[transaction payment]?[transaction payment]:@"",
//					[transaction plu]?[transaction plu]:@"",
//					[transaction qdate]?[transaction qdate]:@"",
//					[transaction qty]?[transaction qty]:@"",
//					[transaction reference]?[transaction reference]:@"",
//					[transaction school]?[transaction school]:@"",
//					[transaction sync]?[transaction sync]:@"",
//					[transaction tax_amount]?[transaction tax_amount]:@"",
//					[transaction time]?[transaction time]:@"",
//					[transaction timeStamp]?[transaction timeStamp]:@""
//					];
//	}
//    
//#ifdef DEBUG
//	NSLog(@"transactArray %@", curTrans);
//#endif
//	
//	ASIFormDataRequest *transactionPostRequest = [WebServiceASFHTTP createPOSTRequestWithResource:@"TransactionLogWrite" andBody:curTrans];
//	
//	[transactionPostRequest	setDelegate:self];
//	[transactionPostRequest startSynchronous];
//	[AuthenticationStation sharedAuth].isPosting = FALSE;
//	if ([transactionPostRequest responseStatusCode] == 200)
//	{
//#ifdef DEBUG
//		NSLog(@"SUCCESS write device transcation log file to PHP server");
//#endif
//		return TRUE;
//	}
//	else
//	{
//#ifdef DEBUG
//		NSLog(@"FAILED write device transcation log file to PHP server. bad code %i ITEM:%@ MSG:%@",[transactionPostRequest responseStatusCode],[transactionPostRequest responseStatusMessage],[transactionPostRequest responseString]);
//#endif
//		return FALSE;
//	}
//}
+ (BOOL)postUploadedTransaction:(NSDictionary *)transaction
{
	[AuthenticationStation sharedAuth].isPosting = TRUE;
	
	NSDictionary * tran = [NSDictionary dictionaryWithDictionary:transaction];
	
	NSData *transactionForDictionary = [[tran JSONRepresentation] JSONValue];
	
	NSDictionary *requestParams = [NSDictionary dictionaryWithObjectsAndKeys:transactionForDictionary,@"transaction", nil];
	
#ifdef DEBUG
	NSLog(@"POST uploaded transaction: %@",[requestParams description]);
#endif
	
	ASIFormDataRequest *transactionPostRequest = [WebServiceASFHTTP createPOSTRequestWithResource:@"TransactionUploaded" andParams:requestParams];
	
	[transactionPostRequest	setDelegate:self];
	[transactionPostRequest startSynchronous];
	[AuthenticationStation sharedAuth].isPosting = FALSE;
	if ([transactionPostRequest responseStatusCode] == 200)
	{
		return TRUE;
	}
	else
	{
#ifdef DEBUG
		NSLog(@"bad code %i ITEM:%@ MSG:%@",[transactionPostRequest responseStatusCode],[transactionPostRequest responseStatusMessage],[transactionPostRequest responseString]);
#endif
		return FALSE;
	}
}
//posts a transaction, and updates student table (along with stock table for "local" builds)
//returns false on any errors
+ (BOOL)postTransaction:(NSDictionary *)transaction
{
	[AuthenticationStation sharedAuth].isPosting = TRUE;
	
	NSData *transactionForDictionary = [[transaction JSONRepresentation] JSONValue];
	
	NSDictionary *requestParams = [NSDictionary dictionaryWithObjectsAndKeys:transactionForDictionary,@"transaction", nil];
	
#ifdef DEBUG
	NSLog(@"POST transaction: %@",[requestParams description]);
#endif
	
	ASIFormDataRequest *transactionPostRequest = [WebServiceASFHTTP createPOSTRequestWithResource:@"Transaction" andParams:requestParams];
	
	[transactionPostRequest	setDelegate:self];
	[transactionPostRequest startSynchronous];
	[AuthenticationStation sharedAuth].isPosting = FALSE;
	if ([transactionPostRequest responseStatusCode] == 200)
	{
		return TRUE;
	}
	else
	{
#ifdef DEBUG
		NSLog(@"bad code %i ITEM:%@ MSG:%@",[transactionPostRequest responseStatusCode],[transactionPostRequest responseStatusMessage],[transactionPostRequest responseString]);
#endif
		return FALSE;
	}
}
#pragma mark - Call to Error Alert

+(void) noItemConnection
{
	[AuthenticationStation sharedAuth].isStudentChecking = YES;
	[[SettingsHandler sharedHandler] setIsAlertDisplay:NO];
	[ErrorAlert noItemConnection];
}
+(void) noStudentConnectionWithID: (NSString*)id_number
{
	[AuthenticationStation sharedAuth].isStudentChecking = YES;
	[[SettingsHandler sharedHandler] setIsAlertDisplay:NO];
	[ErrorAlert noStudentConnection:id_number];
}
+(void) stayHereTillResponse
{
	[AuthenticationStation sharedAuth].isLoopingTimer = YES;
	do {
		sleep(2);
		NSLog(@"waiting for user response");
	} while ([AuthenticationStation sharedAuth].isLoopingTimer);
}
@end

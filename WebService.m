//
//  WebService.m
//  OdinScanner
//
//  Created by Ben McCloskey on 5/1/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

/*
 *AFNetworking is having trouble with iOS 6.1.6 or maybe other iOS 6. It is possible iOS6 is not compatible with IIS server.
 */
#import "WebService.h"
#import "AFNetworking.h"
#import "SBJson.h"
#import "HUDsingleton.h"
#import "OdinOperationQueue.h"
#include <sys/sysctl.h>
//#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("7.0")  ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)

//#define iOSVersion7Plus (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
@interface WebService ()

+(NSDictionary *)addDefaultParamsTo:(NSDictionary *)requestParams sync:(BOOL)sync;
//+(NSDictionary *)getDefaultParametersWithSync:(BOOL)sync;
+(NSMutableData *)bodyAsJSONDataFromDict:(NSDictionary *)postParams;
//+(ASIFormDataRequest *)createPOSTRequestWithResource:(NSString *)resourceComponent andParams:(NSDictionary *)postParams;

@end
@implementation WebService

@synthesize responseString;
+(NSDictionary *)getDefaultParametersWithSync:(BOOL)sync
{
    return [WebService addDefaultParamsTo:nil sync:sync];
}

//adds the 3 default parameters that must be included in any web request to a given dictionary of parameters
+(NSDictionary *)addDefaultParamsTo:(NSDictionary *)requestParams sync:(BOOL)sync
{
    if (requestParams == nil)
        requestParams = [[NSDictionary alloc] init];
    SettingsHandler* setting = [SettingsHandler sharedHandler];
    
    //get values for 3 default parameters
    NSString *uid = setting.uid;
    NSString *serial = [AuthenticationStation sharedHandler].serialNumber;
    NSString *OSVersion = [UIDevice currentDevice].systemVersion;
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *deviceType = [UIDevice currentDevice].model;
    NSNumber *idstart = [[NSNumber alloc] initWithInt: setting.idStart];
    NSNumber *idstop = [[NSNumber alloc] initWithInt: setting.idStop];
    NSNumber *isSync = [[NSNumber alloc] initWithBool: sync];
    BOOL MSSQL = setting.isMSSQL;
    
    
    //-get device model
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.machine", model, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    //-end get device model
    
    
    //create mutable dictionary and import parameters (if any)
    NSMutableDictionary *paramDict = [requestParams mutableCopy];
    
    //add the 3 default parameters
    [paramDict setValue:setting.uid forKey:@"uid"];
    [paramDict setValue:serial forKey:@"serial"];
    //    [paramDict setValue:[AuthenticationStation sharedHandler].serialNumber forKey:@"serial"];
    [paramDict setValue:[NSNumber numberWithBool:MSSQL] forKey:@"MSSQL"];
    //    [paramDict setValue:OSName forKey:@"osname"];
    [paramDict setValue:OSVersion forKey:@"osversion"];
    [paramDict setValue:appVersion forKey:@"appversion"];
    [paramDict setValue:deviceModel forKey:@"devicemodel"];
    [paramDict setValue:setting.school forKey:@"school"];
    [paramDict setValue:[NSNumber numberWithBool:[AuthenticationStation sharedHandler].isOnline] forKey:@"onlinemode"];
    [paramDict setValue:[NSNumber numberWithBool:setting.useExportID] forKey:@"exportID"];
    [paramDict setValue:[NSNumber numberWithBool:setting.holdTransactions] forKey:@"holdtran"];
    [paramDict setValue:[NSNumber numberWithBool:setting.useLineaDevice] forKey:@"uselinea"];
    [paramDict setValue:idstart forKey:@"idstart"];
    [paramDict setValue:idstop forKey:@"idstop"];
    [paramDict setValue:isSync forKey:@"isSync"];
    
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
/*+(ASIFormDataRequest *)createPOSTRequestWithResource:(NSString *)resourceComponent andParams:(NSDictionary *)postParams
 {
	//create NSURL resource to initiate request (based on compoenent passed in)
	NSURL *resource = [[[AuthenticationStation sharedHandler] portableServicePath] URLByAppendingPathComponent:resourceComponent];
 #ifdef DEBUG
	NSLog(@"POSTing to %@",[resource description]);
 #endif
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:resource];
	[request setRequestMethod:@"POST"];
	//we use self-signed SSL certificates
	[request setValidatesSecureCertificate:NO];
	[request setTimeOutSeconds:15];
	
	postParams = [WebService addDefaultParamsTo:postParams];
	
 #ifdef DEBUG
	NSLog(@"POSTing param %@",[postParams description]);
 #endif
	//[[SettingsHandler sharedHandler] setIsAlertDisplay:NO];
	[request setPostBody:[WebService bodyAsJSONDataFromDict:postParams]];
	
	return request;
 }*/

+ (NSDictionary *)getAuthStatus
{
    __block NSDictionary *responseDict;
    
    NSDictionary *requestParams = [WebService getDefaultParametersWithSync:false];
    //create Request and start it
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSString* responseString;
    
    [manager POST:@"OdinAuth" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              NSError* error;
              responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
              NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
              
              responseDict = [responseString JSONValue];
              
              dispatch_semaphore_signal(semaphore);
          }
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
#ifdef DEBUG
              NSLog(@"AuthRequest ERROR %@", error);
#endif
//              id responseObject = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
//              responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
              
              
              dispatch_semaphore_signal(semaphore);
              [WebService postError:@{@"error":@"OdinAuth",@"message":error.description}];
          }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    
    //	if (responseString == nil || [responseString isEqualToString:@"Not Authenticated"]) {
    //		return nil;
    //	}
    
    
    
#ifdef DEBUG
    NSLog(@"returned Auth Info:%@",[responseDict description]);
    NSLog(@"server detail :%@",[responseDict objectForKey:@"server"]);
#endif
    
    return responseDict;
}

/*
 *Download reference number based on Scanner Serial. If the scanner device break, the possible way to use reference coutinously is by having the same
 *operator (portable id), since operator is retrieve by serial.
 */
+(int) fetchReferenceNumberAFN
{
    NSDictionary *requestParams = [self getDefaultParametersWithSync:true];
    
    
    __block int responseCode = 0;
    __block NSString* referenceString = nil;
    int count = 0;
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    
#ifdef DEBUG
    NSLog(@"request fetchReferenceNumberAFN param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [manager POST:@"Reference" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              NSError* error;
              NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
#ifdef DEBUG
              NSLog(@"downloaded String: %@", responseString);
#endif
              
              NSDictionary* json = ([responseString isEqualToString:@""]) ? @{@"reference" : @"I 0"} : [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
              
              
#ifdef DEBUG
              NSLog(@"Reference Download: %@",[json description] );
#endif
              responseCode = [task.response statusCode];
              
              referenceString = [json objectForKey:@"reference"];
              referenceString = [referenceString substringFromIndex:2];
              
              dispatch_semaphore_signal(semaphore);
              
          }
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
#ifdef DEBUG
              NSLog(@"REFERENCE-ERROR %@", error);
#endif
              
              NSString *title = [NSString stringWithFormat:@"Unable to fetch reference items"];
              NSString *message =[NSString stringWithFormat:@"No connection established to retrieve items with serial from %@",task.description];
              [UIAlertView showBasicAlertWithTitle:title andMessage:message];
              
              dispatch_semaphore_signal(semaphore);
              
              [WebService postError:@{@"error":@"Fetch Reference",@"message":error.description}];
          }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (referenceString) { //return reference or start off with 1
        
        return [referenceString integerValue]+1;
    }
    return 0;
    //return [AuthenticationStation sharedHandler].responseData;
}
+(void) fetchReferenceNumberAFNRecall
{
    NSDictionary *requestParams = [self getDefaultParametersWithSync:true];
    
    
    __block int responseCode = 0;
    __block NSString* referenceString = nil;
    int count = 0;
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    
#ifdef DEBUG
    NSLog(@"request fetchReferenceNumberAFN param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    
    [manager POST:@"Reference" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              NSError* error;
              NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
#ifdef DEBUG
              NSLog(@"downloaded String: %@", responseString);
#endif
              
//              NSDictionary* json = ([responseString isEqualToString:@""]) ? @{@"reference" : @"I 0"} : [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
              
              
              NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
#ifdef DEBUG
//              NSLog(@"Reference Download: %@",[json description] );
#endif
              responseCode = [task.response statusCode];
              
              
              
              NSDictionary* json = ([responseString isEqualToString:@""] || [responseString isEqualToString:@"{}"]) ? @{@"reference" : @"I 0"} : [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
              
              
              referenceString = [json objectForKey:@"reference"];
              responseCode = [task.response statusCode];
#ifdef DEBUG
              NSLog(@"Reference Download: %@ ref:%@",[json description],referenceString );
#endif
              
              NSDictionary* userInfo = @{@"response_code":[NSString stringWithFormat:@"%i",responseCode],
                                         @"response_error":@"connected",
                                         @"response_string":referenceString};
              [nc postNotificationName:NOTIFICATION_WEB_UPDATE_REFERENCE object:nil userInfo:userInfo];
              
          }
     
     
     
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
#ifdef DEBUG
              NSLog(@"STUDENT-ERROR %@", error);
#endif
              
              responseCode = [task.response statusCode];
              
              
              NSDictionary* userInfo = @{@"response_code":[NSString stringWithFormat:@"%i",responseCode],
                                         @"response_error":@"failed",
                                         @"response_string":[error description]};
              NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
              [nc postNotificationName:NOTIFICATION_WEB_UPDATE_REFERENCE object:nil userInfo:userInfo];
              
              [WebService postError:@{@"error":@"Fetch Reference",@"message":error.description}];
          }];
    
    //return [AuthenticationStation sharedHandler].responseData;
}
//returns list of all items for this device as NSArray
+ (NSArray *)fetchItemList
{
    return [self itemFetchMiddlemanAFN:nil];
}

//sends PLU to web service, web service sends back matching item as NSDictionary
+ (NSDictionary *)fetchItemWithPLU:(NSString *)plu
{
    //middleman gives back an array, we return the first dictionary in the array
    //(should only be one item in array, so log an error if there are more than one)
    NSArray *itemArray = [self itemFetchMiddlemanAFN:plu];
    
#ifdef DEBUG
    if ([itemArray count] > 1)
        NSLog(@"ERROR: Multiple items returned with same PLU, returning only the first");
#endif
    
    return [itemArray objectAtIndex:0];
}

//does the shared heavy lifting for preceding two methods
+(NSArray *)itemFetchMiddlemanAFN:(NSString *)plu
{
    NSDictionary *requestParams = nil;
    BOOL sync = plu == nil;
    
    //plu is optional, add to parameters if it exists
    if (plu != nil)
        requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:plu,@"plu",nil];
    requestParams = [WebService addDefaultParamsTo:requestParams sync:sync];
    
    __block int responseCode = 0;
    __block NSArray* responseArray = [[NSArray alloc]init];;
    int count = 0;
    
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    
    //    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    //do {
    
#ifdef DEBUG
    NSLog(@"request itemFetchMiddlemanAFN param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    [manager POST:@"Items" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              
              
              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ // 1
                  dispatch_async(dispatch_get_main_queue(), ^{ // 2
                      [HUDsingleton sharedHUD].detailsLabelText = @"connected";
                  });
                  NSError* error;
                  NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                  NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
                  
                  //                  responseArray = [responseString JSONValue];
                  
                  responseCode = [task.response statusCode];
                  NSDictionary* userInfo = @{@"response_code":[NSString stringWithFormat:@"%i",responseCode],
                                             @"response_error":@"connected",
                                             @"response_string":responseString};
                  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                  [nc postNotificationName:NOTIFICATION_WEB_UPDATE_ITEM object:nil userInfo:userInfo];
#ifdef DEBUG
                  NSLog(@"Item Download: %@",[responseArray description] );
#endif
                  
                  //                  dispatch_semaphore_signal(semaphore);
              });
              
              
              //NSMutableDictionary *itemResponseJSONasString = response;
              //itemResponseArray = [itemResponseJSONasString allValues];
          }
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
#ifdef DEBUG
              NSLog(@"ITEM-ERROR %@", error);
#endif
              
              responseCode = [task.response statusCode];
              NSString* responseerror = [error description];
              
              responseArray = [[NSArray alloc] initWithObjects:@{@"response_code":[NSString stringWithFormat:@"%i",responseCode],
                                                                 @"response_error":[error description]},
                               nil];
              
              NSDictionary* userInfo = @{@"response_code":[NSString stringWithFormat:@"%i",responseCode],
                                         @"response_error":@"failed",
                                         @"response_string":responseerror};
              NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
              [nc postNotificationName:NOTIFICATION_WEB_UPDATE_ITEM object:nil userInfo:userInfo];
              
              
              [WebService postError:@{@"error":@"Fetch Items",@"message":error.description}];
              //              dispatch_semaphore_signal(semaphore);
          }];
    
    //    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    count++;
    //} while ([AuthenticationStation sharedHandler].isStudentConnectionRetry);
    
    
    return responseArray;
    //return [AuthenticationStation sharedHandler].responseData;
}

+ (NSDictionary *)fetchRegisterItemWithBarcodeAFN:(NSString *)barcode
{
    
    NSDictionary *requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:TRUE],@"register",barcode,@"barcode",nil];
    requestParams = [self addDefaultParamsTo:requestParams sync:false];
    
    int responseCode = 0;
    int count = 0;
    
    
    
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    __block NSDictionary* responseArray = nil;
#ifdef DEBUG
    NSLog(@"fetchRegisterItemWithBarcode param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    //do {
    [manager POST:@"Items" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              
              
              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ // 1
                  
                  dispatch_async(dispatch_get_main_queue(), ^{ // 2
                      [HUDsingleton sharedHUD].detailsLabelText = @"connected";
                  });
                  
                  NSError* error;
                  NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                  NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
                  
                  responseArray = json;
                  
                  dispatch_semaphore_signal(semaphore);
              });
          }
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
#ifdef DEBUG
              NSLog(@"ERROR %@", error);
#endif
              NSString *title = [NSString stringWithFormat:@"Unable to fetch register items"];
              NSString *message =[NSString stringWithFormat:@"No connection established to retrieve items with barcode"];
              [UIAlertView showBasicAlertWithTitle:title andMessage:message];
              dispatch_semaphore_signal(semaphore);
              
              
              [WebService postError:@{@"error":@"Fetch Items",@"message":error.description}];
              
          }];
    count++;
    //} while ([AuthenticationStation sharedHandler].isStudentConnectionRetry);
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return responseArray;
    //return [AuthenticationStation sharedHandler].responseData;
}
//returns list of all items for this device as NSArray
+ (NSArray *)fetchStudentList
{
    return [self studentFetchMiddlemanAFN:nil];
}

+ (void)fetchStudentListRecall
{
    return [self fetchStudentWithIDRecall:nil andMoc:[CoreDataHelper getMainMOC]];
}
+(NSArray *)studentFetchMiddlemanAFN:(NSString *)id_number
{
#ifdef DEBUG
    NSLog(@"********** studentFetchMiddleman with id: %@ ***********", id_number);
#endif
    
    
    NSDictionary *requestParams = nil;
    BOOL sync = id_number == nil;
    
    //ID Number is optional, add to parameters if it exists to search for a particular ID
    //if ID is nil, the WebService will return all students
    if (id_number != nil)
        requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:id_number,@"id_number",nil];
    requestParams = [self addDefaultParamsTo:requestParams sync:sync];
    
    
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    __block NSArray* responseArray = nil;
    __block int responseCode = 0;
#ifdef DEBUG
    NSLog(@"studentFetchMiddleman param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    
        manager.requestSerializer.timeoutInterval = 60;
        
        [manager POST:@"Students" parameters:requestParams
              success:^(AFHTTPRequestOperation *task, id responseObject) {
                  NSError* error;
                  NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                  //NSDictionary* json = ([responseString isEqualToString:@""]) ? nil : [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
                  
                  responseArray = [responseString JSONValue];
                  
#ifdef DEBUG
                  NSLog(@"Student Download raw data: %@", responseString);
//                  NSLog(@"Student Download: %@", [responseArray description]);
#endif
                  responseCode = [task.response statusCode];
                  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                  if (id_number) {
                      
                      if ([responseArray isKindOfClass:[NSDictionary class]]) {
                          NSManagedObjectContext *moc = [CoreDataService getMainMOC];
                          NSDictionary* studentToUpdateAsDictionary = (NSDictionary*)responseArray;
                          [OdinStudent updateThisStudentWith:studentToUpdateAsDictionary andMOC:moc sync:false];
                      }
                  } else
                  {
                      NSDictionary* userInfo = @{@"response_code":[NSString stringWithFormat:@"%i",responseCode],
                                                 @"response_error":@"connected",
                                                 @"response_string":responseString};
                      [nc postNotificationName:NOTIFICATION_WEB_UPDATE_STUDENT object:nil userInfo:userInfo];
                  }
                  dispatch_semaphore_signal(semaphore);
                  
              }
         
              failure:^(AFHTTPRequestOperation *task, NSError *error) {
                  
#ifdef DEBUG
                  NSLog(@"STUDENT-ERROR %@", error);
#endif
                  
                  responseCode = [task.response statusCode];
                  responseArray = nil;
                  
                  
                  NSDictionary* userInfo = @{@"response_code":[NSString stringWithFormat:@"%i",responseCode],
                                             @"response_error":@"failed",
                                             @"response_string":[error description]};
                  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                  [nc postNotificationName:NOTIFICATION_WEB_UPDATE_STUDENT object:nil userInfo:userInfo];
                  
                  dispatch_semaphore_signal(semaphore);
                  
                  
                  [WebService postError:@{@"error":@"Fetch Students",@"message":error.description}];
              }];
//    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return responseArray;
}
+ (void)fetchStudentWithIDRecall:(NSString *)id_number andMoc:(NSManagedObjectContext*)moc
{
#ifdef DEBUG
//    NSLog(@"********** studentFetchMiddlemanRecall with id: %@ ***********", id_number);
#endif
    
    
    
    NSDictionary *requestParams = nil;
    BOOL sync = id_number == nil;
    
    //ID Number is optional, add to parameters if it exists to search for a particular ID
    //if ID is nil, the WebService will return all students
    if (id_number != nil)
        requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:id_number,@"id_number",nil];
    requestParams = [self addDefaultParamsTo:requestParams sync:sync];
    
    
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
//    __block NSArray* responseArray = nil;
//    __block int responseCode = 0;
#ifdef DEBUG
//    NSLog(@"studentFetchMiddleman param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    
        manager.requestSerializer.timeoutInterval = 60;
    
        [manager POST:@"Students" parameters:requestParams
              success:^(AFHTTPRequestOperation *task, id responseObject) {
                  NSError* error;
                  NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                  //NSDictionary* json = ([responseString isEqualToString:@""]) ? nil : [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
                  
                  NSArray* responseArray = [responseString JSONValue];
                  
#ifdef DEBUG
//                  NSLog(@"Student Download raw data: %@", responseString);
//                  NSLog(@"Student Download: %@", [responseArray description]);
#endif
                  int responseCode = [task.response statusCode];
                  NSDictionary* userInfo = @{@"response_code":[NSString stringWithFormat:@"%i",responseCode],
                                             @"response_error":@"connected",
                                             @"response_string":responseString};
                  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                  
                  
                  if (id_number) {
                      //- don't update student when we are doing other stuff
                      if ([responseArray isKindOfClass:[NSDictionary class]] && ![SettingsHandler sharedHandler].isProcessingSale) {
                          NSDictionary* studentToUpdateAsDictionary = (NSDictionary*)responseArray;
                          [moc performBlock:^{
                              
                              [OdinStudent updateThisStudentWith:studentToUpdateAsDictionary andMOC:moc sync:false];
                              [CoreDataHelper saveObjectsInContext:moc];
                              [AuthenticationStation sharedHandler].isStudentChecking = false;
                          }];
                      }
                  } else
                  {
                      
                      [nc postNotificationName:NOTIFICATION_WEB_UPDATE_STUDENT object:nil userInfo:userInfo];
                  }
//                  dispatch_semaphore_signal(semaphore);
                  
              }
         
              failure:^(AFHTTPRequestOperation *task, NSError *error) {
                  
#ifdef DEBUG
                  NSLog(@"STUDENT-ERROR %@", error);
#endif
                  
                  int responseCode = [task.response statusCode];
//                  responseArray = nil;
                  if (id_number) {
                      
                  } else {
                  
                  NSDictionary* userInfo = @{@"response_code":[NSString stringWithFormat:@"%i",responseCode],
                                             @"response_error":@"failed",
                                             @"response_string":[error description]};
                  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                  [nc postNotificationName:NOTIFICATION_WEB_UPDATE_STUDENT object:nil userInfo:userInfo];
                  }
//                  dispatch_semaphore_signal(semaphore);
                  
                  [WebService postError:@{@"error":@"Fetch Students",@"message":error.description}];
                  
              }];
//    });
//    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
}
//sends PLU to web service, web service sends back matching item as NSDictionary
+ (NSDictionary *)fetchStudentWithID:(NSString *)id_number
{
    if (id_number == nil || [id_number isEqualToString:@""]) {
        return nil;
    }
    
    NSArray *studentArray = [self studentFetchMiddlemanAFN:id_number];
    
    if (studentArray == nil) {
        return nil;
    } else if ([studentArray isKindOfClass:[NSDictionary class]])
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
+ (NSDictionary* )fetchDataForAccountTypeAFN:(NSDictionary *)transaction
{
    [AuthenticationStation sharedHandler].isPosting = TRUE;
    
    NSDictionary * tran = [NSDictionary dictionaryWithDictionary:transaction];
    
    NSData *transactionForDictionary = [[tran JSONRepresentation] JSONValue];
    
    NSDictionary *requestParams = [NSDictionary dictionaryWithObjectsAndKeys:transactionForDictionary,@"transaction", nil];
    requestParams = [WebService addDefaultParamsTo:requestParams sync:false];
    
#ifdef DEBUG
    NSLog(@"AFN POST uploaded transaction: %@",[requestParams description]);
#endif
    
    [AuthenticationStation sharedHandler].isPosting = FALSE;
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    __block NSArray* accntResponseArray = nil;
#ifdef DEBUG
    NSLog(@"AFN fetchDataForAccountTypeAFN request param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [manager POST:@"AccountType" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              
              NSError* error;
              NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
              NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
              accntResponseArray = [responseString JSONValue];
              
              dispatch_semaphore_signal(semaphore);
              
          }
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
#ifdef DEBUG
              NSLog(@"ERROR %@", error);
#endif
              accntResponseArray = nil;
              dispatch_semaphore_signal(semaphore);
              
              [WebService postError:@{@"error":@"Fetch Account Type",@"message":error.description}];
          }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
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
+ (BOOL)postUploadedTransactionAFN:(NSDictionary *)transaction
{
    [AuthenticationStation sharedHandler].isPosting = TRUE;
    
    NSDictionary * tran = [NSDictionary dictionaryWithDictionary:transaction];
    
    NSData *transactionForDictionary = [[tran JSONRepresentation] JSONValue];
    
    NSDictionary *requestParams = [NSDictionary dictionaryWithObjectsAndKeys:transactionForDictionary,@"transaction", nil];
    requestParams = [WebService addDefaultParamsTo:requestParams sync:false];
    
#ifdef DEBUG
    NSLog(@"AFN POST uploaded transaction: %@",[requestParams description]);
#endif
    
    [AuthenticationStation sharedHandler].isPosting = FALSE;
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    __block BOOL* response = FALSE;
#ifdef DEBUG
    NSLog(@"AFN postUploadedTransactionAFN request param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [manager POST:@"TransactionUploaded" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              response = TRUE;
              
              NSError* error;
              NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
#ifdef DEBUG
              NSLog(@"responseString %@",responseString);
#endif
              dispatch_semaphore_signal(semaphore);
              
          }
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
#ifdef DEBUG
              NSLog(@"UPLOAD ERROR %@", error);
#endif
              response = FALSE;
#ifdef DEBUG
              NSData* responseErrorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
              if (responseErrorData != nil) {
                  
                  NSString* responseErrorString = [[NSJSONSerialization JSONObjectWithData:responseErrorData options:0 error:nil]description];
                  NSLog(@"Error data: %@", responseErrorString);
              }
#endif
              
              dispatch_semaphore_signal(semaphore);
              
              [WebService postError:@{@"error":@"Uploaded Transaction",@"message":error.description}];
          }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return response;
    
}
//posts a transaction, and updates student table (along with stock table for "local" builds)
//returns false on any errors
+ (NSString*)postTransactionAFN:(NSDictionary *)transaction
{
//    [AuthenticationStation sharedHandler].isPosting = TRUE;
    
    NSDictionary * tran = [NSDictionary dictionaryWithDictionary:transaction];
    
    NSData *transactionForDictionary = [[tran JSONRepresentation] JSONValue];
    
    NSDictionary *requestParams = [NSDictionary dictionaryWithObjectsAndKeys:transactionForDictionary,@"transaction", nil];
    requestParams = [WebService addDefaultParamsTo:requestParams sync:false];
    
#ifdef DEBUG
    NSLog(@"AFN POST uploaded transaction: %@",[requestParams description]);
#endif
    
//    [AuthenticationStation sharedHandler].isPosting = FALSE;
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    __block NSString* response = @"";
#ifdef DEBUG
    NSLog(@"AFN postTransactionAFN request param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [manager POST:@"Transaction" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              
              
              NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
#ifdef DEBUG
              NSLog(@"UPLOADED response %@", responseString);
#endif
              if (task.response.statusCode == 200) {
                  NSManagedObjectContext* moc = [CoreDataHelper getCoordinatorMOC];
                  [moc performBlock:^{
                      OdinTransaction* webTran = [OdinTransaction getTransaction:transaction andContext:moc];
                      //                  if ([responseString hasSuffix:@"status:success"]) {
                      webTran.sync = [NSNumber numberWithBool:true];
                      [CoreDataService saveObjectsInContext:moc];
                      response = @"200";
                  }];
              }
              dispatch_semaphore_signal(semaphore);
          }
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
#ifdef DEBUG
              NSLog(@"UPLOAD ERROR %@", error);
#endif
              response = @"ERROR";
#ifdef DEBUG
              NSData* responseErrorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
              NSString* responseErrorString = [[NSString alloc] initWithData:responseErrorData encoding:NSUTF8StringEncoding];
              NSLog(@"Error data: %@", responseErrorString);
#endif
              dispatch_semaphore_signal(semaphore);
              [WebService postError:@{@"error":@"Upload Transaction",@"message":error.description}];
          }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return response;
    
}
+ (void)postTransactionAFNWithRecall:(NSDictionary *)transaction isBatch:(BOOL)batch
{
    
    
    
    NSData *transactionForDictionary = [[transaction JSONRepresentation] JSONValue];
    
    NSDictionary *requestParams = [NSDictionary dictionaryWithObjectsAndKeys:transactionForDictionary,@"transaction", nil];
    requestParams = [WebService addDefaultParamsTo:requestParams sync:false];
    
#ifdef DEBUG
    NSLog(@"AFN POST Batch uploaded transaction: %@",[requestParams description]);
#endif
    
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
#ifdef DEBUG
    NSLog(@"AFN postTransactionAFN request param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    
    [manager POST:@"Transaction" parameters:requestParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              
              
              NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
              
              int count = [SettingsHandler sharedHandler].numberOfUploadTransaction;
              [SettingsHandler sharedHandler].numberOfUploadTransaction = --count;
#ifdef DEBUG
              NSLog(@"UPLOADED Batch ref:%@ item:%@ count:%i code:%i response %@", [transaction objectForKey:@"reference"],[transaction objectForKey:@"item"], count,(int)task.response.statusCode, responseString);
#endif
              NSManagedObjectContext* moc = [CoreDataHelper getCoordinatorMOC];
              [moc performBlock:^{
              
                  if (task.response.statusCode == 200) {
                      NSString* reference = [transaction objectForKey:@"reference"];
                      NSString* plu = [transaction objectForKey:@"plu"];
                      OdinTransaction* webTran = [OdinTransaction getTransaction:transaction andContext:moc];
                      //                  if ([responseString hasSuffix:@"status:success"]) {
                      if (webTran) {
#ifdef DEBUG
                          NSLog(@"sync transaction");
#endif
                          webTran.sync = [NSNumber numberWithBool:true];
                      }
                  }
                  
                  if (batch) {
                      NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                      if (count > 0) {
#ifdef DEBUG
                          NSLog(@"update batch hud");
#endif
                          NSDictionary* userInfo = @{@"count":[NSString stringWithFormat:@"%i uploading",count]};
                          [nc postNotificationName:NOTIFICATION_UPDATE_HUD object:nil userInfo:userInfo];
                      } else {
                          [UIView animateWithDuration:0 animations:^{
                              [CoreDataService saveObjectsInContext:moc];
                          } completion:^(BOOL finished) {
#ifdef DEBUG
                              NSLog(@"finish Upload Batch Transaction");
#endif
                              [nc postNotificationName:NOTIFICATION_WEB_UPLOAD_TRANSACTION object:nil];
                          }];
                          
                      }
                  } else {
                      if (![AuthenticationStation sharedHandler].isPosting) {
#ifdef DEBUG
                          NSLog(@"save single transaction");
#endif
                          [CoreDataService saveObjectsInContext:moc];
                      }
                      [AuthenticationStation sharedHandler].isTransactionChecking = false;
                  }
                  
              }];
          }
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
              int count = [SettingsHandler sharedHandler].numberOfUploadTransaction;
              [SettingsHandler sharedHandler].numberOfUploadTransaction = --count;
#ifdef DEBUG
              NSLog(@"UPLOAD Batch count:%i ERROR %@",count, error);
#endif
#ifdef DEBUG
              NSData* responseErrorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
              NSString* responseErrorString = [[NSString alloc] initWithData:responseErrorData encoding:NSUTF8StringEncoding];
              NSLog(@"Error data: %@", responseErrorString);
#endif
              if (count <= 0 && batch) {
                  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                  [nc postNotificationName:NOTIFICATION_WEB_UPLOAD_TRANSACTION object:nil];
              }
              [AuthenticationStation sharedHandler].isTransactionChecking = false;
              [WebService postError:@{@"error":@"Upload Transaction Recall",@"message":error.description}];
          }];
    
}
+(void)postTransactionWithStringAFNWithTransaction:(OdinTransaction*)transaction //depreciated
{
    
    NSString* xmlString = [transaction prepForWebservice];
    //NSDictionary *requestParams = @{@"TranData":xmlString};
    //requestParams = [WebService addDefaultParamsTo:requestParams];
    
#ifdef DEBUG
    NSLog(@"AFN POST uploaded transaction: %@",[transaction description]);
#endif
    
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    //        manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //    [manager.requestSerializer setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    //    [manager.requestSerializer setValue:@"http://tempuri.org/IMKSService/RcvTran" forHTTPHeaderField:@"SOAPAction"];
    
    __block NSString* response = @"";
#ifdef DEBUG
    //NSLog(@"AFN request param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
    //    NSLog(@"header %@", manager.requestSerializer.debugDescription);
#endif
    //    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    
    //    sleep(10);
    NSString* url = @"https://msdata.co/webservice.asmx/RcvTran?";
    //        NSString* url = @"http://52.5.182.228/Service1.svc/balance?";
    //        NSString* url = @"http://52.5.182.228/Service.svc/RcvTran";
    //    NSDictionary* param = @{@"TranData" : xmlString};
    NSDictionary* param = @{@"TranData" : xmlString};
    NSString* reference = transaction.reference;
    //    NSString* param = [NSString insertSOAPContent:xmlString action:@"RcvTran"];
    //    NSDictionary* param = @{@"uid" : @"f31fa04b-84ae-11e5-810f-22000b83b823"};
#ifdef DEBUG
    NSLog(@"\nRcvTran new param %@",param);
#endif
    
    
    manager.requestSerializer.timeoutInterval = 60;
    [manager GET:url parameters:param
         success:^(AFHTTPRequestOperation *task, id responseObject) {
             
             NSError* error;
             response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
             //             dispatch_semaphore_signal(semaphore);
             
             //0 = successfully sync
             //1 = failed
             NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
             NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] initWithDictionary:
                                              @{@"wasASuccess":@"1"}];
#ifdef DEBUG
             
#endif
             [userInfo setObject:@"reference" forKey:reference];
             
             
             NSManagedObjectContext* moc = [CoreDataService getMainMOC];
             OdinTransaction* tran = [OdinTransaction getTransactionByReference:reference];
             if (tran == nil) {
                 //[nc postNotificationName:@"dismissAlert" object:nil];
             } else
                 if ([reference compareReference:[SettingsHandler sharedHandler].processingRef]
                     && [tran existIn:moc]
                     && [SettingsHandler sharedHandler].isProcessingSale) {
                     if ([response hasSuffix:@">0</string>"]) {
#ifdef DEBUG
                         NSLog(@"RcvTran success response %@",task.response.description);
#endif
                         if (tran) {
                             
                             tran.sync = [NSNumber numberWithBool:TRUE];
                             
                             [CoreDataService saveObjectsInContext:moc];
                         }
                         [nc postNotificationName:@"dismissAlert" object:nil];
                     } else {
#ifdef DEBUG
                         NSLog(@"RcvTran success but has error response %@",task.response.description);
#endif
                         [userInfo setObject:@"\nUpload Failed" forKey:@"message"];
                     }
#ifdef DEBUG
                     NSLog(@"post notification showHUDPostStatus %d", [SettingsHandler sharedHandler].isProcessingSale);
#endif
                     //only post current transaction
                     NSString* currentRef = [SettingsHandler sharedHandler].processingRef;
                     
#ifdef DEBUG
                     NSLog(@"current ref %@ current trans ref %@",currentRef,transaction.reference);
#endif
                     
                     [nc postNotificationName:@"showHUDPostStatus" object:nil userInfo:userInfo];
                     [[HUDsingleton sharedHUD] hide:NO afterDelay:1.0];
                 }
             //end it no matter what
             //                 [nc postNotificationName:@"showHUDPostStatus" object:nil userInfo:userInfo];
             [[SettingsHandler sharedHandler] processingSaleEnd];
             
#ifdef DEBUG
             NSLog(@"response: %@",response);
#endif
             
         }
     
         failure:^(AFHTTPRequestOperation *task, NSError *error) {
             
#ifdef DEBUG
             NSLog(@"RcvTran ERROR %@", error);
#endif
             response = @"ERROR";
             //             dispatch_semaphore_signal(semaphore);
#ifdef DEBUG
             NSLog(@"post notification showHUDPostStatus");
#endif
             NSDictionary* userInfo = @{@"wasASuccess":@"1",@"message":@"Upload Failed"};
             
             NSManagedObjectContext* moc = [CoreDataService getMainMOC];
             NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
             if ([reference compareReference:[SettingsHandler sharedHandler].currentReference] &&
                 [transaction existIn:moc]) {
                 
                 //                     [nc postNotificationName:@"dismissAlert" object:nil];
                 
                 NSString* nextRef = [SettingsHandler sharedHandler].referenceNum;
                 int nextNum = [nextRef intValue];
                 nextNum -= 1;
                 NSString* currentRef = [NSString stringWithFormat:@"%@ %i",[SettingsHandler sharedHandler].referenceCode, nextNum];
                 
#ifdef DEBUG
                 NSLog(@"current ref %@ current trans ref %@",currentRef,transaction.reference);
#endif
                 if ([currentRef isEqualToString:transaction.reference]) {
                     
                     [nc postNotificationName:@"showHUDPostStatus" object:nil userInfo:userInfo];
                 }
                 
             }
             
             [WebService postError:@{@"error":@"Upload Transaction With Transaction",@"message":error.description}];
             //end it no matter what
             [[SettingsHandler sharedHandler] processingSaleEnd];
         }];
    
}
+(NSString*)postTransactionWithStringAFN:(NSString*)xmlString
{
    
    //NSDictionary *requestParams = @{@"TranData":xmlString};
    //requestParams = [WebService addDefaultParamsTo:requestParams];
    
#ifdef DEBUG
    //NSLog(@"AFN POST uploaded transaction: %@",[requestParams description]);
#endif
    
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    __block NSString* response = @"";
#ifdef DEBUG
    //NSLog(@"AFN request param: %@ at address %@",requestParams,[[AuthenticationStation sharedHandler].portableServicePath description]);
#endif
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    
    
    NSString* url = @"https://msdata.co/webservice.asmx/RcvTran?";
    NSDictionary* param = @{@"TranData" : xmlString};
    
    
    //LastTransfer returns <balance,date,last deposit amount,???,timestamp>
    //AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:param
         success:^(AFHTTPRequestOperation *task, id responseObject) {
             
             NSError* error;
             response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
             dispatch_semaphore_signal(semaphore);
             
         }
     
         failure:^(AFHTTPRequestOperation *task, NSError *error) {
             
#ifdef DEBUG
             NSLog(@"ERROR %@", error);
#endif
             response = @"ERROR";
             dispatch_semaphore_signal(semaphore);
             [WebService postError:@{@"error":@"Upload Transaction Webservice",@"message":error.description}];
         }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return response;
    
}

/*
 * call function with params
 *      error - The name of the webservice it is calling
 *      message - Error message AFNetworking returns
 * Can check error message at https://msdata.co/Portable/MyLog
 */
+ (void)postError:(NSDictionary*)params
{
    NSDictionary *requestParams = [WebService getDefaultParametersWithSync:true];
    //create Request and start it
    AFHTTPRequestOperationManager* manager = [WebService createAFHTTPRequestWithPortableURL];
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:requestParams];
    [dict addEntriesFromDictionary:params];
    
    NSDictionary* allParams = [NSDictionary dictionaryWithDictionary:dict];
    
    
    [manager POST:@"MyLog" parameters:allParams
          success:^(AFHTTPRequestOperation *task, id responseObject) {
              
#ifdef DEBUG
              NSLog(@"postError Success %@", [NSString downloadDataToString:responseObject]);
#endif
              
          }
     
          failure:^(AFHTTPRequestOperation *task, NSError *error) {
              
#ifdef DEBUG
              NSLog(@"postError ERROR %@", error);
#endif
          }];
    
}
/*
 +(BOOL)postEmailReceipt:(NSString*)xmlString
 {
	
	
	
	NSString *post = [[NSString alloc] initWithFormat: @"https://msdata.co/webservice.asmx/RcvTran?%@",xmlString];
	NSURL *url = [NSURL URLWithString:post];
	NSMutableURLRequest *sendRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15];
	[sendRequest setHTTPMethod:@"GET"];
	NSURLConnection *theConnection = [NSURLConnection.alloc initWithRequest:sendRequest delegate:self];
 
	
 #ifdef DEBUG
	NSLog(@"email: %@", post);
 #endif
	if (theConnection){
 #ifdef DEBUG
 NSLog(@"POST RcvccTranReceipt successful");
 #endif
 return TRUE;
	}
 #ifdef DEBUG
	NSLog(@"POST RcvccTranReceipt failed");
 #endif
 //	REMOVE FOR PSTALERT
 //	POST IN SUBCLASS
 //	[ErrorAlert simpleAlertTitle:@"ERROR"
 //						 message:@"Item is charged but fail to deliver to webservice. Transaction is store into Pending Transaction"];
	
	return FALSE;
 }*/

+(AFHTTPRequestOperationManager*) createAFHTTPRequestWithPortableURL
{
    NSURL* baseURL = [[AuthenticationStation sharedHandler] portableServicePath];
    AFHTTPRequestOperationManager* manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    float deviceType = [UIDevice currentDevice].model.floatValue;
    manager.requestSerializer.timeoutInterval = deviceType >= 5? 15:90;
    manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    float timeout = deviceType >= 5? 15:90;
#ifdef DEBUG
//    NSLog(@"network timeout set %f",timeout);
#endif
    //    manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    return manager;
}
+(AFHTTPSessionManager*) createAFHTTPSessionWithPortableURL
{
    NSURL* baseURL = [[AuthenticationStation sharedHandler] portableServicePath];
    AFHTTPSessionManager* manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    float deviceType = [UIDevice currentDevice].model.floatValue;
    manager.requestSerializer.timeoutInterval = deviceType >= 5? 15:60;
    
    return manager;
}

-(void)myStudentCheckTimerStart
{
#ifdef DEBUG
    NSLog(@"myStudentCheckTimerStart");
#endif
    //    if (myTimer == nil) {
    //    myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(callAfterTenSeconds:) userInfo:nil repeats:NO];
    //        [NSTimer scheduledTimerWithTimeInterval:1 target:FirstVC selector:@selector(callAfterTenSeconds:) userInfo:nil repeats:NO];
    
    //    }
    [self performSelector:@selector(callAfterTenSeconds) withObject:nil afterDelay:1];
}
-(void)callAfterTenSeconds
{
    
#ifdef DEBUG
    NSLog(@"callAfterTenSeconds");
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:@"callAfterTenSeconds" object:nil];
}

@end

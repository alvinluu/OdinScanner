//
//  StreamInOut.m
//  OdinScanner
//
//  Created by KenThomsen on 2/7/14.
//
//

#import "StreamInOut.h"
#import "NSObject+SBJson.h"

@implementation StreamInOut
-(id)init
{
	if (self == nil) {
		
		return [[StreamInOut alloc] init];
	}
	return self;
}
//Return the Document Directory Path
+ (NSString *)getPrivateDocsDir
{
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"transaction_log.txt"];
    return documentsDirectory;
    
}
+(NSString*)readLogFileWithLocation:(NSString*)fileLocation
{
	
	NSString *dataPath = [self getPrivateDocsDir];
	
	NSError *error;
	NSString *data = [NSString stringWithContentsOfFile:dataPath encoding:NSUTF8StringEncoding error:&error];
	if (error != nil) return @"";
	
	return data;
	
}

+(BOOL)writeLogFileWithTransaction:(NSDictionary*)transaction Note:(NSString*)note
{
#ifdef DEBUG
	NSLog(@"start WRITE FILE writeLogFileWithTransaction");
#endif
	
	//Assign path
	NSString *dataPath = [self getPrivateDocsDir];
	
	//Get Document File
	NSString *fileData = [self readLogFileWithLocation:dataPath];
	
	//Convert Data to NSString
	NSString* transactionString = [transaction JSONRepresentation];
	
	NSDate* currentDate = [NSDate localDate];
	//Append file Data with new transaction
	fileData = [fileData stringByAppendingFormat:@"%@ %@\n     "  ,[currentDate asStringWithNSDate], note];
	transactionString = [fileData stringByAppendingString:transactionString];
	transactionString = [transactionString stringByAppendingFormat:@"\n\n"];
	
	//Write to file
	NSError *error;
	BOOL WRITE_ERROR = [transactionString writeToFile:dataPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
#ifdef DEBUG
	if (WRITE_ERROR) {
		NSLog(@"write file success with path %@ with data %@", dataPath, transaction);
	} else
	{
		NSLog(@"write file with error %@",error);
	}
#endif
	
	//Make a copy to transaction pending
	if ([note isEqualToString:@"Manual Stored Into Pending"] || [note isEqualToString:@"Batch Stored Into Pending"]) {
		[self writePendingFileWithTransaction:transaction];
	}
	
	//Update transaction in pending
	if ([note isEqualToString:@"Delete Pending Transaction"]) {
		[self deletePendingItemInFileWithTransaction:transaction];
	}
	
	return WRITE_ERROR;
}
#pragma mark Pending Transaction
+ (NSString *)getPrivateDocsDirInPending
{
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"transaction_pending.txt"];
    return documentsDirectory;
}
+(NSString*)readPendingFileWithLocation:(NSString*)fileLocation
{
	
	//NSString *dataPath = [self getPrivateDocsDirInPending];
	
	NSError *error;
	NSString *data = [NSString stringWithContentsOfFile:fileLocation encoding:NSUTF8StringEncoding error:&error];
	if (error != nil || data.length < 1)
		//return @"{ \"transaction\" : [ ";
		return @"";
	
	return data;
	
}
+(NSString*)removeBracketWithString:(NSString*)data
{
	// remove everything after the end bracket
	
	NSRange bracketRange = [data rangeOfString:@"]" ];
	if (bracketRange.location == NSNotFound) {
#ifdef	DEBUG
		NSLog(@"There is no end bracket");
#endif
	} else
	{
		
#ifdef  DEBUG
		NSLog(@"Pending File exists with end bracket at %lu and remove bracket",(unsigned long)bracketRange.location);
#endif
		data = [data substringToIndex:bracketRange.location];
	}
	return data;
}
+(BOOL)writePendingFileWithTransaction:(NSDictionary*)transaction
{
#ifdef DEBUG
	NSLog(@"start WRITE FILE writePendingFileWithTransaction");
#endif
	
	//Assign path
	NSString *dataPath = [self getPrivateDocsDirInPending];
	
	//Get Document File
	NSString *fileData = [self readPendingFileWithLocation:dataPath];
	
	//remove end bracket
	fileData = [self removeBracketWithString:fileData];

	//Convert Data to NSString
	/* convert NSDictionary to NSData
	NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:transaction
													   options:0
														 error:&error];*/
	NSString* transactionString = [transaction JSONRepresentation];
	
	NSRange bracketRange = [fileData rangeOfString:@"["];
	NSRange curlybracketRange = [fileData rangeOfString:@"{"];
	
	//add bracket when adding a 2nd transaction
	if (bracketRange.location == NSNotFound) {
		fileData = [@"[" stringByAppendingString:fileData];
	}
	
	if (curlybracketRange.location != NSNotFound) {
		
		
		NSLog(@"add comma");
		
		//add comma in front of transaction
		transactionString = [@",\n\n" stringByAppendingString:transactionString];
	}
	
	//Append file Data with new transaction
	transactionString = [fileData stringByAppendingString:transactionString];
	
	//add end bracket when there is a start bracket
	bracketRange = [fileData rangeOfString:@"["];
	if (bracketRange.location != NSNotFound) {
		transactionString = [transactionString stringByAppendingFormat:@"]"];
	}
	
	//Write to file
	NSError *error;
	BOOL WRITE_ERROR = [transactionString writeToFile:dataPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
#ifdef DEBUG
	if (WRITE_ERROR) {
		NSLog(@"write file success with pending path %@ with data %@", dataPath, transaction);
	} else
		NSLog(@"write file with error %@",error);
#endif
	return WRITE_ERROR;
}
+(BOOL)resetPendingFile
{
#ifdef DEBUG
	NSLog(@"start WRITE FILE resetPendingFile");
#endif
	
	//Assign path
	NSString *dataPath = [self getPrivateDocsDirInPending];
	
	//Get Document File
	NSString *fileData = [self readPendingFileWithLocation:dataPath];
	
	NSString *myData = @"";
	
	//Write to file
	NSError *error;
	BOOL WRITE_ERROR = [myData writeToFile:dataPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
#ifdef DEBUG
	if (WRITE_ERROR) {
		NSLog(@"write file success with pending path %@", dataPath);
	} else
		NSLog(@"write file with error %@",error);
#endif
	return WRITE_ERROR;
}

+(BOOL)deletePendingItemInFileWithTransaction:(NSDictionary*)transaction
{
#ifdef DEBUG
	NSLog(@"start WRITE FILE deletePendingItemFileWithTransaction");
#endif
	
	//Assign path
	NSString *dataPath = [self getPrivateDocsDirInPending];
	
	//Get Document File
	NSString *fileData = [self readPendingFileWithLocation:dataPath];
	
	NSArray *itemsArray = [fileData JSONValue];
	
	//remove
	
	NSString *newFileData = @"";
	
	//NSLog(@"itemsArray count %i",[itemsArray count]);
	for (NSDictionary *itemAsDictionary in itemsArray)
	{
		if (![itemAsDictionary isEqual:transaction]) {
			//NSLog(@"re-add old transaction");
			
			NSRange bracketRange = [newFileData rangeOfString:@"}"];
			if (bracketRange.location == NSNotFound)
			{
				newFileData = [newFileData stringByAppendingString:[itemAsDictionary JSONRepresentation]];
			} else
			{
				newFileData = [newFileData stringByAppendingString:@",\n\n"];
				newFileData = [newFileData stringByAppendingString:[itemAsDictionary JSONRepresentation]];
			}
		}
	}

	NSRange curlybracketRange = [newFileData rangeOfString:@"}"];
	if ([newFileData isEqualToString: @""] == NO && curlybracketRange.location != NSNotFound) {
		newFileData = [@"[" stringByAppendingString:newFileData];
		newFileData = [newFileData stringByAppendingString:@"]"];
	}
	
	
	//NSLog(@"newFileData:%@",newFileData);
	//Write to file
	NSError *error;
	BOOL WRITE_ERROR = [newFileData writeToFile:dataPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
#ifdef DEBUG
	if (WRITE_ERROR) {
		NSLog(@"write file success with path %@ with deleting data %@", dataPath, transaction);
	} else
		NSLog(@"write file with error %@",error);
#endif
	return WRITE_ERROR;
}

+(BOOL)updatePendingItemInFileWithTransaction:(NSDictionary*)transaction
{
#ifdef DEBUG
	NSLog(@"start WRITE FILE updatingPendingItemFileWithTransaction");
#endif
	
	//Assign path
	NSString *dataPath = [self getPrivateDocsDirInPending];
	
	//Get Document File
	NSString *fileData = [self readPendingFileWithLocation:dataPath];
	
	NSArray *itemsArray = [fileData JSONValue];
	
	//remove
	
	NSString *newFileData = @"";
	
	//NSLog(@"itemsArray count %i",[itemsArray count]);
	for (NSDictionary *itemAsDictionary in itemsArray)
	{
		if (![itemAsDictionary isEqual:transaction]) {
			//NSLog(@"re-add old transaction");
			
			NSRange bracketRange = [newFileData rangeOfString:@"}"];
			if (bracketRange.location == NSNotFound)
			{
				newFileData = [newFileData stringByAppendingString:[itemAsDictionary JSONRepresentation]];
			} else
			{
				newFileData = [newFileData stringByAppendingString:@",\n\n"];
				newFileData = [newFileData stringByAppendingString:[itemAsDictionary JSONRepresentation]];
			}
		} else {//update current transaction
			
			NSRange bracketRange = [newFileData rangeOfString:@"}"];
			if (bracketRange.location == NSNotFound)
			{
				newFileData = [newFileData stringByAppendingString:[transaction JSONRepresentation]];
			} else
			{
				newFileData = [newFileData stringByAppendingString:@",\n\n"];
				newFileData = [newFileData stringByAppendingString:[transaction JSONRepresentation]];
			}
		}
	}
	
	NSRange curlybracketRange = [newFileData rangeOfString:@"}"];
	if ([newFileData isEqualToString: @""] == NO && curlybracketRange.location != NSNotFound) {
		newFileData = [@"[" stringByAppendingString:newFileData];
		newFileData = [newFileData stringByAppendingString:@"]"];
	}
	
	
	//NSLog(@"newFileData:%@",newFileData);
	//Write to file
	NSError *error;
	BOOL WRITE_ERROR = [newFileData writeToFile:dataPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
#ifdef DEBUG
	if (WRITE_ERROR) {
		NSLog(@"write file success with path %@ with updating data %@", dataPath, transaction);
	} else
		NSLog(@"write file with error %@",error);
#endif
	return WRITE_ERROR;
}

@end

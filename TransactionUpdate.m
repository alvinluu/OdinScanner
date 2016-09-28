//
//  StudentUpdate.m
//  OdinScanner
//
//  Created by Ben McCloskey on 9/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StudentUpdate.h"
#import "OdinStudent.h"
#import "AppDelegate.h"
//#import "SynchronizationOperation.h"

@implementation StudentUpdate
{
	NSDate* startDate;
	NSDate* endDate;
}
@synthesize sleepyTime;

-(StudentUpdate *) initWithDelay:(NSTimeInterval)sleepDelay
{
	sleepyTime = sleepDelay;
	self = [super init];
	return self;
}
NSManagedObjectContext *moc;
-(void) main
{
	//This is a scheduler for checking student balance
	//if (studentListSize == 0) {return;}
	
	
	//wait for the alloted time between each student update
	sleep(sleepyTime);
#ifdef DEBUG
//	return;
	NSLog(@"checking student balance isStudentChecking:%i isProcessing:%i",[AuthenticationStation sharedAuth].isStudentChecking, [SettingsHandler sharedHandler].isProcessingSale);
#endif
	
	//don't check on student during Re-Sync
	if ([AuthenticationStation sharedAuth].isStudentChecking || [SettingsHandler sharedHandler].isProcessingSale)
	{
#ifdef DEBUG
		NSLog(@"cancel student update");
#endif
		return;
	}
	
	//if we're in offline mode, skip this process
	if ([[AuthenticationStation sharedAuth] isOnline] == TRUE)
	{
		[AuthenticationStation sharedAuth].isStudentChecking = true;
#ifdef DEBUG
		//get start time
		startDate = [NSDate localDate];
		//sleep(rand()%10+1);
#endif
		moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
		[moc setPersistentStoreCoordinator:[CoreDataService getMainStoreCoordinator]];
		
		//find most out-of-date student record
		NSArray *arrayOfStudents = [CoreDataService getObjectsForEntity:@"OdinStudent"
														   withSortKey:@"last_update"
													  andSortAscending:YES
															andContext:moc];
		
		OdinStudent *studentToUpdate;
		if ([arrayOfStudents count] > 0)
		{
			studentToUpdate = [arrayOfStudents objectAtIndex:0];
		} else {
			[AuthenticationStation sharedAuth].isStudentChecking = false;
			return;
		}
		//check "isCancelled" on either end of the fetch from webservice, as that's what takes the time
		if ([self isCancelled] == TRUE || studentToUpdate == nil || [SettingsHandler sharedHandler].isProcessingSale) {
			[AuthenticationStation sharedAuth].isStudentChecking = false;
			return;
		}
		
		//fetch info from webservice
        
        
//        NSDictionary *studentToUpdateAsDictionary = [WebService fetchStudentWithID:[studentToUpdate id_number]];
        [WebService fetchStudentWithID:[studentToUpdate id_number]];
        [AuthenticationStation sharedAuth].isStudentChecking = false;
        return;
        
//		if ([self isCancelled] == TRUE || studentToUpdateAsDictionary == nil || studentToUpdate == nil ||  || [SettingsHandler sharedHandler].isProcessingSale) {
//			[AuthenticationStation sharedAuth].isStudentChecking = false;
//			return;
//		}
		
		//update that student's balance
//		if ([studentToUpdateAsDictionary objectForKey:@"present"])
//		{
//			if (!) {
    
//				[OdinStudent updateThisStudentWith:studentToUpdateAsDictionary andMOC:moc];
//			}
			
//			if (studentToUpdate.last_update) {
#ifdef DEBUG
//				NSLog(@"update single student %@ %@",studentToUpdate.id_number, studentToUpdate.last_update);
#endif
//				studentToUpdate.last_update = [NSDate localDate];
				
				//[CoreDataService saveObjectsInContext:opMoc];
				
				//save our changes
				//		if ( == false)
				//		{
//				[CoreDataService saveObjectsInContext:moc];
				//		}
//			}
//		}
		
		//get end time
#ifdef DEBUG
		endDate = [NSDate localDate];
		NSTimeInterval durationOfUpdate = [endDate timeIntervalSinceDate:startDate];
		NSLog(@"update took:%.2f seconds",durationOfUpdate);
#endif
		[AuthenticationStation sharedAuth].isStudentChecking = false;
	}
}


@end

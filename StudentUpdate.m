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
    AuthenticationStation* auth = [AuthenticationStation sharedHandler];
    SettingsHandler* sett = [SettingsHandler sharedHandler];
#ifdef DEBUG
    //	return;
//    	NSLog(@"checking student balance isStudentChecking:%i isProcessing:%i isPosting:%i",
//              auth.isStudentChecking,
//              sett.isProcessingSale,
//              auth.isPosting);
    //    return;
#endif
    //don't check on student during Re-Sync
    if (auth.isStudentChecking
        || sett.isProcessingSale
        || auth.isPosting)
    {
#ifdef DEBUG
        //		NSLog(@"cancel student update");
#endif
        return;
    }
    
    //if we're in offline mode, skip this process
    if ([auth isOnline] == TRUE)
    {
        auth.isStudentChecking = true;
#ifdef DEBUG
        //get start time
        startDate = [NSDate localDate];
        //sleep(rand()%10+1);
#endif
        moc = [CoreDataHelper getCoordinatorMOC];
        __block NSString* idNumber;
        
        //find most out-of-date student record
        [moc performBlock:^{
            
            NSArray *arrayOfStudents = [CoreDataService getObjectsForEntity:@"OdinStudent"
                                                                withSortKey:@"last_update"
                                                           andSortAscending:YES
                                                                 andContext:moc];
            
            OdinStudent *studentToUpdate;
            if ([arrayOfStudents count] > 0)
            {
                studentToUpdate = [arrayOfStudents objectAtIndex:0];
                idNumber = studentToUpdate.id_number;
            }
            
#ifdef DEBUG
            		NSLog(@"update %@ %@ %@ %@",studentToUpdate.id_number,studentToUpdate.student,studentToUpdate.last_name,studentToUpdate.last_update);
#endif
            
            //check "isCancelled" on either end of the fetch from webservice, as that's what takes the time
            if ([self isCancelled] == TRUE
                || idNumber == nil
                || sett.isProcessingSale
                || auth.isPosting
                ) {
                auth.isStudentChecking = false;
                return;
            }
            
            //fetch info from webservice
            
            
            //        NSDictionary *studentToUpdateAsDictionary = [WebService fetchStudentWithID:[studentToUpdate id_number]];
            //        [WebService fetchStudentWithID:[studentToUpdate id_number]];
            [WebService fetchStudentWithIDRecall:idNumber andMoc:moc];
#ifdef DEBUG
            endDate = [NSDate localDate];
            NSTimeInterval durationOfUpdate = [endDate timeIntervalSinceDate:startDate];
            //		NSLog(@"update student took:%.2f seconds",durationOfUpdate);
#endif
        }];
    }
}


@end

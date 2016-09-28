//
//  StudentUpdateObserver.m
//  OdinScanner
//
//  Created by Ken Thomsen on 3/14/13.
//
//

#import "StudentUpdateObserver.h"
#import "StudentUpdate.h"
#import "TransactionUpdate.h"

@implementation StudentUpdateObserver

@synthesize studentUpdateQueue;

-(id) initWithQueue:(NSOperationQueue *)newQueue
{
	if (self = [super init])
	{
		self.studentUpdateQueue = newQueue;
		return self;
	}
	return nil;
}

- (void) startStudentUpdates
{
    //TODO: check if this should really be every 10 seconds
	StudentUpdate *nextUpdate = [[StudentUpdate alloc] initWithDelay:2];
	//re-queue the student update upon completion
	[nextUpdate setCompletionBlock:^(void){
//        [AuthenticationStation sharedHandler].isStudentChecking = false;
		[self startStudentUpdates];
	}];
	[studentUpdateQueue addOperation:nextUpdate];
}
- (void) startTransactionUpdates
{
    //TODO: check if this should really be every 10 seconds
    TransactionUpdate *nextUpdate = [[TransactionUpdate alloc]initWithDelay:2];
    //re-queue the student update upon completion
    [nextUpdate setCompletionBlock:^(void){
        [AuthenticationStation sharedHandler].isTransactionChecking = false;
        [self startStudentUpdates];
    }];
    [studentUpdateQueue addOperation:nextUpdate];
}

@end

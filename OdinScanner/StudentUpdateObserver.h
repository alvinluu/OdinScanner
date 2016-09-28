//
//  StudentUpdateObserver.h
//  OdinScanner
//
//  Created by Ken Thomsen on 3/14/13.
//
//

#import <Foundation/Foundation.h>

@interface StudentUpdateObserver : NSObject

@property (nonatomic) NSOperationQueue *studentUpdateQueue;


-(id) initWithQueue:(NSOperationQueue *)newQueue;
- (void) startStudentUpdates;
- (void) startTransactionUpdates;
@end

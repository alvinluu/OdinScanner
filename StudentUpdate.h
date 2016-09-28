//
//  StudentUpdate.h
//  OdinScanner
//
//  Created by Ben McCloskey on 9/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StudentUpdateObserver.h"

@interface StudentUpdate : NSOperation

@property unsigned int sleepyTime;
@property NSObject *delegate;
@property StudentUpdateObserver *myObserver;


-(void) main;
-(StudentUpdate *) initWithDelay:(NSTimeInterval)sleepDelay;

@end

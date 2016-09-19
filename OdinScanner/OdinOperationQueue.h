//
//  OdinOperationQueue.h
//  OdinScanner
//
//  Created by Alvin Luu on 12/24/15.
//
//

#import <Foundation/Foundation.h>

@interface OdinOperationQueue : NSOperationQueue


+(OdinOperationQueue *)sharedHandler;
-(NSBlockOperation *)findOperationByReference:(NSString*)reference;
-(BOOL) cancelOperationByReference:(NSString*)reference;
-(BOOL) isExecutingByReference:(NSString*)reference;

@end

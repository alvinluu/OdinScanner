//
//  OdinOperationQueue.m
//  OdinScanner
//
//  Created by Alvin Luu on 12/24/15.
//
//

#import "OdinOperationQueue.h"

@implementation OdinOperationQueue

static OdinOperationQueue *sharedHandler = nil;
+(OdinOperationQueue *)sharedHandler
{
    @synchronized(self)
    {
        if (sharedHandler == nil)
            sharedHandler = [[OdinOperationQueue alloc] init];
    }
    return sharedHandler;
}
-(NSBlockOperation *)findOperationByReference:(NSString *)reference
{
    
    for (NSBlockOperation* block in [self operations]) {
#ifdef DEBUG
        NSLog(@"Checking operation name %@",block.name);
#endif
        if ([block.name isEqualToString:[SettingsHandler sharedHandler].currentReference]) {
#ifdef DEBUG
            NSLog(@"Found operation match name %@",block.name);
#endif
            return block;
        }
    }
    return nil;
}
-(BOOL)cancelOperationByReference:(NSString *)reference
{
    NSBlockOperation* block = [self findOperationByReference:reference];
    if (block) {
        
#ifdef DEBUG
        NSLog(@"cancel operation %@",block.name);
#endif

        [block cancel];
        
#ifdef DEBUG
        NSLog(@"%@ operation isCancelled %i isExecuting %i",block.name,[block isCancelled],[block isExecuting]);
#endif

    }
    
    return block ? true : false;
}
-(BOOL)isExecutingByReference:(NSString *)reference
{
    NSBlockOperation* block = [self findOperationByReference:reference];
    
    if (block) {
        if ([block isExecuting] && ![block isCancelled]) {
            return true;
        }
    }
    return false;
}
@end

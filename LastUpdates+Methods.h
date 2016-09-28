//
//  LastUpdates+Methods.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/19/12.
//
//

#import "LastUpdates.h"

@interface LastUpdates (Methods)

+ (LastUpdates *)getLastUpdatefromMOC:(NSManagedObjectContext *)moc;

- (NSDictionary *)asDictionary;

@end

//
//  LastUpdates+Methods.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/19/12.
//  Updated by Sparrow French on Oct 11 2013.
//

#import "LastUpdates+Methods.h"

@implementation LastUpdates (Methods)

//returns LastUpdate entry from CoreData
+ (LastUpdates *)getLastUpdatefromMOC:(NSManagedObjectContext *)moc
{
	LastUpdates *updates;
	
	NSArray *lastUpdatesArray = [CoreDataService getObjectsForEntity:@"LastUpdates" withSortKey:nil andSortAscending:NO andContext:moc];
	
	//if there's no entries, create one
	if ([lastUpdatesArray count] <= 0)
	{
		updates.lastAuth = [NSDate distantFuture];
		updates.lastItemUpdate = [NSDate distantFuture];
		updates.lastStudentUpdate = [NSDate distantFuture];
		updates.lastSerial = @"N";
		updates.lastUID = @"N";
		updates = [CoreDataService insertObjectForEntity:@"LastUpdates" andContext:moc];
		
		@synchronized([CoreDataService class])
		{
			//save our changes
			[CoreDataService saveObjectsInContext:moc];
		}
	}
	//if there's an entry, retrieve it
	else
	{
		updates = [lastUpdatesArray objectAtIndex:0];
	}
	
	return updates;
}

-(NSDictionary *)asDictionary{
	NSMutableDictionary *lastUpdateAsDictionary = [[NSMutableDictionary alloc] init];
	
	//[self dictionaryWithValuesForKeys:self.entity.attributesByName.allKeys];
	//[results setObject:propertyType forKey:propertyName];
	LastUpdates *lastUpdate = [LastUpdates getLastUpdatefromMOC:[CoreDataService getMainMOC]];
	if(lastUpdate.lastAuth != nil)
		[lastUpdateAsDictionary setObject:lastUpdate.lastAuth forKey:@"lastAuth"];
	if(lastUpdate.lastItemUpdate != nil)
		[lastUpdateAsDictionary setObject:lastUpdate.lastItemUpdate forKey:@"lastItemUpdate"];
	if(lastUpdate.lastStudentUpdate != nil)
		[lastUpdateAsDictionary setObject:lastUpdate.lastStudentUpdate forKey:@"lastStudentUpdate"];
	if(lastUpdate.lastSerial != nil)
		[lastUpdateAsDictionary setObject:lastUpdate.lastSerial forKey:@"lastSerial"];
	if(lastUpdate.lastUID !=nil)
		[lastUpdateAsDictionary setObject:lastUpdate.lastUID forKey:@"lastUID"];
#ifdef DEBUG
	NSLog(@"%@ As Dictionary:%@",[[self class] description],[lastUpdateAsDictionary description]);
#endif
	
	return [NSDictionary dictionaryWithDictionary:lastUpdateAsDictionary];
}

@end

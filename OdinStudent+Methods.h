//
//  OdinStudent+Methods.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/19/12.
//
//

#import "OdinStudent.h"

@interface OdinStudent (Methods)

+(NSDictionary *) getStudentInfoForID:(NSString *)idNumber andMOC:(NSManagedObjectContext *)managedObjectContext;
+(void) updateThisStudentWith:(NSDictionary *)studentFromWeb andMOC:(NSManagedObjectContext *)moc sync:(BOOL)sync;
+(OdinStudent *) getStudentObjectForID:(NSString *)idNumber andMOC:(NSManagedObjectContext *)managedObjectContext;

+(NSDictionary *) getStudentOfflineInfoForID:(NSString *)idNumber andMOC:(NSManagedObjectContext *)managedObjectContext;

+(NSString *) getStudentSecondaryEmailForID:(NSString *)idNumber;

+(NSArray*)getAllStudent;
+(NSArray*)getStudentsBySearch:(NSString *)searchString;
+(NSArray*)getStudentsBySearch:(NSString *)searchString withMOC:(NSManagedObjectContext*)moc;

+(OdinStudent*) getStudentByIDnumber:(NSString*)id_number;
+(int)count;
@end

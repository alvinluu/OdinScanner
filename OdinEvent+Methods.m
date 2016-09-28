//
//  OdinEvent+Methods.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/19/12.
//
//


#import "OdinEvent.h"
#import "OdinEvent+Methods.h"

@implementation OdinEvent (Methods)

-(OdinEvent *)loadValuesFromDictionaryRepresentation:(NSDictionary *)itemAsDictionary
{
    if ([itemAsDictionary objectForKey:@"amount"] && ![[itemAsDictionary objectForKey:@"amount"] isKindOfClass:[NSNull class]])
        self.amount = [itemAsDictionary objectForKey:@"amount"];
    
    if ([itemAsDictionary objectForKey:@"plu"] && ![[itemAsDictionary objectForKey:@"plu"] isKindOfClass:[NSNull class]])
        self.plu = [itemAsDictionary objectForKey:@"plu"];
    
    if ([itemAsDictionary objectForKey:@"item"] && ![[itemAsDictionary objectForKey:@"item"] isKindOfClass:[NSNull class]])
        self.item = [itemAsDictionary objectForKey:@"item"];
    
    //if no tax info, default to 0%
    if ([itemAsDictionary objectForKey:@"tax"] && ![[itemAsDictionary objectForKey:@"tax"] isKindOfClass:[NSNull class]])
        self.tax = [itemAsDictionary objectForKey:@"tax"];
    else
        self.tax = [NSDecimalNumber decimalNumberWithNumber:[NSNumber numberWithInt:0]];
    
    if ([itemAsDictionary objectForKey:@"location"] && ![[itemAsDictionary objectForKey:@"location"] isKindOfClass:[NSNull class]])
        self.location = [itemAsDictionary objectForKey:@"location"];
    
    if ([itemAsDictionary objectForKey:@"glcode"] && ![[itemAsDictionary objectForKey:@"glcode"] isKindOfClass:[NSNull class]])
        self.glcode = [itemAsDictionary objectForKey:@"glcode"];
    
    if ([itemAsDictionary objectForKey:@"barcode"] && ![[itemAsDictionary objectForKey:@"barcode"] isKindOfClass:[NSNull class]])
        self.barcode = [itemAsDictionary objectForKey:@"barcode"];
    
    if ([itemAsDictionary objectForKey:@"dept_code"] && ![[itemAsDictionary objectForKey:@"dept_code"] isKindOfClass:[NSNull class]])
        self.dept_code = [NSString stringWithFormat:@"%@", [itemAsDictionary objectForKey:@"dept_code"]];
    
    if ([itemAsDictionary objectForKey:@"qty"] && ![[itemAsDictionary objectForKey:@"qty"] isKindOfClass:[NSNull class]])
    {
        if ([[itemAsDictionary objectForKey:@"qty"] isEqualToNumber:[NSNumber numberWithInt:0]])
            self.qty = [NSNumber numberWithInt:1];
        else
            self.qty = [itemAsDictionary objectForKey:@"qty"];
    }
    if ([itemAsDictionary objectForKey:@"allow_qty"] && ![[itemAsDictionary objectForKey:@"allow_qty"] isKindOfClass:[NSNull class]])
        self.allow_qty = [itemAsDictionary objectForKey:@"allow_qty"];
    
    if ([itemAsDictionary objectForKey:@"allow_amount"] && ![[itemAsDictionary objectForKey:@"allow_amount"] isKindOfClass:[NSNull class]])
        self.allow_amount = [itemAsDictionary objectForKey:@"allow_amount"];
    
    if ([itemAsDictionary objectForKey:@"allow_item"] && ![[itemAsDictionary objectForKey:@"allow_item"] isKindOfClass:[NSNull class]])
        self.allow_item = [itemAsDictionary objectForKey:@"allow_item"];
    
    if ([itemAsDictionary objectForKey:@"chk_balance"] && ![[itemAsDictionary objectForKey:@"chk_balance"] isKindOfClass:[NSNull class]])
        self.chk_balance = [itemAsDictionary objectForKey:@"chk_balance"];
    
    if ([itemAsDictionary objectForKey:@"lock_cfg"] && ![[itemAsDictionary objectForKey:@"lock_cfg"] isKindOfClass:[NSNull class]])
        self.lock_cfg = [itemAsDictionary objectForKey:@"lock_cfg"];
    
    if ([itemAsDictionary objectForKey:@"allow_edit"] && ![[itemAsDictionary objectForKey:@"allow_edit"] isKindOfClass:[NSNull class]])
        self.allow_edit = [itemAsDictionary objectForKey:@"allow_edit"];
    
    if ([itemAsDictionary objectForKey:@"allow_manual_id"] && ![[itemAsDictionary objectForKey:@"allow_manual_id"] isKindOfClass:[NSNull class]])
        self.allow_manual_id = [itemAsDictionary objectForKey:@"allow_manual_id"];
    
    if ([itemAsDictionary objectForKey:@"allow_stock"] && ![[itemAsDictionary objectForKey:@"allow_stock"] isKindOfClass:[NSNull class]])
        self.allow_stock = [itemAsDictionary objectForKey:@"allow_stock"];
    
    if ([itemAsDictionary objectForKey:@"stock_name"] && ![[itemAsDictionary objectForKey:@"stock_name"] isKindOfClass:[NSNull class]])
        self.stock_name = [itemAsDictionary objectForKey:@"stock_name"];
    
    if ([itemAsDictionary objectForKey:@"school"] && ![[itemAsDictionary objectForKey:@"school"] isKindOfClass:[NSNull class]])
        self.school = [itemAsDictionary objectForKey:@"school"];
    
    if ([itemAsDictionary objectForKey:@"friendly"] && ![[itemAsDictionary objectForKey:@"friendly"] isKindOfClass:[NSNull class]])
        self.operator = [itemAsDictionary objectForKey:@"friendly"];
    
    if ([itemAsDictionary objectForKey:@"taxable"] && ![[itemAsDictionary objectForKey:@"taxable"] isKindOfClass:[NSNull class]])
        self.taxable = [itemAsDictionary objectForKey:@"taxable"];
    
    if ([itemAsDictionary objectForKey:@"process_on_sync"] && ![[itemAsDictionary objectForKey:@"process_on_sync"] isKindOfClass:[NSNull class]])
        self.process_on_sync = [itemAsDictionary objectForKey:@"process_on_sync"];
    else
        self.process_on_sync = [NSNumber numberWithInt:0];
    
#ifdef DEBUG
    NSLog(@"Item Added: %@ %@ on_synce(%@) %.2f", self.item, self.barcode, self.process_on_sync, self.tax.floatValue);
#endif
    return self;
}

+(OdinEvent *)searchForItemWithBarcode:(NSString*)barcode
{
    NSArray *itemsWithBarcode = [CoreDataService searchObjectsForEntity:@"OdinEvent"
                                                          withPredicate:[NSPredicate predicateWithFormat:@"barcode == %@",barcode]
                                                             andSortKey:nil
                                                       andSortAscending:NO
                                                             andContext:[CoreDataService getMainMOC]];
    if ([itemsWithBarcode count] > 0)
    {
        OdinEvent *selectedItem = [itemsWithBarcode objectAtIndex:0];
        return selectedItem;
    }
    else
        return nil;
}
+(OdinEvent *)searchForItemWithPLU:(NSString*)plu
{
    NSArray *itemsWithBarcode = [CoreDataService searchObjectsForEntity:@"OdinEvent"
                                                          withPredicate:[NSPredicate predicateWithFormat:@"plu == %@",plu]
                                                             andSortKey:nil
                                                       andSortAscending:NO
                                                             andContext:[CoreDataService getMainMOC]];
    if ([itemsWithBarcode count] > 0)
    {
        OdinEvent *selectedItem = [itemsWithBarcode objectAtIndex:0];
        return selectedItem;
    }
    else
        return nil;
}
+(NSArray*)getAllItems
{
    NSManagedObjectContext* moc = [CoreDataService getMainMOC];
    //    [CoreDataService saveObjectsInContext:self.moc];
    NSArray *arrayOfTransaction = [CoreDataService searchObjectsForEntity:@"OdinEvent"
                                                            withPredicate:nil
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:moc];
    
    if (@(arrayOfTransaction.count) > 0) {
        return arrayOfTransaction;
    }
    return nil;
    
}
+(NSArray*)getItemsBySearch:(NSString *)searchString
{
    NSManagedObjectContext* moc = [CoreDataService getMainMOC];
    if ([searchString isEqualToString:@""] || searchString == nil) {
        NSArray *allItems = [CoreDataService searchObjectsForEntity:@"OdinEvent"
                                                      withPredicate:nil
                                                         andSortKey:@"item"
                                                   andSortAscending:YES
                                                         andContext:moc];
        return allItems;
    }
    
    NSArray *allItems = [CoreDataService searchObjectsForEntity:@"OdinEvent"
                                                  withPredicate:[NSPredicate predicateWithFormat:@"item contains[c] %@ or plu beginswith[c] %@",searchString,searchString]
                                                     andSortKey:@"item"
                                               andSortAscending:YES
                                                     andContext:moc];
    return allItems;
}
+(int)count
{
    return [CoreDataHelper countForEntity:@"OdinEvent" andContext:[CoreDataHelper getMainMOC]];
}

@end

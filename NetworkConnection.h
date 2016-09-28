//
//  NetworkConnection.h
//  OdinScanner
//
//  Created by Ken Thomsen on 12/13/13.
//
//

#import <Foundation/Foundation.h>

@interface NetworkConnection : NSObject

+(BOOL) isInternetOffline;
+(BOOL) isInternetOnline;

@end

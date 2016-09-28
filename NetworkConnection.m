//
//  NetworkConnection.m
//  OdinScanner
//
//  Created by Ken Thomsen on 12/13/13.
//
//

#import "NetworkConnection.h"
#import "Reachability.h"

@implementation NetworkConnection

+(BOOL)isInternetOffline {
	
	Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
	
	if (networkStatus == NotReachable) {
#ifdef DEBUG
		NSLog(@"There is no internet connection");
#endif
	} else {
		
#ifdef DEBUG
		NSLog(@"There is internet connection");
#endif
	}
	return (networkStatus == NotReachable);
	
}

+(BOOL)isInternetOnline {
    return ![self isInternetOffline];
}
@end

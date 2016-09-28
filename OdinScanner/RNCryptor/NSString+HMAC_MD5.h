//
//  NSString+HMAC_MD5.h
//  My Kids Spending
//
//  Created by KenThomsen on 3/7/14.
//
//

#import <Foundation/Foundation.h>

@interface NSString (HMAC_MD5)
-(NSString*) encryptMessage;
- (NSString*) HMACWithSecret:(NSString*) secret;
@end

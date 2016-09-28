//
//  NSString+HMAC_MD5.m
//  My Kids Spending
//
//  Created by KenThomsen on 3/7/14.
//
//

#import "NSString+HMAC_MD5.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

#include <sys/types.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

@implementation NSString (HMAC_MD5)
-(NSString*) encryptMessage
{
	//NSString *strToEncrypt  = [NSString stringWithFormat:@"%@",message];
	
	//Add HASH balance
	NSString *key        = @"T8xkoI32o9aEv3e8vAG9zZ20";
	NSString *hexHmac       = [self HMACWithSecret:key];
	
	
	NSString* message = [NSString stringWithFormat:@"\"hash\":%@",hexHmac];
	
	return message;
}
- (NSString*) HMACWithSecret:(NSString*) secret
{
    CCHmacContext    ctx;
    const char       *key = [secret UTF8String];
    const char       *str = [self UTF8String];
    unsigned char    mac[CC_MD5_DIGEST_LENGTH];
    char             hexmac[2 * CC_MD5_DIGEST_LENGTH + 1];
    char             *p;
	
    CCHmacInit( &ctx, kCCHmacAlgMD5, key, strlen( key ));
    CCHmacUpdate( &ctx, str, strlen(str) );
    CCHmacFinal( &ctx, mac );
	
    p = hexmac;
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++ ) {
        snprintf( p, 3, "%02x", mac[ i ] );
        p += 2;
    }
	
    return [NSString stringWithUTF8String:hexmac];
}

@end

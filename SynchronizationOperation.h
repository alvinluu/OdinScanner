//
//  SynchronizationOperation.h
//  OdinScanner
//
//  Created by Ben McCloskey on 2/9/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SynchronizationOperation : NSObject

+(void) syncSettings;

+(void)updateSettings:(NSDictionary *)syncData;
@end

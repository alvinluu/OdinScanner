//
//  SynchronizationOperation.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/9/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "SynchronizationOperation.h"
//#import "AuthenticationStation.h"
#import "OdinEvent.h"
#import "OdinStudent.h"
#import "LastUpdates+Methods.h"
#import "SBJSON.h"
#import "Linea.h"

@interface SynchronizationOperation ()

//+(void) updateItemList;
+(void) updateServerSettingsFromData:(NSDictionary *)serverData;
+(void) updatePreferencesFromData:(NSDictionary *)prefData;
+(void) updateSettings:(NSDictionary *)syncData;

@end

@implementation SynchronizationOperation

+(void) syncSettings
{
#ifdef DEBUG
	NSLog(@"syncSettings");
#endif
	
//	DTDevices *dtdev = [DTDevices sharedDevice];
#ifdef DEBUG
//	NSLog(@"%@",dtdev);
#endif
//	if (dtdev) {
//		[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_DISABLED error:nil];
//	}
	
	[SynchronizationOperation updateSettings:[AuthenticationStation sharedHandler].syncData];
	
//	if (dtdev) {
//		[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
//	}
}

+(void)updateSettings:(NSDictionary *)syncData
{
	
	[SynchronizationOperation updateServerSettingsFromData:syncData];
	[SynchronizationOperation updatePreferencesFromData:syncData];
	
}

+(void) updateServerSettingsFromData:(NSDictionary *)serverData
{
	
#ifdef DEBUG
	NSLog(@"Perparing to update server info:%@",[serverData description]);
#endif
	if ([serverData objectForKey:@"server"])
		[[SettingsHandler sharedHandler] setServerHost:[serverData objectForKey:@"server"]];
	
	if ([serverData objectForKey:@"user"])
		[[SettingsHandler sharedHandler] setServerUsername:[serverData objectForKey:@"user"]];
	
	if ([serverData objectForKey:@"db"])
		[[SettingsHandler sharedHandler] setServerSchema:[serverData objectForKey:@"db"]];
	
	if ([serverData objectForKey:@"port"])
		[[SettingsHandler sharedHandler] setServerPort:[[serverData objectForKey:@"port"] intValue]];
	
	if ([serverData objectForKey:@"MSSQL"])
		[[SettingsHandler sharedHandler] setIsMSSQL:[[serverData objectForKey:@"MSSQL"] boolValue]];
	
#ifdef DEBUG
	NSLog(@"Saved Server Settings");
#endif
}

+(void) updatePreferencesFromData:(NSDictionary *)prefData
{
    
    
#ifdef DEBUG
    NSLog(@"Perparing to update preferences info:%@",[prefData description]);
#endif
	if ([prefData objectForKey:@"scan_barcode"])
		[[SettingsHandler sharedHandler] setUseBarcode:[[prefData objectForKey:@"scan_barcode"] boolValue]];
	
	if ([prefData objectForKey:@"scan_exportid"])
		[[SettingsHandler sharedHandler] setUseExportID:[[prefData objectForKey:@"scan_exportid"] boolValue]];
	
	if ([prefData objectForKey:@"school"])
		[[SettingsHandler sharedHandler] setSchool:[prefData objectForKey:@"school"]];
	
	if ([prefData objectForKey:@"check_balance"])
		[[SettingsHandler sharedHandler] setCheckBalance:[[prefData objectForKey:@"check_balance"] boolValue]];
    
    if ([prefData objectForKey:@"allow_override"])
        [[SettingsHandler sharedHandler] setAllowOverride:[[prefData objectForKey:@"allow_override"] boolValue]];
    
	if ([prefData objectForKey:@"PHPpath"])
	{
		NSString *phpPath = [prefData objectForKey:@"PHPpath"];
		NSString *basePrefix = [[SettingsHandler sharedHandler] basePrefix];
		if (([phpPath hasPrefix:basePrefix] == false) && !([[phpPath substringWithRange:NSMakeRange(0,4)] isEqualToString:@"http"]))
			phpPath = [NSString stringWithFormat:@"%@%@",basePrefix, phpPath];
		NSURL *portablePath = [NSURL URLWithString:phpPath];
		[[AuthenticationStation sharedHandler] setPortableServicePath:portablePath];
	}
	
#ifdef DEBUG
	NSLog(@"Saved School-specific Settings");
#endif
}

@end

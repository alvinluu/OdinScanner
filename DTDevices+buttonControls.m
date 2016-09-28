//
//  DTDevices+buttonControls.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/15/13.
//
//

#import "DTDevices+buttonControls.h"

@interface DTDevices ()

@property int initScanMode;

@end

@implementation DTDevices (buttonControls)



-(void) disableButton
{
	
	DTDevices *dtdev = [DTDevices sharedDevice];
//	if ([dtdev isPresent:DEVICE_TYPE_LINEA]) {
		//if button is enabled, then disable
//		if (([[DTDevices sharedDevice] connstate] == CONN_CONNECTED)
//			&& ([[DTDevices sharedDevice] barcodeGetScanButtonMode:BUTTON_DISABLED error:nil] == FALSE))
//		{
			[[DTDevices sharedDevice] barcodeStopScan:nil];
			[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_DISABLED error:nil];
			
//		}
		
//	}
}


-(void) enableButton
{
	DTDevices *dtdev = [DTDevices sharedDevice];
//	if ([dtdev isPresent:DEVICE_TYPE_LINEA]) {
		//if button is disabled, then enable
//		if (([[DTDevices sharedDevice] connstate] == CONN_CONNECTED)
//			&& ([[DTDevices sharedDevice] barcodeGetScanButtonMode:BUTTON_DISABLED error:nil]))
//		{
			[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
			//this prevents the button from requiring a "dummy" press in order to scan again.
			[[DTDevices sharedDevice] barcodeStartScan:nil];
			[[DTDevices sharedDevice] barcodeStopScan:nil];
//		}
//	}
}

-(void) badBeep
{
	DTDevices *dtdev = [DTDevices sharedDevice];
//	if ([dtdev isPresent:DEVICE_TYPE_LINEA]) {
		int beepData[] = {250,300,0,50,250,300};
		NSError *error = nil;
		[[DTDevices sharedDevice] playSound:80 beepData:beepData length:sizeof(beepData) error:&error];
//	}
}


@end


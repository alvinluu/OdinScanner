//
//  SettingViewController.m
//  OdinScanner
//
//  Created by KenThomsen on 2/26/14.
//
//

#import "SettingVC.h"

@interface SettingVC ()
@property (strong, nonatomic) IBOutlet UITextView *settingTextField;

@end

@implementation SettingVC

static NSString *settings[]={
	@"Beep upon scan",
	@"Enable scan button",
	@"Automated charge enabled",
	@"Reset barcode engine",
	@"Enable external speaker",
	@"Enable pass-through sync",
	@"Enable 1A USB charging (!!)",
	@"Vibrate on barcode scan",
};

enum SETTINGS{
	SET_BEEP=0,
	SET_ENABLE_SCAN_BUTTON,
	SET_AUTOCHARGING,
	SET_RESET_BARCODE,
	SET_ENABLE_SPEAKER,
	SET_ENABLE_SYNC,
    SET_CHARGE_1A,
    SET_VIBRATE,
    SET_LAST
};


static NSString *scan_modes[]={
	@"Single scan",
	@"Multi scan",
	@"Motion detect",
	@"Single scan on button release",
    @"Multi scan without duplicates",
};

static NSString *section_names[]={
	@"General Settings",
	@"Barcode Scan Mode",
	@"LED Control",
	@"Bluetooth Client",
	@"Bluetooth Server",
    @"TCP/IP Devices",
    @"Firmware Update",
    @"Voltage",
};

static NSString *voltage_settings[]={
	@"Display info",
	@"Set parameters",
	@"Generate new key",
};


static NSString *led_names[]={
    @"Green",
    @"Red",
    @"Orange",
    @"Blue",
};

static uint32_t led_bits[]={
    0x00000001,
    0x00000002,
    0x00000003,
    0x00000004,
};

static UIColor *led_colors[4];

enum SECTIONS{
    SEC_GENERAL=0,
    SEC_BARCODE_MODE,
    SEC_LEDS,
    SEC_BT_CLIENT,
    SEC_BT_SERVER,
    SEC_TCP_DEVICES,
    SEC_FIRMWARE_UPDATE,
    SEC_VOLTAGE,
    SEC_LAST
};


enum UPDATE_TARGETS{
    TARGET_DEVICE=0,
    TARGET_BARCODE,
};

#define SHOWERR(func) func; if(error)[scannerViewController debug:error.localizedDescription];
#define ERRMSG(title) {UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil]; [alert show];}

static BOOL settings_values[SET_LAST];

int beep1[]={2730,250};
int beep2[]={2730,150,65000,20,2730,150};

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
#pragma mark - View
- (void)viewWillAppear:(BOOL)animated
{
	[supplementalSwitch setOn:[[SettingsHandler sharedHandler] isSupplemental]];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)viewDidAppear:(BOOL)animated
{
	
	[self refreshLinea];
#ifdef DEBUG
	NSString *devicDetail = @"";
	devicDetail = [devicDetail stringByAppendingString:@"Version: " ];
	devicDetail = [devicDetail stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	devicDetail = [devicDetail stringByAppendingString:@"\nSerial: "];
//	if ([dtdev serialNumber]) {
//		devicDetail = [devicDetail stringByAppendingString:[dtdev serialNumber]];
//	} else
    devicDetail = [devicDetail stringByAppendingString:[AuthenticationStation sharedHandler].serialNumber];
	devicDetail = [devicDetail stringByAppendingString:@"\nDatabase: "];
	devicDetail = [devicDetail stringByAppendingString:[SettingsHandler sharedHandler].serverHost];
	devicDetail = [devicDetail stringByAppendingString:@"\nServer: "];
	devicDetail = [devicDetail stringByAppendingString:[[SettingsHandler sharedHandler].portablePath absoluteString]];
	devicDetail = [devicDetail stringByAppendingString:@"\nSchool: "];
	devicDetail = [devicDetail stringByAppendingString:[SettingsHandler sharedHandler].school];
	devicDetail = [devicDetail stringByAppendingString:@"\nUID: "];
	devicDetail = [devicDetail stringByAppendingString:[SettingsHandler sharedHandler].uid];
	devicDetail = [devicDetail stringByAppendingString:@"\nReference: "];
	devicDetail = [devicDetail stringByAppendingString:[[SettingsHandler sharedHandler] getReference]];
	
	_settingTextField.text = devicDetail;
	_settingTextField.hidden = NO;
#endif
}
-(void)viewWillDisappear:(BOOL)animated
{
	[self disconnectLinea];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) {
		return 2;
	} else if (section == 1) {
		return 1;
	}
    // Return the number of rows in the section.
    return 0;
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"deselect");
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
#ifdef DEBUG
	NSLog(@"Open Setting View");
#endif
	//Hacky way of turning table rows into buttons (necessary to keep correct highlighting)
	
	if (indexPath.section == 0)
	{
		if (indexPath.row == 0)
		{
#ifdef DEBUG
			NSLog(@"Update device firmware");
#endif
			firmareTarget = indexPath.row;
			[self checkForFirmwareUpdate];
		}
		else if (indexPath.row == 1)
		{
#ifdef DEBUG
			NSLog(@"Update barcode firmware");
#endif
			firmareTarget = indexPath.row;
			
			if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_OPTICON)
			{
				[self checkForOpticonFirmwareUpdate];
			}
			if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_CODE)
			{
				[self checkForCodeFirmwareUpdate];
			}
			if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_NEWLAND)
			{
				[self checkForNewlandFirmwareUpdate];
			}
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}
#pragma mark - HUD
-(void)showActivity
{
	HUD = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
	
	[[UIApplication sharedApplication].keyWindow addSubview:HUD];
	
	HUD.delegate = self;
	HUD.labelText = @"Progressing";
	HUD.detailsLabelText = @"downloading";
	[HUD show:YES];
	
}
-(void)hidActivity
{
	[HUD hide:YES];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==0)
    {//firmware update
        if(buttonIndex == 1)
        {
            //Make firmware update prettier - call it from a thread and listen to the notifications only
			progressViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"FirmwareProgress"];
            [self.view addSubview:progressViewController.view];
			[self firmwareUpdateProgress:0 percent:0];
			sleep(2);
			
            [NSThread detachNewThreadSelector:@selector(firmwareUpdateThread:) toTarget:self withObject:firmwareFile];
        }
    }
    if(alertView.tag==1)
    {//enable 1A charging
        NSError *error;
        if(![dtdev setUSBChargeCurrent:settings_values[SET_CHARGE_1A]?1000:500 error:&error])
        {
            settings_values[SET_CHARGE_1A]=FALSE;
            ERRMSG(NSLocalizedString(@"Command failed",nil));
        }
        //[settingsTable reloadData];
    }
}
#pragma mark - Firmware

-(NSString *)getFirmwareFileName
{
	//    {
	//        NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Firmware"];
	//        return [path stringByAppendingPathComponent:@"LINEAPro5_NBPMEV_06.05.26.00.BIN"];
	//    }
	
	
	NSMutableString *s=[[NSMutableString alloc] init];
	NSError *error;
	NSString *name=[[dtdev.deviceName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
	NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Firmware"];
	NSArray *files=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
	
	
	int lastVer=0;
	NSString *lastPath;
	for(int i=0;i<[files count];i++)
	{
		NSString *file=[[files objectAtIndex:i] lastPathComponent];
		if([[file lowercaseString] hasSuffix:@".bin"])
		{
			if([[file lowercaseString] rangeOfString:name].location!=NSNotFound)
			{
				NSData *data=[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:file] options:nil error:&error];
				NSDictionary *info=[dtdev getFirmwareFileInformation:data error:&error];
				if(info)
				{
					NSLog(@"file: %@, name=%@, model=%@",file,[info objectForKey:@"deviceName"],[info objectForKey:@"deviceModel"]);
					[s appendFormat:@"file: %@, name=%@, model=%@\n",file,[info objectForKey:@"deviceName"],[info objectForKey:@"deviceModel"]];
				}
				
				if(info && [[info objectForKey:@"deviceName"] isEqualToString:dtdev.deviceName] && [self isDeviceModelEqual:[info objectForKey:@"deviceModel"]]/*[[info objectForKey:@"deviceModel"] isEqualToString:dtdev.deviceModel] */&& [[info objectForKey:@"firmwareRevisionNumber"] intValue]>lastVer)
				{
					lastPath=[path stringByAppendingPathComponent:file];
					lastVer=[[info objectForKey:@"firmwareRevisionNumber"] intValue];
				}
			}
		}
	}
	if(lastVer>0)
		return lastPath;
	return nil;
}-(bool)isDeviceModelEqual:(NSString *)model
{
    if(model.length!=dtdev.deviceModel.length)
        return false;
	
    for(int i=0;i<model.length;i+=2)
    {
        NSString *feat=[model substringWithRange:NSMakeRange(i,2)];
        if([dtdev.deviceModel rangeOfString:feat].length==0)
            return false;
    }
    return true;
}
-(void)firmwareUpdateProgress:(int)phase percent:(int)percent
{
	NSLog(@"update progress %i percent %i",phase,percent);
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (phase)
        {
            case UPDATE_INIT:
                [progressViewController updateProgress:NSLocalizedString(@"Initializing update...",nil) progress:percent];
                break;
            case UPDATE_ERASE:
                [progressViewController updateProgress:NSLocalizedString(@"Erasing flash...",nil) progress:percent];
                break;
            case UPDATE_WRITE:
                [progressViewController updateProgress:NSLocalizedString(@"Writing firmware...",nil) progress:percent];
                break;
            case UPDATE_COMPLETING:
                [progressViewController updateProgress:NSLocalizedString(@"Completing operation...",nil) progress:percent];
                break;
            case UPDATE_FINISH:
                [progressViewController updateProgress:NSLocalizedString(@"Complete!",nil) progress:percent];
                break;
        }
    });
}
-(void)firmwareUpdateThread:(NSString *)file
{
	@autoreleasepool {
		NSLog(@"firmwareUpdateThread");
        NSError *error=nil;
		
        BOOL idleTimerDisabled_Old=[UIApplication sharedApplication].idleTimerDisabled;
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
        
        if(firmareTarget==TARGET_DEVICE)
        {
			NSLog(@"firmwareTarget == Target_Device");
            [progressViewController performSelectorOnMainThread:@selector(updateText:) withObject:@"Updating Linea...\nPlease wait!" waitUntilDone:NO];
            
            //In case authentication key is present in Linea, we need to authenticate with it first, before firmware update is allowed
            //For the sample here I'm using the field "Authentication key" in the crypto settings as data and generally ignoring the result of the
            //authentication operation, firmware update will just fail if authentication have failed
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            //last used decryption key is stored in preferences
            NSString *authenticationKey=[prefs objectForKey:@"AuthenticationKey"];
            if(authenticationKey==nil || authenticationKey.length!=32)
                authenticationKey=@"11111111111111111111111111111111"; //sample default
            
            [dtdev cryptoAuthenticateHost:[authenticationKey dataUsingEncoding:NSASCIIStringEncoding] error:nil];
			[self firmwareUpdateProgress:2 percent:40];
            [dtdev updateFirmwareData:[NSData dataWithContentsOfFile:file] error:&error];
			[self firmwareUpdateProgress:3 percent:60];
			sleep(2);
        }
        if(firmareTarget==TARGET_BARCODE)
        {
            if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_OPTICON)
            {
                NSString *file09=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Opticon_FL49J09.bin"];
                NSFileManager *fileManager=[NSFileManager defaultManager];
                
                if([fileManager fileExistsAtPath:file09])
                {
                    [progressViewController performSelectorOnMainThread:@selector(updateText:) withObject:@"Updating to version Opticon_FL49J09...\nPlease wait!" waitUntilDone:NO];
                    [dtdev barcodeOpticonUpdateFirmware:[NSData dataWithContentsOfFile:file09] bootLoader:FALSE error:&error];
                }
            }
            if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_CODE)
            {
                [progressViewController performSelectorOnMainThread:@selector(updateText:) withObject:@"Updating engine...\nPlease wait!" waitUntilDone:NO];
                [dtdev barcodeCodeUpdateFirmware:[firmwareFile lastPathComponent] data:[NSData dataWithContentsOfFile:firmwareFile] error:&error];
            }
            
        }
		
        [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled_Old];
        [self performSelectorOnMainThread:@selector(firmwareUpdateEnd:) withObject:error waitUntilDone:FALSE];
		
    }
}
-(void)firmwareUpdateEnd:(NSError *)error
{
	NSLog(@"firmwareUpdateEnd");
	[self firmwareUpdateProgress:4 percent:100];
	sleep(2);
    [progressViewController.view removeFromSuperview];
    if(error)
        [self displayAlert:NSLocalizedString(@"Firmware Update",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Firmware updated failed with error:%@",nil),error.localizedDescription]];
}
-(void)checkForFirmwareUpdate;
{
	firmwareFile=[self getFirmwareFileName];
	if(firmwareFile==nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
														message:NSLocalizedString(@"No firmware for this device model present",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil, nil];
		[alert show];
	}else {
        NSDictionary *info=[dtdev getFirmwareFileInformation:[NSData dataWithContentsOfFile:firmwareFile] error:nil];
		
		//Upgrade if the firmware is later than device model
		if(info && [[info objectForKey:@"deviceName"] isEqualToString:dtdev.deviceName] && [[info objectForKey:@"deviceModel"] compare:dtdev.deviceModel options:NSNumericSearch] )
		{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Device ver: %@\nAvailable: %@\n\nDo you want to update firmware?\n\nDO NOT DISCONNECT DEVICE DURING FIRMWARE UPDATE!",nil),[dtdev firmwareRevision],[info objectForKey:@"firmwareRevision"]]
                                                           delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Update",nil), nil];
            [alert show];
		}else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
															message:[NSString stringWithFormat:NSLocalizedString(@"Device ver: %@\n\nNo firmware for this device model present",nil),[dtdev firmwareRevision]] delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil, nil];
			[alert show];
		}
	}
}

-(void)checkForOpticonFirmwareUpdate;
{
    firmwareFile=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Opticon_FL49J09.bin"];
    NSString *opticonIdent=[dtdev barcodeOpticonGetIdent:nil];
    
	if(firmwareFile==nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
														message:NSLocalizedString(@"No firmware for this device model present",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil, nil];
		[alert show];
	}else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Current engine firmware: %@\n\nDo you want to update firmware?\n\nDO NOT DISCONNECT DEVICE DURING FIRMWARE UPDATE!",nil),opticonIdent]
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Update",nil), nil];
        [alert show];
	}
}

-(void)checkForCodeFirmwareUpdate;
{
    //firmwareFile=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"C005922_0674-system-cr8000-CD_GEN.crz"];
	
	firmwareFile=[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Firmware"] stringByAppendingPathComponent:@"C005922_0674-system-cr8000-CD_GEN.crz"];
	if(firmwareFile==nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
														message:NSLocalizedString(@"No firmware for this device model present",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil, nil];
		[alert show];
    }else
    {
        NSDictionary *info=[dtdev barcodeCodeGetInformation:nil];
        if(!info)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                            message:NSLocalizedString(@"Code engine not present or not responding",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil, nil];
            [alert show];
        }else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                            message:[NSString stringWithFormat:@"Reader info:\n%@\nDo you want to update engine firmware?",info]
                                                           delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Update",nil), nil];
            [alert show];
        }
    }
}

-(void)checkForNewlandFirmwareUpdate;
{
    //just show info for now
    NSError *error;
    NSData *r;
    uint8_t cmdVer[]={0x33,0x47};
    r=[dtdev barcodeNewlandQuery:[NSData dataWithBytes:cmdVer length:sizeof(cmdVer)] error:&error];
    if(r)
    {
        NSString *ver=[[NSString alloc] initWithData:r encoding:NSASCIIStringEncoding];
        [self displayAlert:@"Firmware info" message:[NSString stringWithFormat:@"Version: %@\n",ver]];
    }
}
-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

#pragma mark - UI Action
- (IBAction)supplementalToggle:(id)sender {
	[[SettingsHandler sharedHandler] setSupplemental:supplementalSwitch.on];
	
	//restart Linea device to change scan mode
	[[DTDevices sharedDevice] disableButton];
	[dtdev disconnect];
	[dtdev connect];
	[[DTDevices sharedDevice] enableButton];
}
#pragma mark - Linea
-(void)connectionState:(int)state
{
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
			break;
		case CONN_CONNECTED:
			;
            //Turn on the beep
			NSError *error;
            int beepData[] = {1200,100};
			//DTDevices *dtdev = [DTDevices sharedDevice];
            [dtdev barcodeSetScanMode:0 error:nil];
			[dtdev barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
			[dtdev msSetCardDataMode:MS_PROCESSED_CARD_DATA error:nil];
			[dtdev barcodeSetScanBeep:TRUE volume:10 beepData:beepData length:sizeof(beepData) error:nil];
			
			
			if ([[SettingsHandler sharedHandler] isSupplemental]) { //enable supplemental upc/ean
#ifdef DEBUG
				NSLog(@"enable supplemental");
#endif
				if ([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_OPTICON) {
					[dtdev barcodeOpticonSetInitString:@"R2R3R5R6" error:&error];
				}
			} else {
#ifdef DEBUG
				NSLog(@"disable supplemental");
#endif
				if ([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_OPTICON) {
					[dtdev barcodeOpticonSetInitString:@"[X4N[X4P[X4M[X4O" error:&error];
					[dtdev barcodeOpticonSetInitString:@"[V2A[V3A[V2B[V3B[V2C[V3C" error:&error];
				}
			}
			break;
	}
}

//Fires when a barcode is scanned
-(void) barcodeData:(NSString *)scannedBarcode type:(int)type
{
#ifdef DEBUG
    NSLog(@"barcode %@", scannedBarcode);
#endif
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end

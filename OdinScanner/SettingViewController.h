//
//  SettingViewController.h
//  OdinScanner
//
//  Created by KenThomsen on 2/26/14.
//
//

#import <UIKit/UIKit.h>
#import "ProgressVC.h"

@interface SettingViewController : UITableViewController <DTDeviceDelegate, UITableViewDelegate, UIAlertViewDelegate, MBProgressHUDDelegate>{
	DTDevices *dtdev;
	NSString *firmwareFile;
    int firmareTarget;
	ProgressVC *progressViewController;
	MBProgressHUD *HUD;
	IBOutlet UISwitch *supplementalSwitch;
}
@end

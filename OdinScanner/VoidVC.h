//
//  VoidVC.h
//  OdinScanner
//
//  Created by KenThomsen on 11/13/14.
//
//

#import <UIKit/UIKit.h>
//#import "MBProgressHUD.h"
#import "OdinViewController.h"
#import "DTDevices.h"
#import "HUDsingleton.h"

@interface VoidVC : OdinViewController <MBProgressHUDDelegate,
UITableViewDelegate,
UITableViewDataSource,
UIActionSheetDelegate>


@property (nonatomic, strong) OdinTransaction *selectedItem;

@end

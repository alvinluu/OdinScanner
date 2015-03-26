//
//  VoidVC.h
//  OdinScanner
//
//  Created by KenThomsen on 11/13/14.
//
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "OdinViewController.h"
#import "DTDevices.h"

@interface VoidVC : OdinViewController <MBProgressHUDDelegate,
UITableViewDelegate,
UITableViewDataSource,
UIActionSheetDelegate,
DTDeviceDelegate>


@property (nonatomic, strong) OdinTransaction *selectedItem;

@end

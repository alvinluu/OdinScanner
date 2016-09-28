//
//  AddEditItemViewController.h
//  Scanner
//
//  Created by Ben McCloskey on 12/19/11.
//  Copyright (c) 2011 Odin Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OdinEvent.h"
#import "EventsViewController.h"
#import "MBProgressHUD.h"

@interface zzAddEditItemVC : UITableViewController


@property (assign) BOOL isEditing;
@property (nonatomic, strong) OdinEvent *selectedItem;

@end

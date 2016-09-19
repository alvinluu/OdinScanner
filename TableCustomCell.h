//
//  TableCustomCell.h
//  OdinScanner
//
//  Created by Alvin Luu on 2/10/16.
//
//

#import <UIKit/UIKit.h>

@interface TableCustomCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) IBOutlet UILabel *detail2;
@property (weak, nonatomic) IBOutlet UIButton *accessoryButton;

@end

//
//  Patron.h
//  OdinScanner
//
//  Created by Alvin Luu on 1/26/16.
//
//

#import <UIKit/UIKit.h>
@protocol PatronDelegate
@required
- (void) closePatron:(OdinStudent*)student;
@end


@interface Patron : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (retain) id delegate;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UITextField *searchField;


- (Patron*)initWithSourceView:(UIView*)source;

@end


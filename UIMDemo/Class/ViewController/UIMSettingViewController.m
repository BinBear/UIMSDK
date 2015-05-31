//
//  UIMSettingViewController.m
//  UIMSDK
//
//  Created by HuangRetso on 5/30/15.
//  Copyright (c) 2015 Retso Huang. All rights reserved.
//

#import "UIMSettingViewController.h"

///--------------------
/// @name View Model
///--------------------
#import "UIMSDKService.h"

@interface UIMSettingViewController ()
@property (weak, nonatomic) IBOutlet UITextField *companyTextField;
@end

@implementation UIMSettingViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
  [super viewDidLoad];
}
- (IBAction)letMeInButtonTapped:(UIButton *)sender {
  if (self.companyTextField.text.length > 0) {
    [[UIMSDKService sharedService] startServiceWithCompanyName:self.companyTextField.text];
    [self performSegueWithIdentifier:@"Login" sender:sender];
  }
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  UIViewController *destinationViewController = segue.destinationViewController;
  destinationViewController.title = self.companyTextField.text;
}


@end

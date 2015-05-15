//
//  UIMIOSViewController.m
//  UIMIOS
//
//  Created by Retso Huang on 5/2/14.
//  Copyright (c) 2014 Retso Huang. All rights reserved.
//
///--------------------
/// @name Frameworks
///--------------------
@import MobileCoreServices;
#import <TPKeyboardAvoiding/TPKeyboardAvoidingScrollView.h>
#import <SVProgressHUD/SVProgressHUD.h>

///--------------------
/// @name View Controller
///--------------------
#import "UIMSDKService.h"

///--------------------
/// @name View Controller
///--------------------
#import "UIMIOSViewController.h"
#import "UIMIOSMessagesViewController.h"

@interface UIMIOSViewController () <UIPickerViewDelegate, UIMClientDelegate>
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UITextField *uidTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIPickerView *skillPicker;
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *formView;
@property (nonatomic, strong) NSArray *skillNames;
@property (nonatomic, strong) NSArray *skills;
@property (nonatomic, strong) NSString *selectedSkill;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;

@end

@implementation UIMIOSViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.skillNames = @[@"Product", @"Repair"];
  self.skills = @[@"A", @"B"];
  self.selectedSkill = @"A";
  self.addressTextField.text = @"http://1.34.252.176:8081/chat1";
  self.nameTextField.text = @"retso";
}
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [[[UIMSDKService sharedService] client] setDelegate:self];
  [self updateConnectionState:[[[UIMSDKService sharedService] client] uim_connectionState]];
  self.scrollView.contentSize = self.formView.frame.size;
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return self.skillNames.count;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return self.skillNames[row];
}

#pragma mark - UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  self.selectedSkill = self.skills[row];
}

#pragma mark - UIMClientDelegate
- (void)beginChat {
  [[[UIMSDKService sharedService] client] beginChatWithChannel:@"mobile" custID:self.uidTextField.text displayName:self.nameTextField.text phoneNumber:@"111111" email:@"example@gmail.com" problem:self.selectedSkill skill:self.selectedSkill userInfo:@{@"CustomerID": self.uidTextField.text}];
}

- (void)clientDidDisconnect:(UIMClient *)client {
  NSLog(@"Client did disconnect");
}

- (void)uimclientConnectionDidChangeState:(UIMClientConnecttionState)state {
  [self updateConnectionState:state];
  if (state == UIMClientConnecttionStateConnected) {
    [self beginChat];
  }
}
- (void)uimClientDidBeginChatWithChatId:(NSString *)chatId {
  NSLog(@"Begin chat with chat id %@", chatId);
}
- (void)uimClientWaitingForAgent:(long)queuePosition {
  [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"You are in queue: %ld", queuePosition]];
}
- (void)uimClientDidReceiveQueuePosition:(long)queuePosition {
  [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"You are in queue: %ld", queuePosition]];
}
- (void)uimClientAgentDidJoinChatWithAgentId:(NSString *)agentId agentName:(NSString *)agentName {
  UIMIOSMessagesViewController *messagesViewController = [UIMIOSMessagesViewController messagesViewController];
  messagesViewController.senderId = self.nameTextField.text;
  messagesViewController.senderDisplayName = self.nameTextField.text;
  [messagesViewController setTitle:agentName];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:messagesViewController];
  [self presentViewController:navigationController animated:YES completion:nil];
  NSLog(@"Agent joined, name: %@, agent id: %@", agentName, agentId);
}
- (void)uimclientDidFailWithErrorCode:(UIMErrorCode)code message:(NSString *)message {
  [SVProgressHUD showErrorWithStatus:message];
}

#pragma mark - UI Helpers
- (void)updateConnectionState:(UIMClientConnecttionState)state {
  switch (state) {
    case UIMClientConnecttionStateConnected: {
      self.connectionStatusLabel.text = @"Connected";
    }
      break;
    case UIMClientConnecttionStateDisconnected: {
      self.connectionStatusLabel.text = @"Disconnected";
      NSLog(@"Disconnected.");
    }
      break;
    case UIMClientConnecttionStateReconnecting: {
      self.connectionStatusLabel.text = @"Reconnecting";
      NSLog(@"Reconnecting");
    }
      break;
    case UIMClientConnecttionStateConnecting: {
      self.connectionStatusLabel.text = @"Connecting";
      NSLog(@"Connecting");
    }
      break;
    default:
      break;
  }
}

#pragma mark - User Control Events
- (IBAction)connectBarButtonTapped:(id)sender {
  if ([[UIMSDKService sharedService] client].uim_connectionState == UIMClientConnecttionStateConnected) {
    [self beginChat];
  } else {
    [[[UIMSDKService sharedService] client] uim_connect:self.addressTextField.text];
  }
}
- (IBAction)disconnectBarButtonTapped:(id)sender {
  [[[UIMSDKService sharedService] client] disconnect];
}
- (IBAction)queuePositionRequestButtonTapped:(id)sender {
  [[[UIMSDKService sharedService] client] positionRequest];
}

@end

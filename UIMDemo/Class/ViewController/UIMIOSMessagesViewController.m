//
//  UIMIOSMessagesViewController.m
//  UIMIOS
//
//  Created by Retso Huang on 5/19/14.
//  Copyright (c) 2014 Retso Huang. All rights reserved.
//

///--------------------
/// @name Frameworks
///--------------------
@import AssetsLibrary;
@import MobileCoreServices;
#import <JSQMessagesViewController/JSQMessages.h>
#import <NSArray+SafeAccess/NSArray+SafeAccess.h>
#import <UIActionSheet-Blocks/UIActionSheet+Blocks.h>
#import <MRProgress/MRProgressOverlayView.h>
#import <ReactiveObjC/RACEXTScope.h>

///--------------------
/// @name Service
///--------------------
#import "UIMSDKService.h"

///--------------------
/// @name View Controller
///--------------------
#import "UIMIOSMessagesViewController.h"

@interface UIMIOSMessagesViewController () <UIMClientDelegate, UITextViewDelegate>
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;
@property (nonatomic, strong) MRProgressOverlayView *progressOverlayView;
@end

@implementation UIMIOSMessagesViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
  [super viewDidLoad];
  JSQMessagesBubbleImageFactory *bubbleImgaeFactory = [[JSQMessagesBubbleImageFactory alloc] init];
  self.outgoingBubbleImage = [bubbleImgaeFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
  self.incomingBubbleImage = [bubbleImgaeFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
  
  self.messages = [@[] mutableCopy];
  
  self.senderId = [[NSUUID UUID] UUIDString];
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelChatButtonTapped)];
  
  [[[UIMSDKService sharedService] client] setDelegate:self];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Property
- (MRProgressOverlayView *)progressOverlayView {
  if (!_progressOverlayView) {
    _progressOverlayView = [MRProgressOverlayView showOverlayAddedTo:self.view.window title:@"Loading..." mode:MRProgressOverlayViewModeIndeterminate animated:YES];
  }
  return _progressOverlayView;
}

#pragma mark - JSQMessagesViewController Overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date {
  [JSQSystemSoundPlayer jsq_playMessageSentSound];
  
  JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderDisplayName date:date text:text];
  
  [self.messages addObject:message];
  [[[UIMSDKService sharedService] client] uim_sendMessage:text];
  [self finishSendingMessage];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
  
  [UIActionSheet presentOnView:self.view withTitle:@"Send file" cancelButton:NSLocalizedString(@"Cancel", nil) destructiveButton:nil otherButtons:@[@"Photo", @"PDF"] onCancel:nil onDestructive:nil onClickedButton:^(UIActionSheet *actionSheet, NSUInteger buttonIndex) {
    if (buttonIndex == 0) {
      UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"2009-12-31 11.06.03" ofType:@"jpg"]];
      [[[UIMSDKService sharedService] client] sendPhoto:image];
    } else {
      NSURL *filePath = [[NSBundle mainBundle] URLForResource:@"604" withExtension:@"pdf"];
      NSLog(@"PDF file path %@", filePath);
      [[[UIMSDKService sharedService] client] sendPDF:filePath];
    }
  }];
}

#pragma mark - JSQMessagesCollectionViewDataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self.messages objectAtIndex:indexPath.item];
}
- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
  JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
  
  if ([message.senderId isEqualToString:self.senderId]) {
    return self.outgoingBubbleImage;
  }
  
  return self.incomingBubbleImage;
}
- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
  JSQMessage *previoudMessage = [self.messages objectAtIndexOrNil:indexPath.item - 1];
  JSQMessage *message = self.messages[indexPath.item];
  if ([previoudMessage.date isEqualToDate:message.date]) {
    return nil;
  }
  else {
    return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
  }
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
  return nil;
}
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return nil;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [self.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
  
  JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
  
  if ([message.senderId isEqualToString:self.senderId]) {
    cell.textView.textColor = [UIColor blackColor];
  }
  else {
    cell.textView.textColor = [UIColor whiteColor];
  }
  
  return cell;
}



#pragma mark - JSQMessagesCollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
  JSQMessage *previoudMessage = [self.messages objectAtIndexOrNil:indexPath.item - 1];
  JSQMessage *message = self.messages[indexPath.item];
  if ([previoudMessage.date isEqualToDate:message.date]) {
    return 0.0f;
  }
  else {
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
  }
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
  JSQMessage *currentMessage = [self.messages objectAtIndex:indexPath.item];
  if ([currentMessage.senderId isEqualToString:self.senderId]) {
    return 0.0f;
  }
  
  
  if (indexPath.item - 1 > 0) {
    JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
    if ([previousMessage.senderId isEqualToString:currentMessage.senderId]) {
      return 0.0f;
    }
  }
  
  return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
  
  return 0.0f;
}

#pragma mark - UIMClientDelegate
- (void)uimClientDidEndChatWithChatId:(NSString *)chatId {
  NSLog(@"UIMClient did end chat with chat id: %@", chatId);
  [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)uimClientAgentDidLeaveChatWithAgentId:(NSString *)agentId {
  [[[UIMSDKService sharedService] client] uim_endChat];
  [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)uimClientDidReceiveMessageWithSenderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName messageId:(NSString *)messageId content:(NSString *)content {
  NSLog(@"Received message id %@", messageId);
  if ([self.senderDisplayName isEqualToString:senderDisplayName]) {
    return;
  }
  JSQMessage *newMessage = [JSQMessage messageWithSenderId:senderId displayName:senderDisplayName text:content];
  [JSQSystemSoundPlayer jsq_playMessageReceivedAlert];
  [self.messages addObject:newMessage];
  [self finishReceivingMessage];
}
- (void)uimClientDidReceiveMediaFileWithSenderId:(NSString *)senderId senderName:(NSString *)senderName fileId:(NSString *)fileId fileName:(NSString *)filename {
  NSLog(@"Receive media file with file id: %@, file name: %@", fileId, filename);
  if ([self.senderDisplayName isEqualToString:senderName]) {
    return;
  }
  [[[UIMSDKService sharedService] client] downloadMediaFileWithFileId:fileId filename:filename];
}
- (void)uimClientDidBeginUploadMediaFileWithFileId:(NSString *)fileId progress:(float)progress {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.progressOverlayView.mode != MRProgressOverlayViewModeDeterminateCircular) {
      self.progressOverlayView.mode = MRProgressOverlayViewModeDeterminateCircular;
    }
    [self.progressOverlayView setProgress:progress animated:YES];
  });
}
- (void)uimclientDidFinishUploadMediaFileWithFileId:(NSString *)fileId error:(NSError *)error {
  
  @weakify(self)
  dispatch_async(dispatch_get_main_queue(), ^{
    @strongify(self)
    if (error) {
      self.progressOverlayView.mode = MRProgressOverlayViewModeCross;
      self.progressOverlayView.titleLabelText = @"Failed";
    } else {
      self.progressOverlayView.mode = MRProgressOverlayViewModeCheckmark;
      self.progressOverlayView.titleLabelText = @"Succeed";
    }
    
    [self performBlock:^{
      
      [self.progressOverlayView dismiss:YES completion:^{
        self.progressOverlayView = nil;
      }];
    }afterDelay:2.0];
  });

}
- (void)uimClientDidBeginDownloadMediaFileWithFileId:(NSString *)fileId progress:(float)progress {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.progressOverlayView.mode != MRProgressOverlayViewModeDeterminateCircular) {
      self.progressOverlayView.mode = MRProgressOverlayViewModeDeterminateCircular;
    }
    [self.progressOverlayView setProgress:progress animated:YES];
  });
}

- (void)uimClient:(UIMClient *)client didFinishDownloadFileWithId:(NSString *)fileId atPath:(NSString *)path error:(NSError *)error {
  
  @weakify(self)
  dispatch_async(dispatch_get_main_queue(), ^{
    @strongify(self)
    if (error) {
      self.progressOverlayView.mode = MRProgressOverlayViewModeCross;
      self.progressOverlayView.titleLabelText = @"Failed";
    } else {
      NSLog(@"Downloaded fileId: %@", fileId);
      NSLog(@"File path: %@", path);
      self.progressOverlayView.mode = MRProgressOverlayViewModeCheckmark;
      self.progressOverlayView.titleLabelText = @"Succeed";
    }
    
    [self performBlock:^{
      
      [self.progressOverlayView dismiss:YES completion:^{
        self.progressOverlayView = nil;
      }];
    }afterDelay:2.0];
  });

}

#pragma mark - User Control Events
- (void)cancelChatButtonTapped {
  [[[UIMSDKService sharedService] client] uim_endChat];
}
- (void)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay {
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), block);
}
@end

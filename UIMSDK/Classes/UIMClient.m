//
//  UIMClient.m
//  UIMIOS
//
//  Created by Retso Huang on 5/4/14.
//  Copyright (c) 2014 Retso Huang. All rights reserved.
//

///--------------------
/// @name Frameworks
///--------------------
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

///--------------------
/// @name Service
///--------------------
#import "UIMClient.h"
#import "UIMService.h"

@interface UIMClient()
@property (nonatomic, strong) UIMService *service;
@end

@implementation UIMClient

#pragma mark - Initlizer
- (instancetype)initWithTenantId:(NSString *)tenantId {
  if (!tenantId) {
    return nil;
  }
  
  self = [super init];
  if (self) {
    self.service = [[UIMService alloc] initWithTenantId:tenantId];
    
    [[RACObserve(self, service.connectionState) distinctUntilChanged] subscribeNext:^(NSNumber *state) {
      if ([self.delegate respondsToSelector:@selector(uimclientConnectionDidChangeState:)]) {
        [self.delegate uimclientConnectionDidChangeState:state.integerValue];
      }
    }];
    
    [self.service.agentJoinChatSignal subscribeNext:^(RACTuple *tuple) {
      if ([self.delegate respondsToSelector:@selector(uimClientAgentDidJoinChatWithAgentId:agentName:)]) {
        [self.delegate uimClientAgentDidJoinChatWithAgentId:tuple.second
                                                  agentName:tuple.third];
      }
      if ([self.delegate respondsToSelector:@selector(uimClientDidBeginChatWithChatId:)]) {
        [self.delegate uimClientDidBeginChatWithChatId:tuple.first];
      }
    }];
    
    [self.service.signalForWaitingForAgent subscribeNext:^(NSNumber *queuePosition) {
      if ([self.delegate respondsToSelector:@selector(uimClientWaitingForAgent:)]) {
        [self.delegate uimClientWaitingForAgent:queuePosition.integerValue];
      }
    }];
    
    [self.service.agentLeaveChatSignal subscribeNext:^(NSString *agentId) {
      if ([self.delegate respondsToSelector:@selector(uimClientAgentDidLeaveChatWithAgentId:)]) {
        [self.delegate uimClientAgentDidLeaveChatWithAgentId:agentId];
      }
    }];
    
    [self.service.endChatSignal subscribeNext:^(NSString *chatId) {
      if ([self.delegate respondsToSelector:@selector(uimClientDidEndChatWithChatId:)]) {
        [self.delegate uimClientDidEndChatWithChatId:chatId];
      }
    }];
    
    [self.service.textMessageSignal subscribeNext:^(RACTuple *tuple) {
      if ([self.delegate respondsToSelector:@selector(uimClientDidReceiveMessageWithSenderId:senderDisplayName:messageId:content:)]) {
        [self.delegate uimClientDidReceiveMessageWithSenderId:tuple.first senderDisplayName:tuple.second messageId:tuple.third content:tuple.fourth];
      }
    }];
    
    [self.service.fileMessageSignal subscribeNext:^(RACTuple *tuple) {
      if ([self.delegate respondsToSelector:@selector(uimClientDidReceiveMediaFileWithSenderId:senderName:fileId:fileName:)]) {
        [self.delegate uimClientDidReceiveMediaFileWithSenderId:tuple.first senderName:tuple.second fileId:tuple.third fileName:tuple.fourth];
      }
    }];
    
    [self.service.queuePositionResponseSignal subscribeNext:^(NSNumber *position) {
      if ([self.delegate respondsToSelector:@selector(uimClientDidReceiveQueuePosition:)]) {
        [self.delegate uimClientDidReceiveQueuePosition:position.integerValue];
      }
    }];
    
    [self.service.disconnectSignal subscribeNext:^(id x) {
      if ([self.delegate respondsToSelector:@selector(clientDidDisconnect:)]) {
        [self.delegate clientDidDisconnect:self];
      }
    }];
    
  }
  
  return self;
}

#pragma mark - Getter
- (UIMClientConnecttionState)uim_connectionState {
  return self.service.connectionState;
}

#pragma mark - Connection
- (void)uim_connect:(NSString *)urlString {
  NSParameterAssert(urlString);
  
  if (self.uim_connectionState == UIMClientConnecttionStateDisconnected) {
    [self.service uim_connect:urlString];
  } else {
    NSLog(@"You already connected.");
  }
  
}

- (void)disconnect {
  if (self.uim_connectionState == UIMClientConnecttionStateConnected) {
    [self.service disconnect];
  } else {
    NSLog(@"You are not connect yet.");
  }
}

#pragma mark - Chat
- (void)beginChatWithChannel:(NSString *)channel custID:(NSString *)custID displayName:(NSString *)displayName phoneNumber:(NSString *)phoneNumber email:(NSString *)email problem:(NSString *)problem skill:(NSString *)skill userInfo:(NSDictionary *)userInfo {
  
  NSParameterAssert(channel);
  NSParameterAssert(custID);
  NSParameterAssert(displayName);
  NSParameterAssert(phoneNumber);
  NSParameterAssert(email);
  NSParameterAssert(problem);
  NSParameterAssert(skill);
  NSParameterAssert(userInfo);
  
  [self.service beginChatWithChannel:channel
                              custID:custID
                         displayName:displayName
                         phoneNumber:phoneNumber
                               email:email
                             problem:problem
                               skill:skill
                            userInfo:userInfo];
  
}

- (void)uim_endChat {
  if (![self.service endChat]) {
    NSLog(@"You haven't start a conversation yet.");
  }
}

- (NSString *)uim_sendMessage:(NSString *)text {
  NSParameterAssert(text);
  return [self.service sendMessage:text];
}

#pragma mark - File Transfer
- (NSString *)sendPhoto:(UIImage *)image {
  NSParameterAssert(image);
  
  @weakify(self)
  return [self.service sendPhoto:image progress:^(NSString *fileId, float progress) {
    @strongify(self)
    if ([self.delegate respondsToSelector:@selector(uimClientDidBeginUploadMediaFileWithFileId:progress:)]) {
      [self.delegate uimClientDidBeginUploadMediaFileWithFileId:fileId
                                                       progress:progress];
    }
  }finish:^(NSString *fileId, NSError *error) {
    @strongify(self)
    if ([self.delegate respondsToSelector:@selector(uimclientDidFinishUploadMediaFileWithFileId:error:)]) {
      [self.delegate uimclientDidFinishUploadMediaFileWithFileId:fileId
                                                           error:error];
    }
  }];
}

- (NSString *)sendPDF:(NSURL *)path {
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  @weakify(self)
  if ([fileManager fileExistsAtPath:path.relativePath]) {
    return [self.service sendPDF:path progress:^(NSString *fileId, float progress) {
      @strongify(self)
      if ([self.delegate respondsToSelector:@selector(uimClientDidBeginUploadMediaFileWithFileId:progress:)]) {
        [self.delegate uimClientDidBeginUploadMediaFileWithFileId:fileId
                                                         progress:progress];
      }
    }finish:^(NSString *fileId, NSError *error) {
      @strongify(self)
      if ([self.delegate respondsToSelector:@selector(uimclientDidFinishUploadMediaFileWithFileId:error:)]) {
        [self.delegate uimclientDidFinishUploadMediaFileWithFileId:fileId
                                                             error:error];
      }
    }];
  } else {
    NSDictionary *userInfo = @{NSURLErrorFailingURLErrorKey: path};
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:userInfo];
    if ([self.delegate respondsToSelector:@selector(uimclientDidFinishUploadMediaFileWithFileId:error:)]) {
      [self.delegate uimclientDidFinishUploadMediaFileWithFileId:nil
                                                           error:error];
    }
    return nil;
  }
}

- (void)downloadMediaFileWithFileId:(NSString *)fileId
                           filename:(NSString *)filename {
  NSParameterAssert(fileId);
  NSParameterAssert(filename);

  @weakify(self)
  if (self.service.connectionState == UIMClientConnecttionStateConnected) {
    [self.service downloadMediaFileWithFileId:fileId filename:filename progress:^(NSString *fileId, float progress) {
      @strongify(self)
      if ([self.delegate respondsToSelector:@selector(uimClientDidBeginDownloadMediaFileWithFileId:progress:)]) {
        [self.delegate uimClientDidBeginDownloadMediaFileWithFileId:fileId
                                                           progress:progress];
      }
    }finish:^(NSString *fileId, NSString *path, NSError *error) {
      @strongify(self)
      if ([self.delegate respondsToSelector:@selector(uimClient:didFinishDownloadFileWithId:atPath:error:)]) {
        [self.delegate uimClient:self
     didFinishDownloadFileWithId:fileId
                          atPath:path
                           error:error];
      }
    }];
  } else {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:@{NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"You must be connect to server.", nil)}];
    if ([self.delegate respondsToSelector:@selector(uimClient:didFinishDownloadFileWithId:atPath:error:)]) {
      [self.delegate uimClient:self
   didFinishDownloadFileWithId:nil
                        atPath:nil
                         error:error];
    }
  }

}

#pragma mark - Connection State
- (void)positionRequest {
  if (self.uim_connectionState == UIMClientConnecttionStateConnected) {
    [self.service requestPosition];
  } else {
    NSLog(@"You must be connect to server.");
  }
}

@end

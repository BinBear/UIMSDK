//
//  UIMService.m
//  UIMSDK
//
//  Created by Retso Huang on 1/14/15.
//  Modified by Retso Huang on Jun 8 2018
//  Copyright (c) 2018 Retso Huang. All rights reserved.
//

#import "UIMService.h"

///--------------------
/// @name Frameworks
///--------------------
#import <ReactiveObjC/ReactiveObjC.h>
#import <ReactiveObjC/RACEXTScope.h>
#import <SignalR-ObjC/SignalR.h>
#import <SignalR-ObjC/SRLongPollingTransport.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <AFNetworking/AFHTTPSessionManager.h>

///--------------------
/// @name SignalR Server Information
///--------------------
static NSString * const UIMHubProxyName = @"entityHub";
static NSString * const UIMHubEventNameQueuePositionResponse = @"position";
static NSString * const UIMHubEventNameLogin = @"login";
static NSString * const UIMHubEventNameChatCreated = @"join";
static NSString * const UIMHubEventNameMessage = @"message";
static NSString * const UIMHubEventNameWaitingForAgent = @"enqueue";
static NSString * const UIMHubEventNameReconnected = @"move";
static NSString * const UIMHubEventNameLeave = @"leave";
static NSString * const UIMHubInvocationNameLogin = @"userLogin";
static NSString * const UIMHubInvocationNamePosition = @"getPosition";

///--------------------
/// @name Message Key Path Variable
///--------------------
static NSString * const UIMMessageTypeText = @"text";
static NSString * const UIMMessageTypeFile = @"file";
static NSString * const kUIMMessageId = @"Link";
static NSString * const kUIMMessageType = @"Type";
static NSString * const kUIMMessageContent = @"Content";
static NSString * const kUIMMessageSenderId = @"SenderId";
static NSString * const kUIMMessageSenderName = @"SenderName";
static NSString * const kUIMMessageSenderType = @"SenderType";
static NSString * const kUIMMessageFileId = @"Link";
static NSString * const kUIMMessageFilename = @"Content";
static NSString * const kUIMMessageErrorCode = @"Code";
static NSString * const kUIMMessageErrorMessage = @"Message";

///--------------------
/// @name Web Server Information
///--------------------
static NSString * const UIMFileUploadPath = @"media/upload";
static NSString * const UIMFileDownloadPath = @"media/download";
static NSString * const UIMNSURLBackgroundSessionConfigurationIdentifier = @"com.devpro.backgroundSessionConfiguration";
static NSString * const kUIMChatId = @"callId";
static NSString * const kUIMFilename = @"fileName";
static NSString * const kUIMFileId = @"fileId";
static NSString * const kUIMServerFilename = @"filename";
static NSString * const kUIMServerFileId = @"fileid";
static NSString * const kUIMProplem = @"Inquiry";
static NSString * const kUIMPhonenumber = @"PhoneNo";
static NSString * const kUIMEmail = @"EMail";
static NSString * const kUIMAdditionalField1 = @"Attr1";
static NSString * const kUIMAdditionalField2 = @"Attr2";
static NSString * const kUIMAdditionalField3 = @"Attr3";
static NSTimeInterval const UIMTimeoutInterval = 180;

@interface UIMService() <SRConnectionDelegate>

///--------------------
/// @name Properties
///--------------------
@property (nonatomic, strong) SRHubConnection *hubConnection;
@property (nonatomic, strong) SRHubProxy *hubProxy;
@property (nonatomic, readwrite) UIMClientConnecttionState connectionState;
@property (nonatomic, strong) NSString *chatId;
@property (nonatomic) long messageCount;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong, readonly) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong, readonly) NSString *tenantId;
@property (nonatomic, strong) NSString *instantId;

///--------------------
/// @name Signals
///--------------------
@property (nonatomic , strong, readwrite) RACSignal *agentJoinChatSignal;
@property (nonatomic, strong, readwrite) RACSignal *signalForWaitingForAgent;
@property (nonatomic, strong, readwrite) RACSignal *agentLeaveChatSignal;
@property (nonatomic, strong, readwrite) RACSignal *endChatSignal;
@property (nonatomic, strong, readwrite) RACSignal *queuePositionResponseSignal;
@property (nonatomic, strong, readwrite) RACSignal *textMessageSignal;
@property (nonatomic, strong, readwrite) RACSignal *fileMessageSignal;
@property (nonatomic, strong, readwrite) RACSignal *disconnectSignal;

///--------------------
/// @name Hub Event Handler
///--------------------
- (void)memberJoinChatWithChatId:(NSString *)chatId
                        chatInfo:(id)chatInfo
                        userInfo:(id)userInfo;
- (void)waitingForAgentWithChatId:(NSString *)chatId queuePisition:(NSString *)queuePosition;
- (void)memberLeaveChatWithId:(NSString *)chatId info:(NSDictionary *)info;
- (void)userLoginWithInstantId:(NSString *)instantId;
- (void)queuePositionResponseWithChatId:(NSString *)chatId queuePosition:(NSString *)queuePosition;
- (void)receiveMessageWithInstentId:(NSString *)instantId
                           userInfo:(NSDictionary *)userInfo;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation UIMService

#pragma clang diagnostic pop

#pragma mark - Initlizer
- (instancetype)initWithTenantId:(NSString *)tenantId {
  if (!tenantId) {
    return nil;
  }
  
  self = [super init];
  if (self) {
    _tenantId = tenantId;
    self.connectionState = UIMClientConnecttionStateDisconnected;
    
    @weakify(self)
    self.signalForWaitingForAgent = [[self rac_signalForSelector:@selector(waitingForAgentWithChatId:queuePisition:)] map:^NSNumber *(RACTuple *tuple) {
      NSString *position = tuple.second;
      return @(position.integerValue);
    }];
    
    self.agentJoinChatSignal = [[[self rac_signalForSelector:@selector(memberJoinChatWithChatId:chatInfo:userInfo:)] filter:^BOOL(RACTuple *tuple) {
      @strongify(self)
      self.chatId = tuple.first;
      NSDictionary *chatInfo = tuple.second;
      return ![chatInfo[@"InstId"] isEqualToString:self.instantId];
    }] map:^RACTuple *(RACTuple *tuple) {
      return RACTuplePack(tuple.first, tuple.second[@"Id"], tuple.second[@"Name"]);
    }];
    
    self.agentLeaveChatSignal = [[[self rac_signalForSelector:@selector(memberLeaveChatWithId:info:)] filter:^BOOL(RACTuple *tuple) {
      @strongify(self)
      return ![self.instantId isEqualToString:tuple.second[@"InstId"]];
    }] map:^id(RACTuple *tuple) {
      return tuple.second[@"id"];
    }];
    
    self.endChatSignal = [[self rac_signalForSelector:@selector(memberLeaveChatWithId:info:)] map:^id(RACTuple *tuple) {
      return tuple.first;
    }];
    
    self.queuePositionResponseSignal = [[self rac_signalForSelector:@selector(queuePositionResponseWithChatId:queuePosition:)] map:^NSNumber *(RACTuple *tuple) {
      NSString *position = tuple.second;
      return @(position.integerValue);
    }];
    
    self.textMessageSignal = [[[self rac_signalForSelector:@selector(receiveMessageWithInstentId:userInfo:)] filter:^BOOL(RACTuple *tuple) {
      return [tuple.second[kUIMMessageType] isEqualToString:UIMMessageTypeText];
    }] map:^RACTuple *(RACTuple *tuple) {
      NSDictionary *userInfo = tuple.second;
      return RACTuplePack(userInfo[kUIMMessageSenderId], userInfo[kUIMMessageSenderName], userInfo[kUIMMessageId], userInfo[kUIMMessageContent]);
    }];
    
    self.fileMessageSignal = [[[self rac_signalForSelector:@selector(receiveMessageWithInstentId:userInfo:)] filter:^BOOL(RACTuple *tuple) {
      return [tuple.second[kUIMMessageType] isEqualToString:UIMMessageTypeFile];
    }] map:^RACTuple *(RACTuple *tuple) {
      NSDictionary *userInfo = tuple.second;
      return RACTuplePack(userInfo[kUIMMessageSenderId], userInfo[kUIMMessageSenderName], userInfo[kUIMMessageFileId], userInfo[kUIMMessageFilename]);
    }];
    
    [[self rac_signalForSelector:@selector(userLoginWithInstantId:)] subscribeNext:^(RACTuple *tuple) {
      @strongify(self)
      self.instantId = tuple.first;
    }];
    
    self.disconnectSignal = [self rac_signalForSelector:@selector(SRConnectionDidClose:)];
    
    [self.disconnectSignal subscribeNext:^(id x) {
      self.hubConnection = nil;
      self.hubProxy = nil;
      self.connectionState = UIMClientConnecttionStateDisconnected;
    }];
  }
  
  return self;
}

#pragma mark - Connection
- (void)uim_connect:(NSString *)urlString {
  
  ///--------------------
  /// @name AFNetworking initialize
  ///--------------------
  NSURL *baseURL = [NSURL URLWithString:urlString];
  AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
  requestSerializer.timeoutInterval = UIMTimeoutInterval;
  self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
  self.manager.requestSerializer = requestSerializer;
  
  NSURLSessionConfiguration *sessionConfiguration;
  
  if (@available(iOS 8.0, *)) {
    sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:UIMNSURLBackgroundSessionConfigurationIdentifier];
  } else {
    sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:UIMNSURLBackgroundSessionConfigurationIdentifier];
  }

  sessionConfiguration.timeoutIntervalForResource = UIMTimeoutInterval;
  _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:sessionConfiguration];
  
  ///--------------------
  /// @name SignalR connection initialize
  ///--------------------
  self.hubConnection = [SRHubConnection connectionWithURLString:urlString queryString:@{@"tenant": self.tenantId}];
  self.hubConnection.delegate = self;
  self.hubProxy = [self.hubConnection createHubProxy:UIMHubProxyName];
  [self.hubProxy on:UIMHubEventNameChatCreated
            perform:self
           selector:@selector(memberJoinChatWithChatId:chatInfo:userInfo:)];
  [self.hubProxy on:UIMHubEventNameQueuePositionResponse
            perform:self
           selector:@selector(queuePositionResponseWithChatId:queuePosition:)];
  [self.hubProxy on:UIMHubEventNameLogin
            perform:self
           selector:@selector(userLoginWithInstantId:)];
  [self.hubProxy on:UIMHubEventNameMessage
            perform:self
           selector:@selector(receiveMessageWithInstentId:userInfo:)];
  [self.hubProxy on:UIMHubEventNameWaitingForAgent
            perform:self
           selector:@selector(waitingForAgentWithChatId:queuePisition:)];
  [self.hubProxy on:UIMHubEventNameLeave
            perform:self
           selector:@selector(memberLeaveChatWithId:info:)];
  [self.hubConnection start];
}

- (void)disconnect {
  [self endChat];
  self.instantId = nil;
  [self.hubConnection disconnect];
}

#pragma mark - Chat
- (void)beginChatWithChannel:(NSString *)channel
                      custID:(NSString *)custID
                 displayName:(NSString *)displayName
                 phoneNumber:(NSString *)phoneNumber
                       email:(NSString *)email
                     problem:(NSString *)problem
                       skill:(NSString *)skill
                    userInfo:(NSDictionary *)userInfo {
  NSMutableDictionary *info = [userInfo mutableCopy];
  [info setObject:problem forKey:kUIMProplem];
  [info setObject:phoneNumber forKey:kUIMPhonenumber];
  [info setObject:email forKey:kUIMEmail];
  [info setObject:phoneNumber forKey:kUIMAdditionalField1];
  [info setObject:email forKey:kUIMAdditionalField2];
  [info setObject:problem forKey:kUIMAdditionalField3];
  
  NSArray *args = @[self.tenantId, channel, custID, displayName, phoneNumber, email, skill, userInfo];
  
  [self.hubProxy invoke:UIMHubInvocationNameLogin withArgs:args];
}

- (BOOL)endChat {
  if (self.connectionState == UIMClientConnecttionStateConnected &&
      self.chatId) {
    [self.hubProxy invoke:UIMHubEventNameLeave withArgs:@[self.chatId]];
    self.chatId = nil;
    self.instantId = nil;
    return YES;
  } else {
    return NO;
  }
}

- (NSString *)sendMessage:(NSString *)text {
  NSInteger messageIdValue = self.chatId.integerValue + self.messageCount;
  self.messageCount++;
  NSString *messageId = [NSString stringWithFormat:@"%@", @(messageIdValue)];
  
  NSArray *args = @[self.chatId, @"text", messageId, text];
  [self.hubProxy invoke:UIMHubEventNameMessage withArgs:args];
  return messageId;
}

#pragma mark - File Transfer
- (NSString *)sendPhoto:(UIImage *)image
               progress:(void (^)(NSString *fileId, float progress))progressBlock
                 finish:(void (^)(NSString *fileId, NSError *error))finishBlock {
  NSString *localFileId = [[NSUUID UUID] UUIDString];
  NSString *filename = [localFileId stringByAppendingPathExtension:@"jpg"];
  NSDictionary *parameters = @{kUIMChatId: self.chatId, kUIMFilename: localFileId};
  AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
  responseSerializer.acceptableContentTypes = [[NSSet alloc] initWithArray:@[@"text/plain"]];
  self.manager.responseSerializer = responseSerializer;
  @weakify(self)
  AFHTTPRequestOperation *operation = [self.manager POST:UIMFileUploadPath parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [formData appendPartWithFileData:imageData name:@"file" fileName:filename mimeType:@"image/jpeg"];
  } success:^(AFHTTPRequestOperation *operation, id responseObject) {
    @strongify(self)
    NSString *serverFileId = responseObject[kUIMServerFileId];
    NSArray *args = @[self.chatId, @"file", serverFileId, filename];
    if (finishBlock) {
      finishBlock(localFileId, nil);
    }
    [self.hubProxy invoke:UIMHubEventNameMessage withArgs:args];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    if (finishBlock) {
      finishBlock(localFileId, error);
    }
  }];
  [operation setUploadProgressBlock: ^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    CGFloat progress = (totalBytesWritten * 1.0) / totalBytesExpectedToWrite;
    if (progressBlock) {
      progressBlock(localFileId, progress);
    }
  }];
  return localFileId;
}

- (NSString *)sendPDF:(NSURL *)path
             progress:(void (^)(NSString *fileId, float progress))progressBlock
               finish:(void (^)(NSString *fileId, NSError *error))finishBlock {
  NSString *localFileId = [[NSUUID UUID] UUIDString];
  NSDictionary *parameters = @{kUIMChatId: self.chatId, kUIMFilename: localFileId};

  @weakify(self)
  AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
  responseSerializer.acceptableContentTypes = [[NSSet alloc] initWithArray:@[@"text/plain"]];
  self.manager.responseSerializer = responseSerializer;
  AFHTTPRequestOperation *operation = [self.manager POST:UIMFileUploadPath parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
    NSError *loadFileError;
    [formData appendPartWithFileURL:path name:@"file" fileName:path.lastPathComponent mimeType:@"application/pdf" error:&loadFileError];
  } success:^(AFHTTPRequestOperation *operation, id responseObject) {
    @strongify(self)
    NSString *serverFileId = responseObject[kUIMServerFileId];
    NSArray *args = @[self.chatId, @"file", serverFileId, path.lastPathComponent];
    if (finishBlock) {
      finishBlock(localFileId, nil);
    }
    [self.hubProxy invoke:UIMHubEventNameMessage withArgs:args];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    if (finishBlock) {
      finishBlock(localFileId, error);
    }
  }];
  [operation setUploadProgressBlock:^ (NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    if (progressBlock) {
      CGFloat progress = totalBytesWritten/totalBytesExpectedToWrite;
      progressBlock(localFileId, progress);
    }
  }];
  return localFileId;
}
- (void)downloadMediaFileWithFileId:(NSString *)fileId
                           filename:(NSString *)filename
                           progress:(void (^)(NSString *fileId,float progress))progressBlock
                             finish:(void (^)(NSString *fileId, NSString *path, NSError *error))finishBlock {
  if (self.chatId) {
    NSDictionary *parameters = @{kUIMChatId: self.chatId, kUIMFileId: fileId, kUIMFilename: filename};
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:UIMFileDownloadPath relativeToURL:self.sessionManager.baseURL] absoluteString] parameters:parameters error:nil];
    [[self.sessionManager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
      NSURL *dirURL  = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
      return [dirURL URLByAppendingPathComponent:filename];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
      if (finishBlock) {
        finishBlock(fileId, filePath.absoluteString, error);
      }
    }] resume];
    
    [self.sessionManager setDownloadTaskDidWriteDataBlock:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
      float progress = (totalBytesWritten * 1.0) / totalBytesExpectedToWrite;
      if (progressBlock) {
        progressBlock(fileId, progress);
      }
    }];
  } else {
    if (finishBlock) {
      NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: @"You haven't start a conversation yet."};
      NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:userInfo];
      finishBlock(fileId, nil, error);
    }
  }
}

#pragma mark - Connection State
- (void)requestPosition {
  if (self.connectionState == UIMClientConnecttionStateConnected) {
    [self.hubProxy invoke:UIMHubInvocationNamePosition
                 withArgs:@[self.chatId]];
  }
}

#pragma mark - SRConnectionDelegate
- (void)SRConnectionDidReconnect:(id<SRConnectionInterface>)connection {
  if (self.instantId) {
    [self.hubProxy invoke:UIMHubEventNameReconnected
                 withArgs:@[self.tenantId, self.instantId]];
  }
}
- (void)SRConnection:(id<SRConnectionInterface>)connection didChangeState:(connectionState)oldState newState:(connectionState)newState {
  if (connection == self.hubConnection) {
    switch (newState) {
      case disconnected:
        self.connectionState = UIMClientConnecttionStateDisconnected;
        break;
      case connected:
        self.connectionState = UIMClientConnecttionStateConnected;
        break;
      case connecting:
        self.connectionState = UIMClientConnecttionStateConnecting;
        break;
      case reconnecting:
        self.connectionState = UIMClientConnecttionStateReconnecting;
        break;
      default:
        break;
    }
  }
}

@end

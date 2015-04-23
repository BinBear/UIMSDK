//
//  UIMService.h
//  UIMSDK
//
//  Created by Retso Huang on 1/14/15.
//  Copyright (c) 2015 Retso Huang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIMClient.h"

@class RACSignal;

@interface UIMService : NSObject

@property (nonatomic, readonly) UIMClientConnecttionState connectionState;

///--------------------
/// @name Signals
///--------------------
@property (nonatomic , strong, readonly) RACSignal *agentJoinChatSignal;

@property (nonatomic, strong, readonly) RACSignal *signalForWaitingForAgent;

@property (nonatomic, strong, readonly) RACSignal *agentLeaveChatSignal;

@property (nonatomic, strong, readonly) RACSignal *endChatSignal;

@property (nonatomic, strong, readonly) RACSignal *queuePositionResponseSignal;
@property (nonatomic, strong, readonly) RACSignal *textMessageSignal;
@property (nonatomic, strong, readonly) RACSignal *fileMessageSignal;
@property (nonatomic, strong, readonly) RACSignal *disconnectSignal;

- (instancetype)initWithTenantId:(NSString *)tenantId;
- (void)uim_connect:(NSString *)urlString;
- (void)disconnect;
- (void)beginChatWithChannel:(NSString *)channel
                      custID:(NSString *)custID
                 displayName:(NSString *)displayName
                 phoneNumber:(NSString *)phoneNumber
                       email:(NSString *)email
                     problem:(NSString *)problem
                       skill:(NSString *)skill
                    userInfo:(NSDictionary *)userInfo;
- (BOOL)endChat;
- (NSString *)sendMessage:(NSString *)text;
- (NSString *)sendPhoto:(UIImage *)image
               progress:(void (^)(NSString *fileId, float progress))progressBlock
                 finish:(void (^)(NSString *fileId, NSError *error))finishBlock;
- (NSString *)sendPDF:(NSURL *)path
             progress:(void (^)(NSString *fileId, float progress))progressBlock
               finish:(void (^)(NSString *fileId, NSError *error))finishBlock;
- (void)downloadMediaFileWithFileId:(NSString *)fileId
                           filename:(NSString *)filename
                           progress:(void (^)(NSString *fileId, float progress))progressBlock
                             finish:(void (^)(NSString *fileId, NSString *path, NSError *error))finishBlock;
- (void)requestPosition;
@end

///--------------------
/// @name Notifications
///--------------------

extern NSString * const UIMServiceAgentJoinChatNotification;

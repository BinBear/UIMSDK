//
//  UIMClient.h
//  UIMIOS Version 1.5
//
//  Created by Devpro on 5/4/14.
//  Copyright (c) 2014 Devpro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol UIMClientDelegate;

/**
 *  These enumeration representation connection state.
 */
typedef NS_ENUM(NSInteger, UIMClientConnecttionState) {
  /**
   *  Connection is connected with server.
   */
  UIMClientConnecttionStateConnected,
  /**
   *  Connection is disconnect with server.
   */
  UIMClientConnecttionStateDisconnected,
  /**
   *  Connection will reconnecting to server.
   */
  UIMClientConnecttionStateReconnecting,
  /**
   *  Connection is connecting.
   */
  UIMClientConnecttionStateConnecting
};

/**
 *  These enumeration representation response status code.
 */
typedef NS_ENUM(long, UIMErrorCode) {
  /**
   *  No error.
   */
  UIMErrorCodeNone = 0,
  /**
   *  Reuqest timeout.
   */
  UIMErrorCodeTimeout = 1099
};

/**
 *  UIMClient is a manager of chat server base on SingalR, provide by devpro.
 */
@interface UIMClient : NSObject

/**
 *  Setting delegation to UIMClient.
 */
@property (nonatomic) id <UIMClientDelegate> delegate;

/**
 *  A `UIMClientConnecttionState` value representation current connection state.
 */
@property (nonatomic, readonly) UIMClientConnecttionState uim_connectionState;

///-------------------------------
/// @name Ititializer
///-------------------------------

/**
 *  Creates and returns a UIMClient object with given parameters.
 *
 *  @param tenantId The connection query string
 *
 *  @return A newly-initlized instance object.
 */
- (instancetype)initWithTenantId:(NSString *)tenantId;

///-------------------------------
/// @name Connection
///-------------------------------
/**
 *  Connect to SignalR based server with given url string.
 *
 *  @param urlString The string value representation server's address
 */
- (void)uim_connect:(NSString *)urlString;

/**
 *  Disconnect with SignalR server's connection.
 */
- (void)disconnect;

///-------------------------------
/// @name Chat
///-------------------------------

/**
 *  Start a communication with agent use given informations.
 *
 *  @param channel     A string value representation which gayway user connected.
 *  @param custID      A string value representation customer identifier.
 *  @param displayName A string value representation user's nickname.
 *  @param phoneNumber A string value representation user's phone number
 *  @param email       A string value representation user's email address
 *  @param problem     A string value representation user's problem description.
 *  @param skill       A string value representation agent's skill.
 *  @param userInfo    A dictionary object representation customized user infomation.
 */
- (void)beginChatWithChannel:(NSString *)channel
                      custID:(NSString *)custID
                 displayName:(NSString *)displayName
                 phoneNumber:(NSString *)phoneNumber
                       email:(NSString *)email
                     problem:(NSString *)problem
                       skill:(NSString *)skill
                    userInfo:(NSDictionary *)userInfo;

/**
 *  Send text message to agent.
 *
 *  @param text A string value representation content.
 *
 *  @return A string value representation unique message id.
 */
- (NSString *)uim_sendMessage:(NSString *)text;

/**
 *  Finish a communication with agent.
 */
- (void)uim_endChat;

///-------------------------------
/// @name File Transfer
///-------------------------------
/**
 *  Send photo to agent.
 *
 *  @param image A `UIImage` object representation selected photo.
 *
 *  @return A string value representation file id to track progress.
 */
- (NSString *)sendPhoto:(UIImage *)image;

/**
 *  Send PDF file to agent.
 *
 *  @param path A NSURL object representation the file path
 *
 *  @return A string value representation file id to track progress.
 */
- (NSString *)sendPDF:(NSURL *)path;

/**
 *  Download photo or video with given file id and file name.
 *
 *  @param fileId   A string value representation file identifier.
 *  @param filename A string value representation file name.
 */
- (void)downloadMediaFileWithFileId:(NSString *)fileId
                           filename:(NSString *)filename;

///-------------------------------
/// @name Connection State
///-------------------------------
/**
 *  Send request to get position on queue.
 */
- (void)positionRequest;

///-------------------------------
/// @name Deprecated
///-------------------------------

/**
 *  Use initWithTenantId: instead.
 */
- (id)init __attribute__((unavailable("Use +initWithTenantId: instead.")));

/**
 *  Use initWithTenantId: instead.
 */
+ (instancetype)sharedClient __attribute__((unavailable("Use initWithTenantId: instead.")));

@end

/**
 *  The UIMClientDelegate protocol defines methods that your delegate object must implement to interact with the uim client chat. The methods of this protocol notify your delegate when the connection has something happen.
 */
@protocol UIMClientDelegate <NSObject>
@optional
///-------------------------------
/// @name Chat
///-------------------------------
/**
 *  Tell delegate the client did begin chat with agent.
 *
 *  @param chatId A string value representation chat identifier.
 */
- (void)uimClientDidBeginChatWithChatId:(NSString *)chatId;

/**
 *  Tell delegate the client is waiting for agent.
 *
 *  @param queuePosition A integer value representation your position in queue.
 */
- (void)uimClientWaitingForAgent:(NSInteger)queuePosition;

/**
 *  Tell delegate the did agent join the chat.
 *
 *  @param agentId   A string value representation agent's id.
 *  @param agentName A string value representation agent's name.
 */
- (void)uimClientAgentDidJoinChatWithAgentId:(NSString *)agentId
                                   agentName:(NSString *)agentName;

/**
 *  Tell delegate the agent did leave the chat.
 *
 *  @param agentId A string value representation agent's id.
 */
- (void)uimClientAgentDidLeaveChatWithAgentId:(NSString *)agentId;

/**
 *  Tell delegate the client did receive message.
 *
 *  @param senderId          A string value representation sender's id.
 *  @param senderDisplayName A string value representation sender's name.
 *  @param messageId         A string value representation message identifier.
 *  @param content           A string value representation message contents.
 */
- (void)uimClientDidReceiveMessageWithSenderId:(NSString *)senderId
                             senderDisplayName:(NSString *)senderDisplayName
                                     messageId:(NSString *)messageId
                                       content:(NSString *)content;

/**
 *  Tell delegate the client did receive media file.
 *
 *  @param senderId   A string value representation sender's id.
 *  @param senderName A string value representation sender's name.
 *  @param fileId     A string value representation file identifier.
 *  @param filename   A string value representation file name.
 */
- (void)uimClientDidReceiveMediaFileWithSenderId:(NSString *)senderId
                                      senderName:(NSString *)senderName
                                          fileId:(NSString *)fileId
                                        fileName:(NSString *)filename;

/**
 *  Tell delegate the client did end chat with agent.
 *
 *  @param chatId A string value representation chat identifier.
 */
- (void)uimClientDidEndChatWithChatId:(NSString *)chatId;

/**
 *  Tell delegate the client is failure with request.
 *
 *  @param code A `UIMErrorCode` value representation error code.
 *  @param message   A string value representation error reason.
 */
- (void)uimclientDidFailWithErrorCode:(UIMErrorCode)code message:(NSString *)message;

///-------------------------------
/// @name File Transfer
///-------------------------------

/**
 *  Tell delegate the client did begin download media file.
 *
 *  @param fileId   A string value representation file id.
 *  @param progress A float value representation the progress of the file.
 */
- (void)uimClientDidBeginDownloadMediaFileWithFileId:(NSString *)fileId
                                            progress:(float)progress;


/**
 *  Tell delegate the client did finish download file.
 *
 *  @param client The UIMClient instance representation which clietn trigger this event
 *  @param fileId A string value representation file id.
 *  @param path   A string value representation file's store path.
 *  @param error  A error object representation fail reason of the download.
 */
- (void)uimClient:(UIMClient *)client
didFinishDownloadFileWithId:(NSString *)fileId
           atPath:(NSString *)path
            error:(NSError *)error;

/**
 *  Tell delegate the client did begin upload media file.
 *
 *  @param fileId   A string value representation file id.
 *  @param progress A float value representation the progress of the file.
 */
- (void)uimClientDidBeginUploadMediaFileWithFileId:(NSString *)fileId
                                          progress:(float)progress;

/**
 *  Tell delegate the client did begin upload media file.
 *
 *  @param fileId A string value representation file id.
 *  @param error  A error object representation fail reason of the upload.
 */
- (void)uimclientDidFinishUploadMediaFileWithFileId:(NSString *)fileId
                                              error:(NSError *)error;

///-------------------------------
/// @name Connection
///-------------------------------

/**
 *  Tell delegate the client connection state did change.
 *
 *  @param state A `UIMClientConnecttionState` value representation new connection state.
 */
- (void)uimclientConnectionDidChangeState:(UIMClientConnecttionState)state;

/**
 *  Tell delegate the client connection did closed.
 *
 *  @param client The UIMClient instance representation which clietn trigger this event
 */
- (void)clientDidDisconnect:(UIMClient *)client;

/**
 *  Tell delegate the client already receive position, will trigger after -positionRequest: method called.
 *
 *  @param queuePosition An integer value representation your position in queue.
 */
- (void)uimClientDidReceiveQueuePosition:(NSInteger)queuePosition;

@end

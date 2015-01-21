//
//  ConnectationTest.m
//  UIMSDK
//
//  Created by Retso Huang on 1/15/15.
//  Copyright (c) 2015 Retso Huang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "UIMSDKTestCase.h"
@import UIMSDK;

@interface ConnectionTest : UIMSDKTestCase
@property (nonatomic, strong) XCTestExpectation *connectExpectation;
@property (nonatomic, strong) XCTestExpectation *beginChatExpectation;
@property (nonatomic, strong) XCTestExpectation *endChatExpectation;
@property (nonatomic, strong) XCTestExpectation *disconnectExpectation;
@property (nonatomic, strong) NSString *userDisplayName;
@property (nonatomic, strong) NSString *chatId;
@end

@implementation ConnectionTest

- (void)setUp {
  [super setUp];
  self.userDisplayName = @"retso";
  self.connectExpectation = [self expectationWithDescription:@"Connect test"];
  self.beginChatExpectation = [self expectationWithDescription:@"Begin chat test"];
  self.endChatExpectation = [self expectationWithDescription:@"End chat test."];
  self.disconnectExpectation = [self expectationWithDescription:@"Disconnect test"];
}

- (void)testConnect {
  
  XCTAssertEqual(self.client.connectionState, UIMClientConnecttionStateConnecting);
  
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    if (error) {
      NSLog(@"timeout error: %@", error);
    }
  }];
  
}

- (void)beginChat {
  [self.client beginChatWithChannel:@"mobile" custID:@"" displayName:self.userDisplayName phoneNumber:@"111111" email:@"example@gmail.com" problem:@"A" skill:@"A" userInfo:@{@"CustomerID": @""}];
}

- (void)endChat {
  [self.client endChat];
}

- (void)disconnect {
  [self.client disconnect];
  
  XCTAssertEqual(self.client.connectionState, UIMClientConnecttionStateDisconnected);
}

#pragma mark - UIMClientDelegate
- (void)uimclientConnectionDidChangeState:(UIMClientConnecttionState)state {
  
  if (state == UIMClientConnecttionStateConnected &&
      self.client.connectionState == UIMClientConnecttionStateConnected) {
    [self.connectExpectation fulfill];
    [self beginChat];
  }
  
}

- (void)uimClientDidBeginChatWithChatId:(NSString *)chatId {
  XCTAssertNotNil(chatId);
  self.chatId = chatId;
}

- (void)uimClientDidEndChatWithChatId:(NSString *)chatId {
  if ([chatId isEqualToString:self.chatId]) {
    [self.endChatExpectation fulfill];
    [self disconnect];
  }
}

- (void)clientDidDisconnect:(UIMClient *)client {
  XCTAssertEqual(client, self.client);
  [self.disconnectExpectation fulfill];
}

- (void)uimClientAgentDidJoinChatWithAgentId:(NSString *)agentId agentName:(NSString *)agentName {
  XCTAssertNotNil(agentId);
  XCTAssertNotNil(agentName);
  XCTAssertNotEqual(agentName, self.userDisplayName);
  
  [self.beginChatExpectation fulfill];
  [self endChat];
}

@end

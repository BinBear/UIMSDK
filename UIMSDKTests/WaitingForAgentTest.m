//
//  WaitingForAgentTest.m
//  UIMSDK
//
//  Created by Retso Huang on 1/19/15.
//  Copyright (c) 2015 Retso Huang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "UIMSDKTestCase.h"

@interface WaitingForAgentTest : UIMSDKTestCase
@property (nonatomic, strong) XCTestExpectation *connectExpectation;
@property (nonatomic, strong) XCTestExpectation *agentNorAvailabelExpectation;
@end

@implementation WaitingForAgentTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testAgentNotAvailable {
  XCTAssertEqual(self.client.connectionState, UIMClientConnecttionStateConnecting);
  
  self.connectExpectation = [self expectationWithDescription:@"Connect test"];
  self.agentNorAvailabelExpectation = [self expectationWithDescription:@"Agent not available."];
  
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    if (error) {
      NSLog(@"timeout error: %@", error);
    }
  }];
}

- (void)beginChat {
  [self.client beginChatWithChannel:@"mobile" custID:@"" displayName:@"retso" phoneNumber:@"111111" email:@"example@gmail.com" problem:@"A" skill:@"A" userInfo:@{@"CustomerID": @""}];
}

#pragma mark - UIMClientDelegate
- (void)uimclientConnectionDidChangeState:(UIMClientConnecttionState)state {
  
  if (state == UIMClientConnecttionStateConnected &&
      self.client.connectionState == UIMClientConnecttionStateConnected) {
    [self.connectExpectation fulfill];
    [self beginChat];
  }
  
}

- (void)uimClientWaitingForAgent:(NSInteger)queuePosition {
  [self.agentNorAvailabelExpectation fulfill];
}

@end

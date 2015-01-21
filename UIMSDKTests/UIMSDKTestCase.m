//
//  UIMSDKTestCase.m
//  UIMSDK
//
//  Created by Retso Huang on 1/15/15.
//  Copyright (c) 2015 Retso Huang. All rights reserved.
//

#import "UIMSDKTestCase.h"

@implementation UIMSDKTestCase

- (void)setUp {
  [super setUp];
  self.client = [[UIMClient alloc] initWithTenantId:@"CA"];
  self.client.delegate = self;
  [self.client connect:@"http://1.34.252.176:8081/chat1"];
}

@end

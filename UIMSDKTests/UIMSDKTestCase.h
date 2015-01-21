//
//  UIMSDKTestCase.h
//  UIMSDK
//
//  Created by Retso Huang on 1/15/15.
//  Copyright (c) 2015 Retso Huang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
@import UIMSDK;

@interface UIMSDKTestCase : XCTestCase <UIMClientDelegate>
@property (nonatomic, strong) UIMClient *client;
@end

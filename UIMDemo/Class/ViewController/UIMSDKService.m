//
//  UIMService.m
//  UIMIOS
//
//  Created by Retso Huang on 10/24/14.
//  Copyright (c) 2014 Retso Huang. All rights reserved.
//

#import "UIMSDKService.h"

@implementation UIMSDKService

#pragma mark - Shared Instance
+ (instancetype)sharedService {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  
  return sharedInstance;
}

#pragma mark - Life Cycle

- (instancetype)init {
  self = [super init];
  if (self) {
    
    self.client = [[UIMClient alloc] initWithTenantId:@"CA"];
  }
  return self;
}


@end

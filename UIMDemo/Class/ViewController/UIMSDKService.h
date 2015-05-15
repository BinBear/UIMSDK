//
//  UIMService.h
//  UIMIOS
//
//  Created by Retso Huang on 10/24/14.
//  Copyright (c) 2014 Retso Huang. All rights reserved.
//

#import "UIMClient.h"

@interface UIMSDKService : NSObject

@property (nonatomic, strong) UIMClient *client;

/**
 * gets singleton object.
 * @return singleton
 */
+ (instancetype)sharedService;

@end

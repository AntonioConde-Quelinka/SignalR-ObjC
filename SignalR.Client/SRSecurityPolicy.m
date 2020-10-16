//
//  SRSecurityPolicy.m
//  SignalR.Client.ObjC
//
//  Created by Kris Katsanevas on 4/15/20.
//  Copyright © 2020 DyKnow LLC. All rights reserved.
//

#import "SRSecurityPolicy.h"

@implementation SRSecurityPolicy

+ (instancetype)sharedManager {
    static SRSecurityPolicy *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init {
  if (self = [super init]) {
      self.allowInvalidCertificates = false;
      self.validatesDomainName = true;
  }
  return self;
}

@end

//
//  SRSecurityPolicy.h
//  SignalR.Client.ObjC
//
//  Created by Kris Katsanevas on 4/15/20.
//  Copyright © 2020 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRSecurityPolicy : NSObject
@property (nonatomic, assign) BOOL allowInvalidCertificates;
@property (nonatomic, assign) BOOL validatesDomainName;
+ (instancetype)sharedManager;
@end

NS_ASSUME_NONNULL_END

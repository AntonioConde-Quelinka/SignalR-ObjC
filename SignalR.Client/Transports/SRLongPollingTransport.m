//
//  SRLongPollingTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of 
//  the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
//  DEALINGS IN THE SOFTWARE.
//

#import <AFNetworking/AFNetworking.h>
#import "SRConnectionInterface.h"
#import "SRConnectionExtensions.h"
#import "SRExceptionHelper.h"
#import "SRLog.h"
#import "SRLongPollingTransport.h"
#import "SRSecurityPolicy.h"

 @interface SRLongPollingTransport()
 
 
 @end

@implementation SRLongPollingTransport

- (instancetype)init {
    if (self = [super init]) {
        _reconnectDelay = @5;
        _errorDelay = @2;
    }
    return self;
}

#pragma mark 
#pragma mark SRClientTransportInterface

- (NSString *)name {
    return @"longPolling";
}

- (BOOL)supportsKeepAlive {
    return NO;
}

- (void)negotiate:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(SRNegotiationResponse *response, NSError *error))block {
    SRLogLPDebug(@"longPolling will negotiate");
    [super negotiate:connection connectionData:connectionData completionHandler:block];
}

- (void)start:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    SRLogLPDebug(@"longPolling will connect with connectionData %@", connectionData);
    [self poll:connection connectionData:connectionData completionHandler:block];
}

- (void)send:(id<SRConnectionInterface>)connection data:(NSString *)data connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    SRLogLPDebug(@"longPolling will send data %@", data);
    [super send:connection data:data connectionData:connectionData completionHandler:block];
}

- (void)abort:(id<SRConnectionInterface>)connection timeout:(NSNumber *)timeout connectionData:(NSString *)connectionData {
    SRLogLPDebug(@"longPolling will abort");
    [super abort:connection timeout:timeout connectionData:connectionData];
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
    SRLogLPDebug(@"longPolling lost connection");
}

#pragma mark -
#pragma mark LongPolling

- (void)poll:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    
    __block NSNumber *canReconnect = @(YES);

    NSString *url = connection.url;
    if(connection.messageId == nil) {
        url = [url stringByAppendingString:@"connect"];
    } else if ([self isConnectionReconnecting:connection]) {
        url = [url stringByAppendingString:@"reconnect"];
    } else {
        url = [url stringByAppendingString:@"poll"];
    }
    
    [self delayConnectionReconnect:connection canReconnect:canReconnect];
    
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    
    id parameters = @{
        @"transport" : [self name],
        @"connectionToken" : ([connection connectionToken]) ? [connection connectionToken] : @"",
        @"messageId" : ([connection messageId]) ? [connection messageId] : @"",
        @"groupsToken" : ([connection groupsToken]) ? [connection groupsToken] : @"",
        @"connectionData" : (connectionData) ? connectionData : @"",
    };
    
    if ([connection queryString]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:[connection queryString]];
        parameters = _parameters;
    }
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:url parameters:parameters error:nil];
    [connection prepareRequest:request]; //TODO: prepareRequest
    [request setTimeoutInterval:240];
    
    SRLogLPDebug(@"longPolling will connect at url: %@", [[request URL] absoluteString]);
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer = serializer;
    manager.securityPolicy.allowInvalidCertificates = [SRSecurityPolicy sharedManager].allowInvalidCertificates;
    manager.securityPolicy.validatesDomainName = [SRSecurityPolicy sharedManager].validatesDomainName;
    
    if (connection.challengeHandler) {
        [manager setAuthenticationChallengeHandler: connection.challengeHandler];
    }
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;

        BOOL shouldReconnect = NO;
        BOOL disconnectedReceived = NO;
        NSError *serializationError = nil;
        
        NSInteger httpStatusCode = 0;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (id)response;
            httpStatusCode = httpResponse.statusCode;
        }
        
        //Status code needs to be 200 to 299
        if (httpStatusCode < 200 || httpStatusCode >= 300 || error != nil) {
            SRLogLPError(@"longPolling did fail with error %@", error);
            
            canReconnect = @(NO);
            
            // Transition into reconnecting state
            [SRConnection ensureReconnecting:strongConnection];
            
            if (![strongSelf tryCompleteAbort] &&
                ![SRExceptionHelper isRequestAborted:error]) {
                [strongConnection didReceiveError:error];
                
                SRLogLPDebug(@"will poll again in %ld seconds",(long)[_errorDelay integerValue]);
                
                canReconnect = @(YES);
                
                [[NSBlockOperation blockOperationWithBlock:^{
                    [strongSelf poll:strongConnection connectionData:connectionData completionHandler:nil];
                }] performSelector:@selector(start) withObject:nil afterDelay:[strongSelf.errorDelay integerValue]];
                
            } else {
                [strongSelf completeAbort];
                if (block) {
                    block(nil,error);
                }
            }
            return;
        }
        
        NSString *responseString = nil;
        if (responseObject != nil) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&serializationError];
            responseString = data == nil ? nil : [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        SRLogLPInfo(@"longPolling did receive: %@", responseString);
        
        [strongSelf processResponse:strongConnection response:responseString shouldReconnect:&shouldReconnect disconnected:&disconnectedReceived];
        if (block) {
           block(nil, nil);
        }

        if ([strongSelf isConnectionReconnecting:strongConnection]) {
           // If the timeout for the reconnect hasn't fired as yet just fire the
           // event here before any incoming messages are processed
           SRLogLPWarn(@"reconnecting");
           [strongSelf connectionReconnect:strongConnection canReconnect:canReconnect];
        }

        if (shouldReconnect) {
           // Transition into reconnecting state
           SRLogLPDebug(@"longPolling did receive shouldReconnect command from server");
           [SRConnection ensureReconnecting:strongConnection];
        }

        if (disconnectedReceived) {
           SRLogLPDebug(@"longPolling did receive disconnect command from server");
           [strongConnection disconnect];
        }

        if (![strongSelf tryCompleteAbort]) {
           //Abort has not been called so continue polling...
           canReconnect = @(YES);
           [strongSelf poll:strongConnection connectionData:connectionData completionHandler:nil];
        } else {
           SRLogLPWarn(@"longPolling has shutdown due to abort");
        }
    }];
    
    [dataTask resume];
}

- (void)delayConnectionReconnect:(id<SRConnectionInterface>)connection canReconnect:(NSNumber *)canReconnect {
    if ([self isConnectionReconnecting:connection]) {
        __weak __typeof(&*self)weakSelf = self;
        __weak __typeof(&*connection)weakConnection = connection;
        __weak __typeof(&*canReconnect)weakCanReconnect = canReconnect;
        SRLogLPDebug(@"will reconnect in %@", self.reconnectDelay);
        [[NSBlockOperation blockOperationWithBlock:^{
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            __strong __typeof(&*weakCanReconnect)strongCanReconnect = weakCanReconnect;
            SRLogLPWarn(@"reconnecting");
            [strongSelf connectionReconnect:strongConnection canReconnect:strongCanReconnect];
            
        }] performSelector:@selector(start) withObject:nil afterDelay:[self.reconnectDelay integerValue]];
    }
}

- (void)connectionReconnect:(id<SRConnectionInterface>)connection canReconnect:(NSNumber *)canReconnect {
    if ([canReconnect boolValue]) {
        canReconnect = @(NO);
        // Mark the connection as connected
        if ([connection changeState:reconnecting toState:connected]) {
            [connection didReconnect];
        }
    }
}

- (BOOL)isConnectionReconnecting:(id<SRConnectionInterface>)connection {
    return connection.state == reconnecting;
}

@end

//
//  SignalR-ObjC.h
//  SignalR.Client.ObjC
//
//  Created by Antonio Conde on 6/11/25.
//  Copyright © 2025 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for SignalR-ObjC.
FOUNDATION_EXPORT double SignalR_ObjCVersionNumber;

//! Project version string for SignalR-ObjC.
FOUNDATION_EXPORT const unsigned char SignalR_ObjCVersionString[];

// Connections
#import "SRConnection.h"

// Hubs
#import "SRHubConnection.h"
#import "SRHubProxy.h"
#import "SRHubResult.h"
#import "SRHubInvocation.h"

// Transports
#import "SRClientTransportInterface.h"
#import "SRAutoTransport.h"
#import "SRLongPollingTransport.h"
#import "SRServerSentEventsTransport.h"
#import "SRWebSocketTransport.h"

// Infrastructure
#import "SRVersion.h"
#import "SRLog.h"

// Otros headers públicos necesarios...
#import "SRSerializable.h"
#import "SRDeerializable.h"
#import "SRExceptionHelper.h"
#import "SRWebSocketConnectionInfo.h"
#import "SRHubs.h"
#import "SignalRSecurityPolicy.h"


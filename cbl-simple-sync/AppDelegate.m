//
//  AppDelegate.m
//  cbl-simple-sync
//
//  Created by Danil Nikiforov on 03.03.15.
//  Copyright (c) 2015 Danil. All rights reserved.
//

#import "AppDelegate.h"
#import <CouchbaseLite/CouchbaseLite.h>

#define syncGatewayUrl @"http://10.69.32.73:4984/gw"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [AppDelegate runSync];
    [CBLManager enableLogging:@"Sync"];
    [CBLManager enableLogging:@"SyncVerbose"];
    return YES;
}

+ (CBLDatabase *)database{
    NSError* error;
    CBLManager  * manager  = [CBLManager sharedInstance];
    CBLDatabase* db = [manager databaseNamed:@"db-name" error: &error];
    return db;
}

+ (void)runSync{
    CBLReplication * push = [[self database] createPushReplication:[NSURL URLWithString:syncGatewayUrl]];
    CBLReplication * pull = [[self database] createPullReplication:[NSURL URLWithString:syncGatewayUrl]];
    
    for (CBLReplication * repl in @[push, pull]) {
        [repl setContinuous:YES];
        [repl start];
    }
}


@end

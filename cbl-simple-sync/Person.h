//
//  SalesPerson.h
//  CBLiteCRM
//
//  Created by Danil on 26/11/13.
//  Copyright (c) 2013 Couchbase. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>

@interface Person : CBLModel

@property (strong) NSString* name;
@property (strong) NSString* position;

- (instancetype) initInDatabase: (CBLDatabase*)database
                      withId: (NSString*)docId;

@end

//
//  SalesPerson.m
//  CBLiteCRM
//
//  Created by Danil on 26/11/13.
//  Copyright (c) 2013 Couchbase. All rights reserved.
//

#import "Person.h"

@implementation Person
@dynamic name, position;

- (instancetype) initInDatabase: (CBLDatabase*)database
                      withId: (NSString*)docId
{
    NSString* docID = docId;
    CBLDocument* doc = [database existingDocumentWithID:docID];
    if(!doc){
        doc = [database documentWithID: docID];
    }
    
    self = doc.modelObject;

    if(!self)
        self = [Person modelForDocument:doc];

    return self;
}


@end

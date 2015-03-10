//
//  ViewController.m
//  cbl-simple-sync
//
//  Created by Danil Nikiforov on 03.03.15.
//  Copyright (c) 2015 Danil. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Person.h"

#define docId @"123"

@interface ViewController (){
    Person* currentPerson;
}
@property (strong, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *position;

@end

@implementation ViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self showCurrentPerson];
}

-(void)showCurrentPerson{
    currentPerson = [self getPersonFromDB];
    if(currentPerson)
        self.name.text = currentPerson.name;
    self.position.text = currentPerson.position;
}

- (Person*)getPersonFromDB{
    NSError* error;
    
    CBLView* personsView = [AppDelegate.database viewNamed: @"persons"];
    [personsView setMapBlock: MAPBLOCK({
        emit(doc[@"_id"], nil);
    }) version: @"2"];
    
    
    CBLQuery* personQuery = [personsView createQuery];
    personQuery.keys = @[docId];
    CBLQueryEnumerator* result = [personQuery run:&error];
    NSLog(@"personQuery run:&error: %@", error);
    Person* model = nil;
    if(result.count>0){
        CBLQueryRow* row = [result nextObject];
        CBLDocument* doc = [row document];
        model = [Person modelForDocument:doc];
    }
    return model;
}

- (void)putPersonInDB{
    NSError * error = nil;
    Person * person = nil;
    if(currentPerson){
        person = currentPerson;
    }else{
        person = [[Person alloc] initInDatabase:AppDelegate.database withId:docId];
    }
    person.name = self.name.text;
    person.position = self.position.text;
    [person save:&error];
    NSLog(@"save:&error: %@", error);
}

- (IBAction)save:(id)sender {
    [self putPersonInDB];
    
}

- (IBAction)update:(id)sender {
    __block NSError * error = nil;
    Person * person = nil;
    if(currentPerson){
        person = currentPerson;
    }else{
        person = [[Person alloc] initInDatabase:AppDelegate.database withId:docId];
    }
    
    CBLDocument* personDoc = person.document;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [personDoc update:^BOOL(CBLUnsavedRevision * newRev) {
            newRev[@"name"] = self.name.text;
            newRev[@"position"] = self.position.text;
            sleep(30000);
    //        person.name = self.name.text;
    //        person.position = self.position.text;
            return YES;
        } error:&error];
    });
    NSLog(@"save:&error: %@", error);
}

- (IBAction)refresh:(id)sender {
    [self showCurrentPerson];
}


- (IBAction)checkConflicts:(id)sender {
    CBLDocument* doc = [AppDelegate.database documentWithID: docId];
    NSError* error;
    NSArray* conflicts = [doc getConflictingRevisions: &error];
    if (conflicts.count > 1) {
        // There is more than one current revision, thus a conflict!
        [AppDelegate.database inTransaction: ^BOOL{
            NSDictionary* mergedProps = [self mergeRevisions: conflicts];

            // Delete the conflicting revisions to get rid of the conflict:
            CBLSavedRevision* current = doc.currentRevision;
            for (CBLSavedRevision* rev in conflicts) {
                NSLog(@"rev prop: %@ is deleted: %i", rev.properties, rev.isDeletion);
                CBLUnsavedRevision *newRev = [rev createRevision];
                if (rev == current) {
                    // add the merged revision
                    newRev.userProperties = [NSMutableDictionary dictionaryWithDictionary:mergedProps];
                } else {
                    // mark other conflicts as deleted
                    newRev.isDeletion = YES;
                }

                NSError *error;
                if (![newRev saveAllowingConflict: &error]){
                    NSLog(@"newRev save: &error: %@", error);
                    return NO;
                }
            }
            return YES;
        }];
        [self showCurrentPerson];
    }
}

- (NSDictionary*)mergeRevisions:(NSArray*)conflicts {
    // Note: the first revision in the conflicts array may not be a current revision:
    NSDictionary* userProperties = ((CBLRevision*)conflicts[0]).userProperties;
    NSMutableDictionary* mergedDict = [NSMutableDictionary dictionaryWithDictionary:userProperties];
    for (CBLRevision* rev in conflicts) {
        if (rev == conflicts[0])
            continue;
        for (NSString* key in rev.userProperties) {
            mergedDict[key] = [NSString stringWithFormat:@"%@ %@", mergedDict[key], rev.properties[key]];
        }
    }
    NSLog(@"final properties to merge: %@", mergedDict);
    return mergedDict;
}

@end

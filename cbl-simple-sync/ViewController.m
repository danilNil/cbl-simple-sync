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

- (IBAction)update:(id)sender {
    [self putPersonInDB];
    
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
//        [AppDelegate.database inTransaction: ^BOOL{
            // Come up with a merged/resolved document in some way that's
            // appropriate for the app. You could even just pick the body of
            // one of the revisions.
            NSDictionary* mergedProps = [self mergeRevisions: conflicts];
            
            // Delete the conflicting revisions to get rid of the conflict:
            CBLSavedRevision* current = doc.currentRevision;
            for (CBLSavedRevision* rev in conflicts) {
                NSLog(@"rev prop: %@ is deleted: %i", rev.properties, rev.isDeletion);
                CBLUnsavedRevision *newRev = [rev createRevision];
                if (rev == current) {
                    // add the merged revision
                    newRev.properties = [NSMutableDictionary dictionaryWithDictionary: mergedProps];
                } else {
                    // mark other conflicts as deleted
                    newRev.isDeletion = YES;
                }

                NSError *error;
                if (![newRev saveAllowingConflict: &error]){
                    NSLog(@"newRev save: &error: %@", error);
//                    return NO;
                }
            }
//            return YES;
//        }];
//        NSError* error;
        [AppDelegate runSync];
        [self showCurrentPerson];
    }
}

- (NSDictionary*)mergeRevisions:(NSArray*)conflicts{
    NSMutableDictionary* mergedDict = [[NSMutableDictionary alloc] initWithDictionary:((CBLRevision*)conflicts[0]).properties];
    NSMutableArray* array = [NSMutableArray arrayWithArray:conflicts];
    [array removeObjectAtIndex:0];
    for(CBLRevision* rev in array){
        for(NSString* key in rev.properties){
            if(![key isEqualToString:@"_id"] && ![key isEqualToString:@"_rev"] && ![key isEqualToString:@"_revisions"])
                mergedDict[key] = [NSString stringWithFormat:@"%@ %@", mergedDict[key], rev.properties[key]];
        }
    }
    NSLog(@"final properties to merge: %@", mergedDict);
    return mergedDict;
}
@end

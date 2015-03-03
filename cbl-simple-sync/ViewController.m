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
}

- (IBAction)update:(id)sender {
    [self putPersonInDB];

}

- (IBAction)refresh:(id)sender {
    [self showCurrentPerson];
}
@end

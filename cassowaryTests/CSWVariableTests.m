#import <XCTest/XCTest.h>
#import "CSWVariable.h"
#import "CSWVariable+PrivateMethods.h"

@interface CSWVariableTests : XCTestCase

@end

@implementation CSWVariableTests

- (void)testCanInitVariableWithValue {
    CSWVariable * variable = [CSWVariable variableWithValue: 10];
    XCTAssertEqual([variable value], 10);
}

- (void)testCanInitVariableWithValueAndName
{
    CSWVariable *variable = [CSWVariable variableWithValue: 11 name: @"x"];
    XCTAssertEqual([variable value], 11);
    XCTAssertEqual([variable name], @"x");
}

-(void)testVariableIsEqualWithIdenticalProperties
{
    CSWVariable *variable = [CSWVariable variableWithValue:11 name:@"x"];
    CSWVariable *otherVariable = [CSWVariable variableWithValue:11 name:@"x"];
    XCTAssertTrue([variable isEqual:otherVariable]); 
}

-(void)testVariableIsNotDummy
{
    CSWVariable *variable = [CSWVariable variable];
    XCTAssertFalse([variable isDummy]);
}

-(void)testVariableIsExternal
{
    CSWVariable *variable = [CSWVariable variable];
    XCTAssertTrue([variable isExternal]);
}

-(void)testVariableIsNotPivotable
{
    CSWVariable *variable = [CSWVariable variable];
    XCTAssertFalse([variable isPivotable]);
}

-(void)testVariableIsRestricted
{
    CSWVariable *variable = [CSWVariable variable];
    XCTAssertFalse([variable isRestricted]);
}

-(void)testVariableDescription
{
    CSWVariable *variable = [CSWVariable variableWithValue:100 name:@"y"];
    XCTAssertTrue([[variable description] isEqualToString:@"[y:100.00]"]);
}

-(void)testCanInitDummyVariableWithName
{
    CSWVariable *dummyVariable = [CSWVariable  dummyVariableWithName:@"dummy"];
    XCTAssertNotNil(dummyVariable);
}

-(void)testDummyVariableIsDummy
{
    CSWVariable *dummyVariable = [CSWVariable  dummyVariableWithName:@"dummy"];
    XCTAssertTrue([dummyVariable isDummy]);
}

-(void)testDummyVariableIsNotExternal
{
    CSWVariable *dummyVariable = [CSWVariable  dummyVariableWithName:@"dummy"];
    XCTAssertFalse([dummyVariable isExternal]);
}

-(void)testDummyVariableIsNotPivotable
{
    CSWVariable *dummyVariable = [CSWVariable  dummyVariableWithName:@"dummy"];
    XCTAssertFalse([dummyVariable isPivotable]);
}

-(void)testIsRestricted
{
    CSWVariable *dummyVariable = [CSWVariable  dummyVariableWithName:@"dummy"];
    XCTAssertTrue([dummyVariable isRestricted]);
}

-(void)testDummyVariableDescription
{
    CSWVariable *dummyVariable = [CSWVariable  dummyVariableWithName:@"y"];
    XCTAssertTrue([[dummyVariable description] isEqualToString:@"[y:dummy]"]);
}

-(void)testCanInitSlackVariableWithName
{
    CSWVariable *variable = [CSWVariable slackVariableWithName:@"slack"];
    XCTAssertTrue([[variable name] isEqualToString:@"slack"]);
}

-(void)testSlackVariableIsNotExternal
{
    CSWVariable *variable = [CSWVariable slackVariableWithName:@"slack"];
    XCTAssertFalse([variable isExternal]);
}

-(void)testSlackVariableIsPivotable
{
    CSWVariable *variable = [CSWVariable slackVariableWithName:@"slack"];
    XCTAssertTrue([variable isPivotable]);
}

-(void)testSlackVariableIsRestricted
{
    CSWVariable *variable = [CSWVariable slackVariableWithName:@"slack"];
    XCTAssertTrue([variable isRestricted]);
}

-(void)testSlackVariableDescription
{
    CSWVariable *variable = [CSWVariable slackVariableWithName:@"x"];
    XCTAssertTrue([[variable description] isEqualToString:@"[x:slack]"]);
}

-(void)testObjectiveIsNotExternal
{
    CSWVariable *variable = [CSWVariable objectiveVariableWithName:@"obj"];
    XCTAssertFalse([variable isExternal]);
}

-(void)testObjectiveIsNotPivotable
{
    CSWVariable *variable = [CSWVariable objectiveVariableWithName:@"obj"];
    XCTAssertFalse([variable isPivotable]);
}

-(void)testObjectiveIsNotRestricted
{
    CSWVariable *variable = [CSWVariable objectiveVariableWithName:@"obj"];
    XCTAssertFalse([variable isRestricted]);
}

@end

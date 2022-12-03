#import <XCTest/XCTest.h>
#import "CSWVariable.h"
#import "CSWDummyVariable.h"
#import "CSWSlackVariable.h"

@interface CIVariableTests : XCTestCase

@end

@implementation CIVariableTests

- (void)testCanInitVariableWithValue {
    CSWVariable * variable = [[CSWVariable alloc] initWithValue: 10];
    XCTAssertEqual([variable value], 10);
}

- (void)testCanInitVariableWithValueAndName
{
    CSWVariable *variable = [[CSWVariable alloc] initWithValue: 11 name: @"x"];
    XCTAssertEqual([variable value], 11);
    XCTAssertEqual([variable name], @"x");
}

-(void)testVariableIsEqualWithIdenticalProperties
{
    CSWVariable *variable = [[CSWVariable alloc] initWithValue:11 name:@"x"];
    CSWVariable *otherVariable = [[CSWVariable alloc] initWithValue:11 name:@"x"];
    XCTAssertTrue([variable isEqual:otherVariable]); 
}

-(void)testVariableIsNotDummy
{
    CSWVariable *variable = [[CSWVariable alloc] init];
    XCTAssertFalse([variable isDummy]);
}

-(void)testVariableIsExternal
{
    CSWVariable *variable = [[CSWVariable alloc] init];
    XCTAssertTrue([variable isExternal]);
}

-(void)testVariableIsNotPivotable
{
    CSWVariable *variable = [[CSWVariable alloc] init];
    XCTAssertFalse([variable isPivotable]);
}

-(void)testVariableIsRestricted
{
    CSWVariable *variable = [[CSWVariable alloc] init];
    XCTAssertFalse([variable isRestricted]);
}

-(void)testVariableDescription
{
    CSWVariable *variable = [[CSWVariable alloc] initWithValue:100 name:@"y"];
    XCTAssertTrue([[variable description] isEqualToString:@"[y:100.00]"]);
}

-(void)testCanInitDummyVariableWithName
{
    CSWDummyVariable *dummyVariable = [[CSWDummyVariable alloc] initWithName: @"dummy"];
    XCTAssertNotNil(dummyVariable);
}

-(void)testDummyVariableIsDummy
{
    CSWDummyVariable *dummyVariable = [[CSWDummyVariable alloc] initWithName: @"dummy"];
    XCTAssertTrue([dummyVariable isDummy]);
}

-(void)testDummyVariableIsNotExternal
{
    CSWDummyVariable *dummyVariable = [[CSWDummyVariable alloc] init];
    XCTAssertFalse([dummyVariable isExternal]);
}

-(void)testDummyVariableIsNotPivotable
{
    CSWDummyVariable *dummyVariable = [[CSWDummyVariable alloc] init];
    XCTAssertFalse([dummyVariable isPivotable]);
}

-(void)testIsRestricted
{
    CSWDummyVariable *dummyVariable = [[CSWDummyVariable alloc] init];
    XCTAssertTrue([dummyVariable isRestricted]);
}

-(void)testDummyVariableDescription
{
    CSWDummyVariable *dummyVariable = [[CSWDummyVariable alloc] initWithName:@"y"];
    XCTAssertTrue([[dummyVariable description] isEqualToString:@"[y:dummy]"]);
}

-(void)testCanInitSlackVariableWithName
{
    CSWSlackVariable *variable = [[CSWSlackVariable alloc] initWithName:@"slack"];
    XCTAssertTrue([variable isKindOfClass:[CSWSlackVariable class]]);
    XCTAssertTrue([[variable name] isEqualToString:@"slack"]);
}

-(void)testSlackVariableIsNotExternal
{
    CSWSlackVariable *variable = [[CSWSlackVariable alloc] init];
    XCTAssertFalse([variable isExternal]);
}

-(void)testSlackVariableIsPivotable
{
    CSWSlackVariable *variable = [[CSWSlackVariable alloc] init];
    XCTAssertTrue([variable isPivotable]);
}

-(void)testSlackVariableIsRestricted
{
    CSWSlackVariable *variable = [[CSWSlackVariable alloc] init];
    XCTAssertTrue([variable isRestricted]);
}

-(void)testSlackVariableDescription
{
    CSWSlackVariable *variable = [[CSWSlackVariable alloc] initWithName:@"x"];
    XCTAssertTrue([[variable description] isEqualToString:@"[x:slack]"]);
}

@end

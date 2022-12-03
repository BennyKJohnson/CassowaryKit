//
//  CSWConstraintTests.m
//  cassowaryTests
//
//  Created by Benjamin Johnson on 13/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSWConstraint.h"
#import "CSWStrength.h"

@interface CSWConstraintTests : XCTestCase

@end

@implementation CSWConstraintTests

- (void)testInitDefaultsStrengthToRequiredAndWeightTo1
{
    CSWConstraint *constraint = [[CSWConstraint alloc] init];
    XCTAssertTrue([constraint isKindOfClass:[CSWConstraint class]]);
    XCTAssertEqual([constraint weight], 1.0);
    XCTAssertTrue([[constraint strength] isEqual:[CSWStrength strengthRequired]]);
}

-(void)testConstraintIsNotRequiredWhenStrengthIsNotRequired
{
    CSWConstraint *constraint = [[CSWConstraint alloc] initWithType:CSWConstraintTypeLinear strength:[CSWStrength strengthStrong] expression:nil variable:nil];
    XCTAssertFalse([constraint isRequired]);

}

-(void)testConstraintIsRequiredWhenStrengthIsRequired
{
    CSWConstraint *constraint = [[CSWConstraint alloc] init];
    XCTAssertTrue([constraint isRequired]);
}

-(void)testInitLinearConstraintWithExpression
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWConstraint *constraint = [[CSWConstraint alloc] initLinearConstraintWithExpression:expression];
    
    XCTAssertEqual([constraint expression], expression);
    XCTAssertEqual([constraint type], CSWConstraintTypeLinear);
}

-(CSWConstraint*)linearConstraint
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWConstraint *constraint = [[CSWConstraint alloc] initLinearConstraintWithExpression:expression];
    return constraint;
}

-(void)testLinearConstraintIsNotEditConstraint
{
    XCTAssertFalse([[self linearConstraint] isEditConstraint]);
}

-(void)testLinearConstraintIsNotStayConstraint
{
    XCTAssertFalse([[self linearConstraint] isStayConstraint]);
}

-(void)testLinearConstraintIsNotInequality
{
    XCTAssertFalse([[self linearConstraint] isInequality]);
}

-(void)testInitEditConstraintWithVariable
{
    CSWVariable *variable = [[CSWVariable alloc] initWithValue:5];
    CSWConstraint *editConstraint = [[CSWConstraint alloc] initEditConstraintWithVariable:variable stength:[CSWStrength strengthRequired]];
    XCTAssertEqual([editConstraint type], CSWConstraintTypeEdit);
    XCTAssertEqual([editConstraint variable], variable);
    XCTAssertEqual(editConstraint.expression.constant, 5);
    XCTAssertEqual([editConstraint.expression coefficientForTerm:variable], -1);
}

-(void)testEditConstraintIsEditConstraint
{
    CSWVariable *variable = [[CSWVariable alloc] initWithValue:5];
    CSWConstraint *editConstraint = [[CSWConstraint alloc] initEditConstraintWithVariable:variable stength:[CSWStrength strengthRequired]];
    XCTAssertTrue([editConstraint isEditConstraint]);
}

-(void)testInitStayConstraintWithVariableCoefficientAndConstant
{
    CSWVariable *variable = [[CSWVariable alloc] initWithValue:10];
    CSWConstraint *stayConstraint = [[CSWConstraint alloc] initStayConstraintWithVariable: variable strength:[CSWStrength strengthStrong] weight:1.0];
    
    XCTAssertTrue([stayConstraint isKindOfClass:[CSWConstraint class]]);
    XCTAssertEqual([stayConstraint type], CSWConstraintTypeStay);
    XCTAssertEqual([stayConstraint weight], 1.0);
    XCTAssertTrue([[stayConstraint strength] isEqual:[CSWStrength strengthStrong]]);
    XCTAssertEqual([stayConstraint variable], variable);
    
    XCTAssertEqual(stayConstraint.expression.constant, 10);
    XCTAssertEqual([stayConstraint.expression coefficientForTerm: variable], -1);
}

-(void)testCanInitWithLhsVariableEqualsRhsVariable
{
    CSWVariable *x = [[CSWVariable alloc] init];
    CSWVariable *y = [[CSWVariable alloc] init];
    
    CSWConstraint *constraint = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightVariable:y];
    XCTAssertEqual(constraint.type, CSWConstraintTypeLinear);
    XCTAssertEqual([constraint.expression constant], 0);
    XCTAssertEqual([constraint.expression coefficientForTerm:x], 1);
    XCTAssertEqual([constraint.expression coefficientForTerm:y], -1);
}

-(void)testCanInitWithLhsVariableLessThanOrEqualToRhsVariable
{
    CSWVariable *x = [[CSWVariable alloc] init];
    CSWVariable *y = [[CSWVariable alloc] init];
    
    CSWConstraint *constraint = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightVariable:y];
    XCTAssertEqual(constraint.type, CSWConstraintTypeLinear);
    XCTAssertEqual([constraint isInequality], YES);
    XCTAssertEqual([constraint.expression constant], 0);
    XCTAssertEqual([constraint.expression coefficientForTerm:x], -1);
    XCTAssertEqual([constraint.expression coefficientForTerm:y], 1);
}

@end

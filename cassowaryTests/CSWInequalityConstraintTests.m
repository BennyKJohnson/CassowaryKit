//
//  CSWInequalityConstraintTests.m
//  cassowaryTests
//
//  Created by Benjamin Johnson on 19/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSWInequalityConstraint.h"

@interface CSWInequalityConstraintTests : XCTestCase

@end

@implementation CSWInequalityConstraintTests

//-(void)testCanInitGreaterThanOrEqualToConstraint
//{
//    CSWVariable *x = [[CSWVariable alloc] init];
//    CSWInequalityConstraint *constraint = [[CSWInequalityConstraint alloc] initWithLhsVariable:x operator:CSWConstraintOperationGreaterThanOrEqual rhsConstant:10];
//    
//    XCTAssertTrue([constraint isKindOfClass:[CSWInequalityConstraint class]]);
//    XCTAssertEqual([constraint.expression constant], -10);
//    XCTAssertEqual([constraint.expression coefficientForTerm:x], 1.0);
//}
//
//-(void)testCanInitEqualToConstraint
//{
//    CSWVariable *x = [[CSWVariable alloc] init];
//    CSWInequalityConstraint *constraint = [[CSWInequalityConstraint alloc] initWithLhsVariable:x operator: CSWConstraintOperatorEqual rhsConstant:10];
//    
//    XCTAssertTrue([constraint isKindOfClass:[CSWInequalityConstraint class]]);
//    XCTAssertEqual([constraint.expression constant], 10);
//    XCTAssertEqual([constraint.expression coefficientForTerm:x], -1.0);
//}
//
//-(void)testCanInitLessThanOrEqualToConstraint
//{
//    CSWVariable *x = [[CSWVariable alloc] init];
//    CSWInequalityConstraint *constraint = [[CSWInequalityConstraint alloc] initWithLhsVariable:x operator: CSWConstraintOperatorLessThanOrEqual rhsConstant: 10];
//    
//    XCTAssertTrue([constraint isKindOfClass:[CSWInequalityConstraint class]]);
//    XCTAssertEqual([constraint.expression constant], 10);
//    XCTAssertEqual([constraint.expression coefficientForTerm:x], -1.0);
//}

@end

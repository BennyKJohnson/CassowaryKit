//
//  CSWInequalityConstraint.m
//  cassowary
//
//  Created by Benjamin Johnson on 19/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import "CSWInequalityConstraint.h"

@implementation CSWInequalityConstraint

-(instancetype)initWithLhsVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rhsConstant:(CSWDouble)rhsValue
{
    CSWLinearExpression *valueExpression = [[CSWLinearExpression alloc] initWithConstant:rhsValue];

    if (self = [super initLinearConstraintWithExpression: valueExpression strength:[CSWStrength strengthRequired] variable:nil]) {
        if (operator == CSWConstraintOperatorEqual) {
            [self.expression addVariable:lhs coefficient:-1.0];
        } else if (operator == CSWConstraintOperationGreaterThanOrEqual) {
            [self.expression multiplyConstantAndTermsBy:-1];
            [self.expression addVariable:lhs coefficient:1.0];
        } else if (operator == CSWConstraintOperatorLessThanOrEqual) {
            [self.expression addVariable:lhs coefficient:-1.0];
        }
    }
    return self;
}

-(instancetype)initWithLhsConstant: (CSWDouble)lhs operator:(CSWConstraintOperator)operator rhsVariable:(CSWAbstractVariable*)rhsValue
{
    CSWLinearExpression *valueExpression = [[CSWLinearExpression alloc] initWithConstant:lhs];
    
        if (self = [super initLinearConstraintWithExpression: valueExpression strength:[CSWStrength strengthRequired] variable:nil]) {
            if (operator == CSWConstraintOperatorEqual) {
                [self.expression addVariable:rhsValue coefficient:-1.0];
            } else if (operator == CSWConstraintOperationGreaterThanOrEqual) {
                [self.expression addVariable:rhsValue coefficient:-1.0];
            } else if (operator == CSWConstraintOperatorLessThanOrEqual) {
                [self.expression multiplyConstantAndTermsBy:-1];
                [self.expression addVariable:rhsValue coefficient:1.0];
            }
        }
        return self;
}


-(instancetype)initWithLhsVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rhsVariable: (CSWAbstractVariable*)rhs
{
    CSWLinearExpression *rhsExpression = [[CSWLinearExpression alloc] initWithVariable: rhs];
    self = [super initLinearConstraintWithExpression: rhsExpression strength:[CSWStrength strengthRequired] variable:nil];
    if (self != nil) {
        if (operator == CSWConstraintOperationGreaterThanOrEqual) {
            [self.expression multiplyConstantAndTermsBy:-1];
            [self.expression addVariable:lhs];
        } else if (operator == CSWConstraintOperatorLessThanOrEqual) {
            [self.expression addVariable:lhs coefficient:-1];
        }
    }
    
    return self;
}

-(instancetype)initWithLhsVariable: (CSWAbstractVariable*)lhsVariable operator: (CSWConstraintOperator)operator rhsExpression: (CSWLinearExpression*)rhs {
    CSWLinearExpression *lhsExpression = [[CSWLinearExpression alloc] initWithVariable:lhsVariable];
    return [self initWithLhsExpression:lhsExpression operator:operator rhsExpression:rhs];
}

-(instancetype)initWithLhsExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rhsVariable: (CSWAbstractVariable*)rhs
{
    CSWLinearExpression *rhsExpression = [[CSWLinearExpression alloc] initWithVariable:rhs];
    return [self initWithLhsExpression:lhs operator:operator rhsExpression:rhsExpression];
}

-(instancetype)initWithLhsExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rhsExpression: (CSWLinearExpression*)rhs
{
    self = [super initLinearConstraintWithExpression: [rhs copy] strength:[CSWStrength strengthRequired] variable:nil];
    if (self != nil) {
        if (operator == CSWConstraintOperationGreaterThanOrEqual) {
            [self.expression multiplyConstantAndTermsBy:-1];
            [self.expression addExpression:lhs];
        } else if (operator == CSWConstraintOperatorLessThanOrEqual) {
            [self.expression addExpression:lhs multiplier:-1];
        } else {
            [self.expression addExpression:lhs multiplier:-1];
        }
    }
    
    return self;
}

-(BOOL)isInequality {
    return YES;
}

@end

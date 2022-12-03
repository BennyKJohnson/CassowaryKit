#import "CSWConstraintFactory.h"

@implementation CSWConstraintFactory

+(CSWConstraint*)constraintWithLeftVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWAbstractVariable*)rhsVariable
{
    if (operator == CSWConstraintOperatorEqual) {
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:lhs];
        [expression addVariable:rhsVariable coefficient:-1];

        return [[CSWConstraint alloc] initLinearConstraintWithExpression:expression];
    } else {
        CSWLinearExpression *rhsExpression = [[CSWLinearExpression alloc] initWithVariable: rhsVariable];
        if (operator == CSWConstraintOperationGreaterThanOrEqual) {
             [rhsExpression multiplyConstantAndTermsBy:-1];
             [rhsExpression addVariable:lhs];
         } else if (operator == CSWConstraintOperatorLessThanOrEqual) {
             [rhsExpression addVariable:lhs coefficient:-1];
         }

        return [[CSWInequalityConstraint alloc] initLinearConstraintWithExpression:rhsExpression];
    }
}

+(CSWConstraint*)constraintWithLeftVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rightExpression: (CSWLinearExpression*)rhs {
    CSWLinearExpression *lhsExpression = [[CSWLinearExpression alloc] initWithVariable:lhs];
    return [self constraintWithLeftExpression:lhsExpression operator:operator rightExpression:rhs];
}

+(CSWConstraint*)constraintWithLeftVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rightConstant: (CSWDouble)rhs
{
    if (operator == CSWConstraintOperatorEqual) {
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
        [expression addVariable:lhs coefficient:1];
        [expression setConstant:-rhs];
        
        return [[CSWConstraint alloc] initLinearConstraintWithExpression:expression strength:[CSWStrength strengthRequired] variable:nil];
    } else {
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithConstant:rhs];
        if (operator == CSWConstraintOperationGreaterThanOrEqual) {
              [expression multiplyConstantAndTermsBy:-1];
              [expression addVariable:lhs coefficient:1.0];
        } else if (operator == CSWConstraintOperatorLessThanOrEqual) {
              [expression addVariable:lhs coefficient:-1.0];
        }
        
        return [[CSWInequalityConstraint alloc] initLinearConstraintWithExpression:expression];
    }
}

+(CSWConstraint*)constraintWithLeftConstant: (CSWDouble)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWAbstractVariable*)rhs
{
    CSWLinearExpression *valueExpression = [[CSWLinearExpression alloc] initWithConstant:lhs];
    if (operator == CSWConstraintOperatorEqual) {
        [valueExpression addVariable:rhs coefficient:-1.0];
        return [[CSWConstraint alloc] initLinearConstraintWithExpression: valueExpression];
    } else {
        if (operator == CSWConstraintOperationGreaterThanOrEqual) {
            [valueExpression addVariable: rhs coefficient:-1.0];
        } else if (operator == CSWConstraintOperatorLessThanOrEqual) {
            [valueExpression multiplyConstantAndTermsBy:-1];
            [valueExpression addVariable:rhs coefficient:1.0];
        }
        
        return [[CSWInequalityConstraint alloc]  initLinearConstraintWithExpression:valueExpression];
    }
}

+(CSWConstraint*)constraintWithLeftExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWAbstractVariable*)rhs
{
    CSWLinearExpression *rhsExpression = [[CSWLinearExpression alloc] initWithVariable:rhs];
    return [self constraintWithLeftExpression:lhs operator:operator rightExpression:rhsExpression];
}

+(CSWConstraint*)constraintWithLeftExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rightExpression: (CSWLinearExpression*)rhs
{
    CSWLinearExpression *expression = [rhs copy];
    if (operator == CSWConstraintOperatorEqual) {
        [expression addExpression:lhs multiplier:-1];
        return [[CSWConstraint alloc] initLinearConstraintWithExpression:expression];
    } else {
        if (operator == CSWConstraintOperationGreaterThanOrEqual) {
            [expression multiplyConstantAndTermsBy:-1];
            [expression addExpression:lhs];
        } else if (operator == CSWConstraintOperatorLessThanOrEqual) {
            [expression addExpression:lhs multiplier:-1];
        }
        
        return [[CSWInequalityConstraint alloc] initLinearConstraintWithExpression:expression];
    }
}

+(CSWConstraint*)stayConstraintWithVariable: (CSWVariable*)variable strength: (CSWStrength*)strength
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:variable coefficient:-1 constant:variable.value];
       return [[CSWConstraint alloc] initWithType:CSWConstraintTypeStay strength:strength expression:expression variable:variable];
}

@end

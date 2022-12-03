#import "CSWConstraintFactory.h"

@implementation CSWConstraintFactory

+(CSWConstraint*)constraintWithLeftVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWAbstractVariable*)rhsVariable
{
    if (operator == CSWConstraintOperatorEqual) {
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:lhs];
        [expression addVariable:rhsVariable coefficient:-1];
        
        return [[CSWConstraint alloc] initLinearConstraintWithExpression:expression];
    } else {
        return [[CSWInequalityConstraint alloc] initWithLhsVariable:lhs operator:operator rhsVariable: rhsVariable];
    }
}

+(CSWConstraint*)constraintWithLeftVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rightExpression: (CSWLinearExpression*)rhs {
    if (operator == CSWConstraintOperatorEqual) {
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
        [expression addExpression:rhs multiplier:1];
        [expression addVariable:lhs coefficient:-1];

        return [[CSWConstraint alloc] initLinearConstraintWithExpression:expression strength:[CSWStrength strengthRequired] variable:nil];
    } else {
        return [[CSWInequalityConstraint alloc] initWithLhsVariable:lhs operator:operator rhsExpression: rhs];
    }
}

+(CSWConstraint*)constraintWithLeftVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rightConstant: (CSWDouble)rhs
{
    if (operator == CSWConstraintOperatorEqual) {
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
        [expression addVariable:lhs coefficient:1];
        [expression setConstant:-rhs];
        
        return [[CSWConstraint alloc] initLinearConstraintWithExpression:expression strength:[CSWStrength strengthRequired] variable:nil];
    } else {
        return [[CSWInequalityConstraint alloc] initWithLhsVariable:lhs operator:operator rhsConstant:rhs];
    }
}

+(CSWConstraint*)stayConstraintWithVariable: (CSWVariable*)variable strength: (CSWStrength*)strength weight: (CSWDouble)weight
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:variable coefficient:-1 constant:variable.value];
       return [[CSWConstraint alloc] initWithType:CSWConstraintTypeStay strength:strength expression:expression variable:variable];
}

@end

#import "CSWConstraint.h"
#import "CSWVariable.h"
#import "CSWConstraintFactory.h"

@implementation CSWConstraint

-(instancetype)init
{
    return [self initWithType:CSWConstraintTypeLinear strength:nil expression:nil variable:nil];
}

-(instancetype)initWithType: (CSWConstraintType)type
                strength: (CSWStrength*)strength
                expression: (CSWLinearExpression*)expression
                variable: (CSWVariable*)variable
{
    self = [super init];
     if (self) {
         self.strength = strength != nil ? [strength copy] : [CSWStrength strengthRequired];
         self.expression = expression;
         _type = type;
         self.variable = variable;
     }
     return self;
}

-(instancetype)initLinearConstraintWithExpression:(CSWLinearExpression *)expression
                                         strength: (CSWStrength*)strength
                                         variable: (nullable CSWVariable*)variable
{
    return [self initWithType:CSWConstraintTypeLinear strength:strength expression:expression variable:variable];
}

-(instancetype)initLinearConstraintWithExpression: (CSWLinearExpression*)expression
{
    return [self initLinearConstraintWithExpression:expression strength:[CSWStrength strengthRequired] variable:nil];

}

-(instancetype)initLinearInequityConstraintWithExpression: (CSWLinearExpression*)expression
{
    CSWConstraint *constraint = [self initLinearConstraintWithExpression:expression strength:[CSWStrength strengthRequired] variable:nil];
    _type = CSWConstraintTypeLinearInequity;
    return constraint;

}

-(instancetype)initEditConstraintWithVariable: (CSWVariable*)variable stength: (CSWStrength*)strength
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:variable coefficient:-1 constant:variable.value];
    return [self initWithType:CSWConstraintTypeEdit
                 strength:strength
                 expression:expression
                 variable:variable];
}

-(instancetype)initStayConstraintWithVariable: (CSWVariable*)variable strength: (CSWStrength*)strength
{
    return [CSWConstraintFactory stayConstraintWithVariable:variable strength:strength];
}

-(instancetype)initWithLhsVariable: (CSWVariable*)lhs equalsRhsVariable: (CSWVariable*)rhs
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:lhs];
    [expression addVariable:rhs coefficient:-1];
    return [self initLinearConstraintWithExpression:expression];
}

-(instancetype)initWithLhsVariable: (CSWVariable*)lhs equalsConstant: (CSWDouble)rhs
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:lhs coefficient:1 constant:-rhs];
    return [self initLinearConstraintWithExpression:expression];
}

+(CSWConstraint*)constraintWithLeftVariable: (CSWVariable*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWVariable*)rhsVariable
{
    return [CSWConstraintFactory constraintWithLeftVariable:lhs operator:operator rightVariable:rhsVariable];
}

+(CSWConstraint*)constraintWithLeftVariable: (CSWVariable*)lhs operator: (CSWConstraintOperator)operator rightConstant: (CSWDouble)rhs
{
    return [CSWConstraintFactory constraintWithLeftVariable:lhs operator:operator rightConstant:rhs];
}

+(CSWConstraint*)constraintWithLeftVariable: (CSWVariable*)lhs operator: (CSWConstraintOperator)operator rightExpression: (CSWLinearExpression*)rhs
{
    return [CSWConstraintFactory constraintWithLeftVariable:lhs operator:CSWConstraintOperatorEqual rightExpression:rhs];
}

+(CSWConstraint*)constraintWithLeftConstant: (CSWDouble)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWVariable*)rhs
{
    return [CSWConstraintFactory constraintWithLeftConstant:lhs operator:operator rightVariable:rhs];
}

+(CSWConstraint*)constraintWithLeftExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWVariable*)rhs
{
    return [CSWConstraintFactory constraintWithLeftExpression:lhs operator:operator rightVariable:rhs];
}

+(CSWConstraint*)constraintWithLeftExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rightExpression: (CSWLinearExpression*)rhs
{
    return [CSWConstraintFactory constraintWithLeftExpression:lhs operator:operator rightExpression:rhs];
}

+(instancetype)editConstraintWithVariable: (CSWVariable*)variable
{
    return [[self alloc] initEditConstraintWithVariable:variable stength:[CSWStrength strengthStrong]];
}

-(BOOL) isRequired
{
    return [self.strength isRequired];
}

-(BOOL) isEditConstraint
{
    return self.type == CSWConstraintTypeEdit;
}

-(BOOL) isStayConstraint
{
    return self.type == CSWConstraintTypeStay;
}

-(BOOL) isInequality
{
    return self.type == CSWConstraintTypeLinearInequity;
}

@end

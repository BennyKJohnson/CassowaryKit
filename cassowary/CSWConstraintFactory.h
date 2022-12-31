#import <Foundation/Foundation.h>
#import "CSWConstraint.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWConstraintFactory : NSObject

+(CSWConstraint*)constraintWithLeftVariable: (CSWVariable*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWVariable*)rhsVariable;

+(CSWConstraint*)constraintWithLeftVariable: (CSWVariable*)lhs operator: (CSWConstraintOperator)operator rightConstant: (CSWDouble)rhs;

+(CSWConstraint*)constraintWithLeftVariable:(CSWVariable *)lhs operator:(CSWConstraintOperator)operator rightExpression:(CSWLinearExpression*)rhs;

+(CSWConstraint*)constraintWithLeftConstant: (CSWDouble)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWVariable*)rhs;

+(CSWConstraint*)constraintWithLeftExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWVariable*)rhs;

+(CSWConstraint*)constraintWithLeftExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rightExpression: (CSWLinearExpression*)rhs;

+(CSWConstraint*)constraintWithLeftExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rightConstant:(CSWDouble)rhs;

+(CSWConstraint*)stayConstraintWithVariable: (CSWVariable*)variable strength: (CSWStrength*)strength;

@end

NS_ASSUME_NONNULL_END

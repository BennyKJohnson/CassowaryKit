#import <Foundation/Foundation.h>
#import "CSWInequalityConstraint.h"
#import "CSWConstraint.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWConstraintFactory : NSObject

+(CSWConstraint*)constraintWithLeftVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWAbstractVariable*)rhsVariable;

+(CSWConstraint*)constraintWithLeftVariable: (CSWAbstractVariable*)lhs operator: (CSWConstraintOperator)operator rightConstant: (CSWDouble)rhs;

+(CSWConstraint*)constraintWithLeftVariable:(CSWAbstractVariable *)lhs operator:(CSWConstraintOperator)operator rightExpression:(CSWLinearExpression*)rhs;

+(CSWConstraint*)stayConstraintWithVariable: (CSWVariable*)variable strength: (CSWStrength*)strength weight: (CSWDouble)weight;

@end

NS_ASSUME_NONNULL_END

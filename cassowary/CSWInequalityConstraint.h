//
//  CSWInequalityConstraint.h
//  cassowary
//
//  Created by Benjamin Johnson on 19/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import "CSWConstraint.h"
#import "CSWConstraintOperator.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWInequalityConstraint : CSWConstraint

-(instancetype)initWithLhsVariable: (CSWAbstractVariable*)variable operator: (CSWConstraintOperator)operator rhsConstant:(CSWDouble)rhsValue;

-(instancetype)initWithLhsConstant: (CSWDouble)lhs operator:(CSWConstraintOperator)operator rhsVariable:(CSWAbstractVariable*)rhsValue;

-(instancetype)initWithLhsVariable: (CSWAbstractVariable*)variable operator: (CSWConstraintOperator)operator rhsVariable: (CSWAbstractVariable*)variable;

-(instancetype)initWithLhsVariable: (CSWAbstractVariable*)variable operator: (CSWConstraintOperator)operator rhsExpression: (CSWLinearExpression*)rhs;

-(instancetype)initWithLhsExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rhsVariable: (CSWAbstractVariable*)rhs;

-(instancetype)initWithLhsExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rhsExpression: (CSWLinearExpression*)rhs;

-(BOOL)isInequality;

@end

NS_ASSUME_NONNULL_END

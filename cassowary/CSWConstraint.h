#import <Foundation/Foundation.h>
#import "CSWStrength.h"
#import "CSWLinearExpression.h"
#import "CSWVariable.h"
#import "CSWConstraintOperator.h"

@class CSWConstraintFactory;

 enum CSWConstraintType {
    CSWConstraintTypeEdit,
    CSWConstraintTypeStay,
    CSWConstraintTypeLinear
};
typedef enum CSWConstraintType CSWConstraintType;

NS_ASSUME_NONNULL_BEGIN

@interface CSWConstraint : NSObject

-(instancetype)initLinearConstraintWithExpression: (CSWLinearExpression*)expression;

-(instancetype)initWithType: (CSWConstraintType)type
    strength: (CSWStrength* _Nullable)strength
    expression: (CSWLinearExpression* _Nullable)expression
                   variable: (CSWVariable* _Nullable)variable;

-(instancetype)initLinearConstraintWithExpression:(CSWLinearExpression *)expression strength: (CSWStrength*)strength variable: (nullable CSWVariable*)variable;

-(instancetype)initEditConstraintWithVariable: (CSWVariable*)variable stength: (CSWStrength*)strength;

-(instancetype)initStayConstraintWithVariable: (CSWVariable*)variable strength: (CSWStrength*)strength;

-(instancetype)initWithLhsVariable: (CSWVariable*)lhs equalsConstant: (CSWDouble)rhs;

-(instancetype)initWithLhsVariable: (CSWVariable*)lhs equalsRhsVariable: (CSWVariable*)rhs;

+(CSWConstraint*)constraintWithLeftVariable: (CSWVariable*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWVariable*)rhsVariable;

+(CSWConstraint*)constraintWithLeftVariable: (CSWVariable*)lhs operator: (CSWConstraintOperator)operator rightConstant: (CSWDouble)rhs;

+(CSWConstraint*)constraintWithLeftVariable: (CSWVariable*)lhs operator: (CSWConstraintOperator)operator rightExpression: (CSWLinearExpression*)rhs;

+(CSWConstraint*)constraintWithLeftConstant: (CSWDouble)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWVariable*)rhs;

+(CSWConstraint*)constraintWithLeftExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rightVariable: (CSWVariable*)rhs;

+(CSWConstraint*)constraintWithLeftExpression: (CSWLinearExpression*)lhs operator: (CSWConstraintOperator)operator rightExpression: (CSWLinearExpression*)rhs;

+(instancetype)editConstraintWithVariable: (CSWVariable*)variable;

@property (readonly) CSWConstraintType type;

@property (nonatomic, strong) CSWStrength* strength;

@property (nonatomic, strong) CSWLinearExpression *expression;

@property (nonatomic, strong) CSWVariable *variable;

-(CSWLinearExpression*) expression;

-(BOOL) isRequired;

-(BOOL) isEditConstraint;

-(BOOL) isStayConstraint;

-(BOOL) isInequality;


@end

NS_ASSUME_NONNULL_END

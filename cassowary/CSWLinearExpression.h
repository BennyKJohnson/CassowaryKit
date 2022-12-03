#import <Foundation/Foundation.h>
#import "CSWAbstractVariable.h"

typedef CGFloat CSWDouble;

NS_ASSUME_NONNULL_BEGIN

@interface CSWLinearExpression : NSObject <NSCopying>

@property (nonatomic, strong) NSMapTable *terms;

@property (nonatomic) CGFloat constant;

@property (nonatomic, strong) NSMutableArray *termVariables;

-(instancetype)initWithConstant: (CSWDouble)constant;

-(instancetype)initWithVariable: (CSWAbstractVariable*)variable;

-(instancetype)initWithVariable: (CSWAbstractVariable*)variable coefficient: (CSWDouble)value constant: (CSWDouble)constant;

-(instancetype)initWithVariables: (NSArray*)variables;

-(NSNumber*)multiplierForTerm: (CSWAbstractVariable*)variable;

-(void)removeVariable: (nonnull CSWAbstractVariable*)variable;

-(void)multiplyConstantAndTermsBy: (CSWDouble)value;

-(void)divideConstantAndTermsBy: (CSWDouble)value;

-(CSWDouble)coefficientForTerm: (CSWAbstractVariable*)variable;

-(CSWDouble)newSubject:(CSWAbstractVariable*)subject;

-(void)addVariable: (CSWAbstractVariable*)variable;

-(void)addVariable: (CSWAbstractVariable*)variable coefficient: (CSWDouble)coefficient;

-(void)addExpression: (CSWLinearExpression*)expression;

-(void)addExpression: (CSWLinearExpression*)expression multiplier: (CSWDouble)multiplier;

-(CSWAbstractVariable*)findPivotableVariableWithMostNegativeCoefficient;

-(void)normalize;

-(NSArray*)termKeys;

-(BOOL)isConstant;

-(BOOL)isTermForVariable: (CSWAbstractVariable*)variable;

-(CSWAbstractVariable*)anyPivotableVariable;

-(NSArray*)externalVariables;

-(BOOL)containsOnlyDummyVariables;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>
#import "CSWVariable.h"

typedef CGFloat CSWDouble;

NS_ASSUME_NONNULL_BEGIN

@interface CSWLinearExpression : NSObject <NSCopying>

@property (nonatomic, strong) NSMapTable *terms;

@property (nonatomic) CGFloat constant;

@property (nonatomic, strong) NSMutableArray *termVariables;

-(instancetype)initWithConstant: (CSWDouble)constant;

-(instancetype)initWithVariable: (CSWVariable*)variable;

-(instancetype)initWithVariable: (CSWVariable*)variable coefficient: (CSWDouble)value constant: (CSWDouble)constant;

-(instancetype)initWithVariables: (NSArray*)variables;

-(NSNumber*)multiplierForTerm: (CSWVariable*)variable;

-(void)removeVariable: (nonnull CSWVariable*)variable;

-(void)multiplyConstantAndTermsBy: (CSWDouble)value;

-(void)divideConstantAndTermsBy: (CSWDouble)value;

-(CSWDouble)coefficientForTerm: (CSWVariable*)variable;

-(CSWDouble)newSubject:(CSWVariable*)subject;

-(void)addVariable: (CSWVariable*)variable;

-(void)addVariable: (CSWVariable*)variable coefficient: (CSWDouble)coefficient;

-(void)addExpression: (CSWLinearExpression*)expression;

-(void)addExpression: (CSWLinearExpression*)expression multiplier: (CSWDouble)multiplier;

-(CSWVariable*)findPivotableVariableWithMostNegativeCoefficient;

-(void)normalize;

-(NSArray*)termKeys;

-(BOOL)isConstant;

-(BOOL)isTermForVariable: (CSWVariable*)variable;

-(CSWVariable*)anyPivotableVariable;

-(NSArray*)externalVariables;

-(BOOL)containsOnlyDummyVariables;

@end

NS_ASSUME_NONNULL_END

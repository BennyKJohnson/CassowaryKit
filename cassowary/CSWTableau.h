#import <Foundation/Foundation.h>
#import "CSWAbstractVariable.h"
#import "CSWLinearExpression.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWTableau : NSObject
{
    NSMutableSet *_externalParametricVariables;
    
    NSMapTable *_externalRows;
    
    NSMutableArray *_infeasibleRows;
    
    NSMutableSet *_updatedExternals;
}

@property (nonatomic, strong) NSMapTable *columns;

@property (nonatomic, strong) NSMapTable *rows;

-(void) addRowForVariable: (CSWAbstractVariable*)variable equalsExpression:(CSWLinearExpression*)expression;

-(void) removeRowForVariable: (CSWAbstractVariable*)variable;

-(BOOL) hasRowForVariable: (CSWAbstractVariable*)variable;

-(void) substituteOutVariable: (CSWAbstractVariable*)variable forExpression:(CSWLinearExpression*)expression;

-(void) substituteOutTerm: (CSWAbstractVariable*)term withExpression:(CSWLinearExpression*)newExpression inExpression: (CSWLinearExpression*)expression subject: (CSWAbstractVariable*)subject;

-(BOOL) isBasicVariable: (CSWAbstractVariable*)variable;

-(void)addVariable: (CSWAbstractVariable*)variable toExpression: (CSWLinearExpression*)expression;

-(void)addVariable: (CSWAbstractVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient;

-(void)addVariable: (CSWAbstractVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient subject: (CSWAbstractVariable* _Nullable)subject;

-(void)setVariable: (CSWAbstractVariable*)variable onExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient;

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression n: (CSWDouble)n subject: (nullable CSWAbstractVariable*)subject;

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression;

-(void)addMappingFromExpressionVariable: (CSWAbstractVariable*)columnVariable toRowVariable: (CSWAbstractVariable*)rowVariable;

-(void)removeColumn: (CSWAbstractVariable*)variable;

-(CSWLinearExpression*)rowExpressionForVariable: (CSWAbstractVariable*)variable;

-(void)changeSubjectOnExpression: (CSWLinearExpression*)expression existingSubject:(CSWAbstractVariable*)existingSubject newSubject: (CSWAbstractVariable*)newSubject;

@end

NS_ASSUME_NONNULL_END

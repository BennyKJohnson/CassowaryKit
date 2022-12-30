#import <Foundation/Foundation.h>
#import "CSWVariable.h"
#import "CSWLinearExpression.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWTableau : NSObject
{
    NSMutableSet *_externalParametricVariables;
    
    NSMapTable *_externalRows;
    
    NSMutableArray *_infeasibleRows;
    
}

@property (nonatomic, strong) NSMutableSet *updatedExternals;

@property (nonatomic, strong) NSMapTable *columns;

@property (nonatomic, strong) NSMapTable *rows;

-(void) addRowForVariable: (CSWVariable*)variable equalsExpression:(CSWLinearExpression*)expression;

-(void) removeRowForVariable: (CSWVariable*)variable;

-(BOOL) hasRowForVariable: (CSWVariable*)variable;

-(void) substituteOutVariable: (CSWVariable*)variable forExpression:(CSWLinearExpression*)expression;

-(void) substituteOutTerm: (CSWVariable*)term withExpression:(CSWLinearExpression*)newExpression inExpression: (CSWLinearExpression*)expression subject: (CSWVariable*)subject;

-(BOOL) isBasicVariable: (CSWVariable*)variable;

-(void)addVariable: (CSWVariable*)variable toExpression: (CSWLinearExpression*)expression;

-(void)addVariable: (CSWVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient;

-(void)addVariable: (CSWVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient subject: (CSWVariable* _Nullable)subject;

-(void)setVariable: (CSWVariable*)variable onExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient;

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression n: (CSWDouble)n subject: (nullable CSWVariable*)subject;

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression;

-(void)addMappingFromExpressionVariable: (CSWVariable*)columnVariable toRowVariable: (CSWVariable*)rowVariable;

-(void)removeColumn: (CSWVariable*)variable;

-(CSWLinearExpression*)rowExpressionForVariable: (CSWVariable*)variable;

-(void)changeSubjectOnExpression: (CSWLinearExpression*)expression existingSubject:(CSWVariable*)existingSubject newSubject: (CSWVariable*)newSubject;

@end

NS_ASSUME_NONNULL_END

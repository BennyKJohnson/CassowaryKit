#import "CSWTableau.h"
#import "CSWFloatComparator.h"

@implementation CSWTableau

-(instancetype)init
{
    if (self = [super init]) {
        rows = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                          valueOptions:NSMapTableStrongMemory];
        columns = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
        valueOptions:NSMapTableStrongMemory];
        externalParametricVariables = [NSMutableSet set];
        self.externalRows = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
        valueOptions:NSMapTableStrongMemory];
        self.infeasibleRows = [NSMutableArray array];
        self.updatedExternals = [NSMutableSet set];
    }
    return self;
}

// Add v=expr to the tableau, update column cross indices
// v becomes a basic variable
// expr is now owned by ClTableau class,
// and ClTableauis responsible for deleting it
-(void)addRowForVariable: (CSWVariable*)variable equalsExpression: (CSWLinearExpression*)expression
{
    [rows setObject:expression forKey: variable];
    if (variable.isExternal) {
        [self.externalRows setObject:expression forKey:variable];
    }
    [self addTermVariablesForExpression:expression variable:variable];
}

-(void)addTermVariablesForExpression: (CSWLinearExpression*)expression variable: (CSWVariable*)variable {
    for (CSWVariable *expressionTermVariable in expression.termVariables) {
         [self addMappingFromExpressionVariable:expressionTermVariable toRowVariable:variable];
         if ([expressionTermVariable isExternal]) {
             [externalParametricVariables addObject:expressionTermVariable];
         }
     }
}

-(void)addMappingFromExpressionVariable: (CSWVariable*)columnVariable toRowVariable: (CSWVariable*)rowVariable
{
    NSMutableSet *columnSet = [columns objectForKey:columnVariable];
    if (columnSet == nil) {
        columnSet = [NSMutableSet set];
        [columns setObject:columnSet forKey:columnVariable];
    }
    [columnSet addObject:rowVariable];
}

-(void)removeMappingFromExpressionVariable: (CSWVariable*)columnVariable toRowVariable: (CSWVariable*)rowVariable
{
    NSMutableSet *columnSet = [columns objectForKey:columnVariable];
    if (columnSet == nil) {
        return;
    }
    [columnSet removeObject:rowVariable];
}

-(void)removeColumn: (CSWVariable*)variable
{
    NSSet *crows = [ columns objectForKey:variable];
    if (rows != nil) {
        for (id clv in crows) {
            CSWLinearExpression *expression = [rows objectForKey:clv];
            [expression removeVariable:variable];
        }
        [columns removeObjectForKey:variable];
    }
    
    if ([variable isExternal]) {
        [self.externalRows removeObjectForKey:variable];
    }
}

-(void)removeRowForVariable: (CSWVariable*)variable
{
    CSWLinearExpression *expression = [rows objectForKey:variable];
    if (expression == nil) {
        NSException *missingExpressionException = [NSException exceptionWithName:NSInvalidArgumentException reason:@"No expression exists for the provided variable" userInfo:nil];
        [missingExpressionException raise];
        return;
    }
    [rows removeObjectForKey:variable];
    if (variable.isExternal) {
        [self.externalRows removeObjectForKey:variable];
    }
    
    for (CSWVariable *expressionTermVariable in expression.termVariables) {
        [self removeMappingFromExpressionVariable:expressionTermVariable toRowVariable:variable];
          if ([expressionTermVariable isExternal]) {
              [externalParametricVariables addObject:expressionTermVariable];
          }
      }
}

-(BOOL)hasRowForVariable: (CSWVariable*)variable
{
    return [rows objectForKey:variable] != nil;
}

-(void)substituteOutVariable: (CSWVariable*)variable forExpression:(CSWLinearExpression*)expression
{
    NSSet *variableSet = [[columns objectForKey:variable] copy];
    
    for (CSWVariable *columnVariable in variableSet) {
        CSWLinearExpression *row = [rows objectForKey:columnVariable];
        [self substituteOutTerm:variable withExpression:expression inExpression:row subject:columnVariable];
        if ([columnVariable isRestricted] && row.constant < 0.0) {
            [self.infeasibleRows addObject: columnVariable];
        }
    }

    if ([variable isExternal]) {
        [self.externalRows setObject:expression forKey:variable];
        [externalParametricVariables removeObject:variable];
    }
    [columns removeObjectForKey:variable];
}

-(void)substituteOutTerm: (CSWVariable*)term withExpression:(CSWLinearExpression*)newExpression inExpression: (CSWLinearExpression*)expression subject: (CSWVariable*)subject
{
    CSWDouble coefficieint = [expression coefficientForTerm:term];
    [expression removeVariable: term];
    expression.constant = (coefficieint * newExpression.constant) + expression.constant;
    
    for (CSWVariable *newExpressionTerm in newExpression.termVariables) {
        [self substituteOutTermInExpression:expression newExpression:newExpression subject:subject term:newExpressionTerm multiplier:coefficieint];
    }
}

- (void)substituteOutTermInExpression:(CSWLinearExpression * _Nonnull)expression newExpression:(CSWLinearExpression * _Nonnull)newExpression subject:(CSWVariable * _Nonnull)subject term:(CSWVariable *)term multiplier: (CSWDouble)multiplier {
    NSNumber *coefficentInNewExpression = [newExpression multiplierForTerm:term];
    NSNumber *coefficentInExistingExpression = [expression multiplierForTerm:term];
    
    if (coefficentInExistingExpression != nil) {
        CGFloat newCoefficent = [self calculateNewCoefficent:[coefficentInExistingExpression floatValue] coefficentInNewExpression:[coefficentInNewExpression floatValue] multiplier:multiplier];
        
        if ([CSWFloatComparator isApproxiatelyZero:newCoefficent]) {
            [expression removeVariable:term];
            [self removeMappingFromExpressionVariable:term toRowVariable:subject];
        } else {
            [expression addVariable:term coefficient:newCoefficent];
        }
    } else {
        CGFloat updatedCoefficent = multiplier * [coefficentInNewExpression floatValue];
        [expression addVariable:term coefficient:updatedCoefficent];
        [self addMappingFromExpressionVariable:term toRowVariable:subject];
    }
}

- (CGFloat)calculateNewCoefficent:(CGFloat)coefficentInExistingExpression coefficentInNewExpression:(CGFloat)coefficentInNewExpression multiplier:(CGFloat )multiplier {
    CGFloat newCoefficent = coefficentInExistingExpression + multiplier * coefficentInNewExpression;
    return newCoefficent;
}

-(BOOL) isBasicVariable: (CSWVariable*)variable
{
    return [rows objectForKey:variable] != nil;
}

-(void)addVariable: (CSWVariable*)variable toExpression: (CSWLinearExpression*)expression
{
    [self addVariable:variable toExpression:expression withCoefficient: 1.0 subject: nil];
}

-(void)addVariable: (CSWVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient;
{
    [self addVariable:variable toExpression:expression withCoefficient:coefficient subject:nil];
}

-(void)addVariable: (CSWVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient subject: (CSWVariable*)subject
{
    if ([expression isTermForVariable:variable]) {
        CSWDouble newCoefficient = [expression coefficientForTerm:variable] + coefficient;
        if (newCoefficient == 0 || [CSWFloatComparator isApproxiatelyZero:newCoefficient]) {
            [expression removeVariable:variable];
            [self removeColumnVariable:variable subject:subject];
        } else {
            [self setVariable:variable onExpression:expression withCoefficient:newCoefficient];
        }
    } else {
        if (![CSWFloatComparator isApproxiatelyZero:coefficient]) {
            [self setVariable:variable onExpression:expression withCoefficient:coefficient];
            if (subject) {
                [self addMappingFromExpressionVariable:variable toRowVariable:subject];
            }
        }
    }
}

-(void)removeColumnVariable: (CSWVariable*)variable subject: (CSWVariable*)subject
{
    NSMutableSet *column = [columns objectForKey:variable];
    if (subject != nil && column != nil) {
        [column removeObject:subject];
    }
}

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression
{
    [self addNewExpression:newExpression toExpression:existingExpression n:1 subject:nil];
}

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression n: (CSWDouble)n subject: (nullable CSWVariable*)subject
{
    [existingExpression setConstant:existingExpression.constant + (n * newExpression.constant)];
    
    for (CSWVariable *term in [newExpression termKeys]) {
        CSWDouble newCoefficient = [newExpression coefficientForTerm:term] * n;
        [self addVariable:term toExpression:existingExpression withCoefficient:newCoefficient subject:subject];
        
        [self recordUpdatedVariable:term];
    }
}

-(void)recordUpdatedVariable: (CSWVariable*)variable
{
    if ([variable isExternal]) {
        [externalParametricVariables addObject:variable];
        [_updatedExternals addObject:variable];
    }
}

-(void)setVariable: (CSWVariable*)variable onExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient
{
    [expression addVariable:variable coefficient:coefficient];
    [self recordUpdatedVariable:variable];
}

-(void)changeSubjectOnExpression: (CSWLinearExpression*)expression existingSubject:(CSWVariable*)existingSubject newSubject: (CSWVariable*)newSubject
{
    [self setVariable:existingSubject onExpression:expression withCoefficient: [expression newSubject:newSubject]];
}

-(CSWLinearExpression*)rowExpressionForVariable: (CSWVariable*)variable
{
    return [rows objectForKey:variable];
}

-(void)pivotWithEntryVariable: (CSWVariable*)entryVariable exitVariable: (CSWVariable*)exitVariable
{
    // expr is the Expression for the exit variable (about to leave the basis) --
    // so that the old tableau includes the equation:
    //   exitVar = expr
    CSWLinearExpression *expression = [self rowExpressionForVariable:exitVariable];
    [self removeRowForVariable:exitVariable];
    
    // Compute an Expression for the entry variable.  Since expr has
    // been deleted from the tableau we can destructively modify it to
    // build this Expression.
    [self changeSubjectOnExpression:expression existingSubject:exitVariable newSubject:entryVariable];
    [self substituteOutVariable:entryVariable forExpression:expression];
    
    if ([entryVariable isExternal]) {
        [externalParametricVariables removeObject:entryVariable];
    }
    
    [self addRowForVariable:entryVariable equalsExpression:expression];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithString:@"Tableau Information\n"];
    [description appendFormat:@"Rows: %ld (%ld constraints)\n", rows.count, rows.count - 1];
    [description appendFormat:@"Columns: %ld\n", columns.count];
    [description appendFormat:@"Infesible rows: %ld\n", self.infeasibleRows.count];
    [description appendFormat:@"External basic variables: %ld\n", self.externalRows.count];
    [description appendFormat:@"External parametric variables: %ld\n\n", externalParametricVariables.count];
    
    [description appendFormat:@"Columns: \n"];
    [description appendString:[self columnsDescription]];
    
    [description appendFormat:@"\nRows:\n"];
    [description appendString:[self rowsDescription]];
    
    return description; 
}

-(NSString *)columnsDescription
{
    NSMutableString *description = [NSMutableString string];
    for (CSWVariable *columnVariable in columns) {
        [description appendFormat:@"%@ : %@", columnVariable, [columns objectForKey:columnVariable]];
    }
    
    return description;
}

-(NSString*)rowsDescription
{
    NSMutableString *description = [NSMutableString string];
    for (CSWVariable *variable in rows) {
        [description appendFormat:@"%@ : %@\n", variable, [rows objectForKey:variable]];
    }
    return description;
}

-(BOOL)hasInfeasibleRows
{
    return [self.infeasibleRows count] > 0;
}

- (BOOL)containsExternalParametricVariableForEveryExternalTerm {
    for (CSWVariable *rowVariable in rows) {
        CSWLinearExpression *expression = [rows objectForKey:rowVariable];
        for (CSWVariable *variable in [expression termVariables]) {
            if ([variable isExternal]) {
                if (![externalParametricVariables containsObject:variable]) {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

- (BOOL)containsExternalRowForEachExternalRowVariable {
    for (CSWVariable *rowVariable in rows) {
        if ([rowVariable isExternal]) {
            if ([self.externalRows objectForKey:rowVariable] == nil) {
                return NO;
            }
        }
    }
    
    return YES;
}

-(BOOL)hasSubstitedOutNonBasicPivotableVariable: (CSWVariable*)objective
{
    CSWLinearExpression *objectiveRowExpression = [self rowExpressionForVariable: objective];
    for (CSWVariable *columnVariable in columns) {
        if (columnVariable.isPivotable && ![self isBasicVariable:columnVariable] && [objectiveRowExpression.terms objectForKey:columnVariable] == nil) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)hasColumnForVariable: (CSWVariable*)variable
{
    return [columns objectForKey:variable] != nil;
}

-(NSSet*)columnForVariable: (CSWVariable*)variable
{
    return [columns objectForKey:variable];
}

@end

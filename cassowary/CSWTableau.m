#import "CSWTableau.h"
#import "CSWFloatComparator.h"

@implementation CSWTableau

-(instancetype)init
{
    if (self = [super init]) {
        self.rows = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                          valueOptions:NSMapTableStrongMemory];
        self.columns = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
        valueOptions:NSMapTableStrongMemory];
        _externalParametricVariables = [NSMutableSet set];
        _externalRows = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
        valueOptions:NSMapTableStrongMemory];
        _infeasibleRows = [NSMutableArray array];
        _updatedExternals = [NSMutableSet set];
    }
    return self;
}

// Add v=expr to the tableau, update column cross indices
// v becomes a basic variable
// expr is now owned by ClTableau class,
// and ClTableauis responsible for deleting it
-(void)addRowForVariable: (CSWAbstractVariable*)variable equalsExpression: (CSWLinearExpression*)expression
{
    [self.rows setObject:expression forKey: variable];
    if (variable.isExternal) {
        [_externalRows setObject:expression forKey:variable];
    }
    [self addTermVariablesForExpression:expression variable:variable];
}

-(void)addTermVariablesForExpression: (CSWLinearExpression*)expression variable: (CSWAbstractVariable*)variable {
    for (CSWAbstractVariable *expressionTermVariable in expression.termVariables) {
         [self addMappingFromExpressionVariable:expressionTermVariable toRowVariable:variable];
         if ([expressionTermVariable isExternal]) {
             [_externalParametricVariables addObject:expressionTermVariable];
         }
     }
}

-(void)addMappingFromExpressionVariable: (CSWAbstractVariable*)columnVariable toRowVariable: (CSWAbstractVariable*)rowVariable
{
    NSMutableSet *columnSet = [self.columns objectForKey:columnVariable];
    if (columnSet == nil) {
        columnSet = [NSMutableSet set];
        [self.columns setObject:columnSet forKey:columnVariable];
    }
    [columnSet addObject:rowVariable];
}

-(void)removeMappingFromExpressionVariable: (CSWAbstractVariable*)columnVariable toRowVariable: (CSWAbstractVariable*)rowVariable
{
    NSMutableSet *columnSet = [self.columns objectForKey:columnVariable];
    if (columnSet == nil) {
        return;
    }
    [columnSet removeObject:rowVariable];
}

-(void)removeColumn: (CSWAbstractVariable*)variable
{
    NSSet *rows = [ self.columns objectForKey:variable];
    if (rows != nil) {
        for (id clv in rows) {
            CSWLinearExpression *expression = [self.rows objectForKey:clv];
            [expression removeVariable:variable];
        }
        [self.columns removeObjectForKey:variable];
    }
    
    if ([variable isExternal]) {
        [_externalRows removeObjectForKey:variable];
    }
}

-(void)removeRowForVariable: (CSWAbstractVariable*)variable
{
    CSWLinearExpression *expression = [self.rows objectForKey:variable];
    if (expression == nil) {
        NSException *missingExpressionException = [NSException exceptionWithName:NSInvalidArgumentException reason:@"No expression exists for the provided variable" userInfo:nil];
        [missingExpressionException raise];
        return;
    }
    [self.rows removeObjectForKey:variable];
    if (variable.isExternal) {
        [_externalRows removeObjectForKey:variable];
    }
    
    for (CSWAbstractVariable *expressionTermVariable in expression.termVariables) {
        [self removeMappingFromExpressionVariable:expressionTermVariable toRowVariable:variable];
          if ([expressionTermVariable isExternal]) {
              [_externalParametricVariables addObject:expressionTermVariable];
          }
      }
}

-(BOOL)hasRowForVariable: (CSWAbstractVariable*)variable
{
    return [self.rows objectForKey:variable] != nil;
}

-(void)substituteOutVariable: (CSWAbstractVariable*)variable forExpression:(CSWLinearExpression*)expression
{
    NSSet *variableSet = [[self.columns objectForKey:variable] copy];
    
    for (CSWAbstractVariable *columnVariable in variableSet) {
        CSWLinearExpression *row = [self.rows objectForKey:columnVariable];
        [self substituteOutTerm:variable withExpression:expression inExpression:row subject:columnVariable];
        if ([columnVariable isRestricted] && row.constant < 0.0) {
            [_infeasibleRows addObject: columnVariable];
        }
    }

    if ([variable isExternal]) {
        [_externalRows setObject:expression forKey:variable];
        [_externalParametricVariables removeObject:variable];
    }
    [self.columns removeObjectForKey:variable];
}

-(void)substituteOutTerm: (CSWAbstractVariable*)term withExpression:(CSWLinearExpression*)newExpression inExpression: (CSWLinearExpression*)expression subject: (CSWAbstractVariable*)subject
{
    CSWDouble coefficieint = [expression coefficientForTerm:term];
    [expression removeVariable: term];
    expression.constant = (coefficieint * newExpression.constant) + expression.constant;
    
    for (CSWAbstractVariable *newExpressionTerm in newExpression.termVariables) {
        [self substituteOutTermInExpression:expression newExpression:newExpression subject:subject term:newExpressionTerm multiplier:coefficieint];
    }
}

- (void)substituteOutTermInExpression:(CSWLinearExpression * _Nonnull)expression newExpression:(CSWLinearExpression * _Nonnull)newExpression subject:(CSWAbstractVariable * _Nonnull)subject term:(CSWAbstractVariable *)term multiplier: (CSWDouble)multiplier {
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

-(BOOL) isBasicVariable: (CSWAbstractVariable*)variable
{
    return [self.rows objectForKey:variable] != nil;
}

-(void)addVariable: (CSWAbstractVariable*)variable toExpression: (CSWLinearExpression*)expression
{
    [self addVariable:variable toExpression:expression withCoefficient: 1.0 subject: nil];
}

-(void)addVariable: (CSWAbstractVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient;
{
    [self addVariable:variable toExpression:expression withCoefficient:coefficient subject:nil];
}

-(void)addVariable: (CSWAbstractVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient subject: (CSWAbstractVariable*)subject
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

-(void)removeColumnVariable: (CSWAbstractVariable*)variable subject: (CSWAbstractVariable*)subject
{
    NSMutableSet *column = [self.columns objectForKey:variable];
    if (subject != nil && column != nil) {
        [column removeObject:subject];
    }
}

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression
{
    [self addNewExpression:newExpression toExpression:existingExpression n:1 subject:nil];
}

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression n: (CSWDouble)n subject: (nullable CSWAbstractVariable*)subject
{
    [existingExpression setConstant:existingExpression.constant + (n * newExpression.constant)];
    
    for (CSWAbstractVariable *term in [newExpression termKeys]) {
        CSWDouble newCoefficient = [newExpression coefficientForTerm:term] * n;
        [self addVariable:term toExpression:existingExpression withCoefficient:newCoefficient subject:subject];
        
        [self recordUpdatedVariable:term];
    }
}

-(void)recordUpdatedVariable: (CSWAbstractVariable*)variable
{
    if ([variable isExternal]) {
        [_externalParametricVariables addObject:variable];
        [_updatedExternals addObject:variable];
    }
}

-(void)setVariable: (CSWAbstractVariable*)variable onExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient
{
    [expression addVariable:variable coefficient:coefficient];
    [self recordUpdatedVariable:variable];
}

-(void)changeSubjectOnExpression: (CSWLinearExpression*)expression existingSubject:(CSWAbstractVariable*)existingSubject newSubject: (CSWAbstractVariable*)newSubject
{
    [self setVariable:existingSubject onExpression:expression withCoefficient: [expression newSubject:newSubject]];
}

-(CSWLinearExpression*)rowExpressionForVariable: (CSWAbstractVariable*)variable
{
    return [self.rows objectForKey:variable];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithString:@"Tableau Information\n"];
    [description appendFormat:@"Rows: %ld (%ld constraints)\n", _rows.count, _rows.count - 1];
    [description appendFormat:@"Columns: %ld\n", _columns.count];
    [description appendFormat:@"Infesible rows: %ld\n", _infeasibleRows.count];
    [description appendFormat:@"External basic variables: %ld\n", _externalRows.count];
    [description appendFormat:@"External parametric variables: %ld\n\n", _externalParametricVariables.count];
    
    [description appendFormat:@"Columns: \n"];
    [description appendString:[self columnsDescription]];
    
    [description appendFormat:@"\nRows:\n"];
    [description appendString:[self rowsDescription]];
    
    return description; 
}

-(NSString *)columnsDescription
{
    NSMutableString *description = [NSMutableString string];
    for (CSWAbstractVariable *columnVariable in self.columns) {
        [description appendFormat:@"%@ : %@", columnVariable, [_columns objectForKey:columnVariable]];
    }
    
    return description;
}

-(NSString*)rowsDescription
{
    NSMutableString *description = [NSMutableString string];
    for (CSWAbstractVariable *variable in _rows) {
        [description appendFormat:@"%@ : %@\n", variable, [_rows objectForKey:variable]];
    }
    return description;
}

@end
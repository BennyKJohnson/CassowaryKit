#import "CSWSimplexSolver.h"
#import "CSWFloatComparator.h"
#import "CSWVariable.h"
#import "CSWEditInfo.h"
#import "CSWVariable+PrivateMethods.h"

NSString * const CSWErrorDomain = @"com.cassowary";

@implementation CSWSimplexSolver

- (instancetype)init
{
    self = [super init];
    if (self) {
        _stayMinusErrorVariables = [NSMutableArray array];
        _stayPlusErrorVariables = [NSMutableArray array];
  
        _markerVariables = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
        valueOptions:NSMapTableStrongMemory];
        _errorVariables = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
        valueOptions:NSMapTableStrongMemory];
        
        _slackCounter = 0;
        _artificialCounter = 0;
        _dummyCounter = 0;
        _variableCounter = 0;

        _objective = [CSWVariable objectiveVariableWithName:@"Z"];
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
        [self.rows setObject: expression forKey:_objective];
        
        self.editVariableManager = [[CSWEditVariableManager alloc] init];

        _needsSolving = NO;
    }
    
    return self;
}

-(void)addConstraints: (NSArray*)constraints
{
    for (CSWConstraint *constraint in constraints) {
        [self _addConstraint:constraint];
    }
    if (self.autoSolve) {
        [self solve];
    }
}

-(void)addConstraint:(CSWConstraint *)constraint
{
    [self _addConstraint:constraint];
    if (self.autoSolve) {
        [self solve];
    }
}

-(void)_addConstraint: (CSWConstraint*)constraint
{
    if ([constraint isEditConstraint] && ![[constraint variable] isExternal]) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot have an edit variable with a non external variable" userInfo:nil] raise];
    }
    
    if ([constraint isKindOfClass:[CSWConstraint class]]) {
        for (CSWVariable *externalVariable in [constraint.expression externalVariables]) {
            [_updatedExternals addObject:externalVariable];
        }
    }
    
    ExpressionResult expressionResult;
    CSWLinearExpression *expression = [self createExpression:constraint expressionResult:&expressionResult];
    BOOL addedDirectly = [self tryAddingExpressionDirectly: expression];
    if (!addedDirectly) {
        NSError *error = nil;
        [self addWithArtificialVariable:expression error:&error];
        if (error != nil) {
            [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Conflicting constraint" userInfo:nil] raise];
        }
    }
    
    if ([constraint isEditConstraint]) {
        CSWEditInfo *editInfo = [[CSWEditInfo alloc] initWithVariable:constraint.variable constraint:constraint plusVariable: expressionResult.plus minusVariable:expressionResult.minus previousConstant:expressionResult.previousConstant];
        [self.editVariableManager addEditInfo:editInfo];
    }
    
    _needsSolving = YES;
}

-(BOOL)tryAddingExpressionDirectly: (CSWLinearExpression*)expression {
    CSWVariable *subject = [self choseSubject:expression];
    if (subject == nil) {
        return NO;
    }

    [expression newSubject: subject];
    if ([self.columns objectForKey:subject] != nil) {
        [self substituteOutVariable:subject forExpression:expression];
    }
    
    [self addRowForVariable:subject equalsExpression:expression];
    return YES;
}

-(BOOL)columnsContainObjectiveVariable
{
    return [self.columns objectForKey:_objective] != nil;
}

-(void)removeConstraints: (NSArray*)constraints
{
    for (CSWConstraint *constraint in constraints) {
        [self removeConstraint:constraint];
    }
    if (self.autoSolve) {
        [self solve];
    }
}

-(void)removeConstraint: (CSWConstraint*)constraint
{
    [self _removeConstraint:constraint];
    // Do additional housekeeping for edit/stay constraints
    if ([constraint isEditConstraint]) {
        CSWEditInfo *editInfoForConstraint = [self.editVariableManager editInfoForConstraint:constraint];
        [self removeColumn:editInfoForConstraint.minusVariable];
        [self.editVariableManager removeEditInfoForConstraint:constraint];
    } else if ([constraint isStayConstraint] && [_errorVariables objectForKey:constraint] != nil) {
        [self removeStayErrorVariablesForConstraint:constraint];
    }
    
    if (self.autoSolve) {
        [self solve];
    }
}

-(void)_removeConstraint: (CSWConstraint*)constraint
{
    [self resetStayConstraints];
    
    CSWLinearExpression *zRow = [self.rows objectForKey:_objective];
    NSArray *constraintErrorVars = [_errorVariables objectForKey:constraint];
    if (constraintErrorVars != nil) {
        for (CSWVariable *errorVariable in constraintErrorVars) {
            CSWDouble value = -[constraint.strength value];

            if ([self isBasicVariable:errorVariable]) {
                CSWLinearExpression *errorVariableRowExpression = [self.rows objectForKey:errorVariable];
                [self addNewExpression:errorVariableRowExpression toExpression:zRow n:value subject:_objective];
            } else {
                [self addVariable:errorVariable toExpression:zRow withCoefficient:value subject: _objective];
            }
        }
    }

    CSWVariable *constraintMarkerVariable = [_markerVariables objectForKey:constraint];
    if (constraintMarkerVariable == nil) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Marker variable not found for constraint" userInfo:nil] raise];
    }
    [_markerVariables removeObjectForKey:constraint];
    
    if ([self.rows objectForKey:constraintMarkerVariable] == nil) {
        CSWVariable * exitVariable = [self resolveExitVariableRemoveConstraint:constraintMarkerVariable];
        if (exitVariable) {
            [self pivotWithEntryVariable:constraintMarkerVariable exitVariable:exitVariable];
        } else {
            // ExitVar doesn't occur in any equations, so just remove it.
            [self removeColumn:constraintMarkerVariable];
        }
    }
    
    if ([self isBasicVariable:constraintMarkerVariable]) {
        [self removeRowForVariable:constraintMarkerVariable];
    }
    
    // Delete any error variables.  If cn is an inequality, it also
    // contains a slack variable; but we use that as the marker variable
    // and so it has been deleted when we removed its row.
    for (CSWVariable *errorVariable in constraintErrorVars) {
        if (errorVariable != constraintMarkerVariable) {
            [self removeColumn: errorVariable];
        }
    }
    
    if (constraintErrorVars != nil) {
        [_errorVariables removeObjectForKey: constraint];
    }
    
    _needsSolving = YES;
}

- (CSWVariable *)resolveExitVariableRemoveConstraint:(CSWVariable *)constraintMarkerVariable {
    
    CSWVariable *exitVariable = [self findExitVariableForMarkerVariableThatIsRestrictedAndHasANegativeCoefficient:constraintMarkerVariable];
    if (exitVariable != nil) {
        return exitVariable;
    }
    
    // If we didn't set exitvar above, then either the marker
      // variable has a positive coefficient in all equations, or it
      // only occurs in equations for unrestricted variables.  If it
      // does occur in an equation for a restricted variable, pick the
      // equation that gives the smallest ratio.  (The row with the
      // marker variable will become infeasible, but all the other rows
      // will still be feasible; and we will be dropping the row with
      // the marker variable.  In effect we are removing the
      // non-negativity restriction on the marker variable.)
    if (exitVariable == nil) {
        exitVariable = [self findExitVariableForEquationWhichMinimizesRatioOfRestrictedVariables: constraintMarkerVariable];
    }
    
    if (exitVariable == nil) {
        // Pick an exit var from among the unrestricted variables whose equation involves the marker var
        NSSet *column = [self.columns objectForKey:constraintMarkerVariable];
        for (CSWVariable *variable in column) {
            if (variable != _objective) {
                exitVariable = variable;
                break;
            }
        }
    }
    return exitVariable;
}

- (CSWVariable*)findExitVariableForMarkerVariableThatIsRestrictedAndHasANegativeCoefficient:(CSWVariable *)constraintMarkerVariable {
    CSWVariable *exitVariable = nil;
    CSWDouble minRatio = 0;
    
    NSSet *column = [self.columns objectForKey:constraintMarkerVariable];
    for (CSWVariable *variable in column) {
        if ([variable isRestricted]) {
            CSWLinearExpression *expression = [self.rows objectForKey:variable];
            CSWDouble coefficient = [expression coefficientForTerm:constraintMarkerVariable];
            if (coefficient < 0) {
                CSWDouble r = -expression.constant / coefficient;
                BOOL isNewExitVarCandidate = exitVariable == nil || r < minRatio || ([CSWFloatComparator isApproxiatelyEqual:r b:minRatio] && [self shouldPreferPivotableVariable:variable overPivotableVariable:exitVariable]);
                if (isNewExitVarCandidate) {
                    minRatio = r;
                    exitVariable = variable;
                }
            }
        }
    }
    
    return exitVariable;
}

- (CSWVariable*)findExitVariableForEquationWhichMinimizesRatioOfRestrictedVariables:(CSWVariable *)constraintMarkerVariable {
    CSWVariable *exitVariable = nil;
    CSWDouble minRatio = 0;

    NSSet *column = [self.columns objectForKey:constraintMarkerVariable];
    for (CSWVariable *variable in column) {
        if ([variable isRestricted]) {
            CSWLinearExpression *expression = [self rowExpressionForVariable:variable];
            CSWDouble coefficient = [expression coefficientForTerm:constraintMarkerVariable];
            CSWDouble r = [expression constant] / coefficient;
            
            if (exitVariable == nil || r < minRatio) {
                minRatio = r;
                exitVariable = variable;
            }
        }
    }
    
    return exitVariable;
}

- (void)removeStayErrorVariablesForConstraint:(CSWConstraint *)constraint {
    NSArray *constraintErrorVars = [_errorVariables objectForKey:constraint];
    for (CSWVariable *variable in [_stayPlusErrorVariables copy]) {
        if ([constraintErrorVars containsObject:variable]) {
            [_stayPlusErrorVariables removeObject:variable];
        }
    }
    for (CSWVariable *variable in [_stayMinusErrorVariables copy]) {
        if ([constraintErrorVars containsObject:variable]) {
            [_stayPlusErrorVariables removeObject:variable];
        }
    }
}

-(CSWVariable*)choseSubject: (CSWLinearExpression*)expression
{
    CSWVariable *subject = [self chooseSubjectFromExpression:expression];
    if (subject != nil) {
        return subject;
    }
    
    if (![expression containsOnlyDummyVariables]) {
        return nil;
    }
    
    // variables, then we can pick a dummy variable as the subject.
    float coefficent = 0;
    for (CSWVariable *term in expression.termVariables) {
         if (![self.columns objectForKey:term]) {
            subject = term;
            coefficent = [expression coefficientForTerm:term];
        }
    }
    
    // If we get this far, all of the variables in the expression should
     // be dummy variables.  If the constant is nonzero we are trying to
     // add an unsatisfiable required constraint.  (Remember that dummy
     // variables must take on a value of 0.)
    if (![CSWFloatComparator isApproxiatelyZero: expression.constant] ) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Unsatisfiable required constraint" userInfo:nil] raise];
    }
    
    // Otherwise, if the constant is grater than zero, multiply by -1 if necessary to
    // make the coefficient for the subject negative.
    if (coefficent > 0) {
        [expression setConstant:expression.constant * -1];
    }
    
    return subject;
}

- (CSWVariable * _Nonnull)chooseSubjectFromExpression:(CSWLinearExpression * _Nonnull)expression {
    BOOL foundUnrestricted = NO;
    BOOL foundNewRestricted = NO;
    
    CSWVariable *subject = nil;
    for (CSWVariable *variable in expression.termVariables) {
        CGFloat coefficent = [[expression multiplierForTerm:variable] floatValue];
        BOOL isNewVariable = ![self.columns doesContain:variable];
        
        if (foundUnrestricted && ![variable isRestricted] && isNewVariable) {
            return variable;
        } else if (foundUnrestricted == NO) {
            if ([variable isRestricted]) {
                if (!foundNewRestricted && ![variable isDummy] && coefficent < 0) {
                    NSSet *col = [self.columns objectForKey:variable];
                    if (col == nil || ([col count] == 1 && [self columnsContainObjectiveVariable])) {
                        subject = variable;
                        foundNewRestricted = true;
                    }
                }
            } else {
                subject = variable;
                foundUnrestricted = YES;
            }
        }
    }
    
    return subject;
}

-(void)beginEdit
{
    if ([self.editVariableManager isEmpty]) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"No edit variables have been added to solver" userInfo:nil] raise];
    }
    [_infeasibleRows removeAllObjects];
    [self resetStayConstraints];
    [self.editVariableManager pushEditVariableCount];
}

-(void)endEdit
{
    if ([self.editVariableManager isEmpty]) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"No edit variables have been added to solver" userInfo:nil] raise];
    }
    
    [self resolve];
    
    for (CSWEditInfo *editInfo in [self.editVariableManager getNextSet]) {
        [self removeEditVariableForEditInfo: editInfo];
    }
}

-(void)resolve
{
    [self dualOptimize];
    [self _updateExternalVariables];
    [_infeasibleRows removeAllObjects];
    [self resetStayConstraints];
}

-(void)removeEditVariableForEditInfo: (CSWEditInfo*)editInfoForVariable
{
    if (editInfoForVariable == nil) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Failed to find edit info for variable" userInfo:nil] raise];
    }
    
    [self _removeConstraint:editInfoForVariable.constraint];
    [self removeColumn:editInfoForVariable.minusVariable];
    [self.editVariableManager removeEditInfo:editInfoForVariable];
}

-(void)suggestEditVariables: (NSArray*)suggestions
{
    for (CSWSuggestion *suggestion in suggestions) {
        [self addEditVariableForVariable:[suggestion variable] strength:[CSWStrength strengthStrong]];
    }
    
    [self beginEdit];
    for (CSWSuggestion *suggestion in suggestions) {
        [self suggestEditVariable:[suggestion variable] equals:[suggestion value]];
    }
    [self endEdit];
}


-(void)suggestVariable: (CSWVariable*)varible equals: (CSWDouble)value
{
    [self addEditVariableForVariable:varible strength:[CSWStrength strengthStrong]];
    [self beginEdit];
    [self suggestEditVariable:varible equals:value];
    [self endEdit];
}

-(void)suggestEditConstraint: (CSWConstraint*)constraint equals: (CSWDouble)value
{
    if (![constraint isEditConstraint]) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Not an edit constraint" userInfo:nil] raise];
    }
    
    CSWEditInfo *editInfo = [self.editVariableManager editInfoForConstraint:constraint];
    if (editInfo == nil) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Edit Info not found for constraint" userInfo:nil] raise];
    }
    
    CSWDouble delta = value - editInfo.previousConstant;
    editInfo.previousConstant = delta;
    [self deltaEditConstant:delta plusErrorVariable:editInfo.plusVariable minusErrorVariable:editInfo.minusVariable];
}

-(void)suggestEditVariable: (CSWVariable*)variable equals: (CSWDouble)value
{
    for (CSWEditInfo *editInfo in [self.editVariableManager editInfosForVariable:variable]) {
        CSWDouble delta = value - editInfo.previousConstant;
        editInfo.previousConstant = value;
        [self deltaEditConstant:delta plusErrorVariable:editInfo.plusVariable minusErrorVariable:editInfo.minusVariable];
    }
}

-(void)deltaEditConstant: (CSWDouble)delta plusErrorVariable: (CSWVariable*)plusErrorVariable minusErrorVariable: (CSWVariable*)minusErrorVariable
{
    CSWLinearExpression *plusExpression = [self.rows objectForKey:plusErrorVariable];
    if (plusExpression != nil) {
        plusExpression.constant += delta;
        if (plusExpression.constant < 0) {
            [_infeasibleRows addObject:plusErrorVariable];
        }
        return;
    }
    
    CSWLinearExpression *minusExpression = [self.rows objectForKey:minusErrorVariable];
    if (minusExpression != nil) {
        minusExpression.constant += -delta;
        if (minusExpression.constant < 0) {
            [_infeasibleRows addObject:minusErrorVariable];
        }
        return;
    }
    
    // Neither is basic.  So they must both be nonbasic, and will both
    // occur in exactly the same expressions.  Find all the expressions
    // in which they occur by finding the column for the minusErrorVar
    // (it doesn't matter whether we look for that one or for
    // plusErrorVar).  Fix the constants in these expressions.
    
    NSSet *columnVars = [self.columns objectForKey:minusErrorVariable];
    if (!columnVars) {
        NSLog(@"columns for variable is null");
    }
    
    for (CSWVariable *basicVariable in columnVars) {
        CSWLinearExpression *expression = [self.rows objectForKey: basicVariable];
        CSWDouble coefficient = [expression coefficientForTerm:minusErrorVariable];
        expression.constant += coefficient * delta;
        if (basicVariable.isExternal) {
            [_updatedExternals addObject:basicVariable];
        }
        if (basicVariable.isRestricted && expression.constant < 0) {
            [_infeasibleRows addObject:basicVariable];
        }
    }
}


-(void)addEditVariableForVariable: (CSWVariable*)variable strength: (CSWStrength*)strength
{
    CSWConstraint *editVariableConstraint = [[CSWConstraint alloc] initEditConstraintWithVariable:variable stength:strength];
    [self addConstraint: editVariableConstraint];
}

/** Make a new linear expression representing the constraint c,
 ** replacing any basic variables with their defining expressions.
 * Normalize if necessary so that the constant is non-negative.  If
 * the constraint is non-required, give its error variables an
 * appropriate weight in the objective function. */
-(CSWLinearExpression*)createExpression: (CSWConstraint *)constraint expressionResult: (ExpressionResult*)expressionResult;
{
    CSWLinearExpression *constraintExpression = [constraint expression];
    
    CSWLinearExpression *newExpression = [[CSWLinearExpression alloc] init];
    [newExpression setConstant:[constraintExpression constant]];
    
    for (CSWVariable *term in constraintExpression.termVariables) {
        CSWDouble termCoefficient = [[constraintExpression multiplierForTerm: term] doubleValue];
        CSWLinearExpression *rowExpression = [self.rows objectForKey:term];
        if ([self isBasicVariable:term]) {
            [self addNewExpression:rowExpression toExpression:newExpression n:termCoefficient subject:nil];
        } else {
            [self addVariable:term toExpression:newExpression withCoefficient:termCoefficient subject:nil];
        }
    }
    
    ExpressionResult *result = expressionResult;
    result->expression = nil;
    result->minus = nil;
    result->plus = nil;
    
    if ([constraint isInequality]) {
        [self applyInequityConstraint:constraint newExpression:newExpression];
    } else {
        [self applyConstraint:constraint newExpression:newExpression result:&result];
    }
    
    // the Constant in the Expression should be non-negative. If necessary
    // normalize the Expression by multiplying by -1
    if (newExpression.constant < 0) {
        [newExpression normalize];
    }
    
    return newExpression;
}

- (void)applyConstraint:(CSWConstraint *)constraint newExpression:(CSWLinearExpression *)newExpression result:(ExpressionResult **)result {
    CSWLinearExpression *constraintExpression = [constraint expression];

    if ([constraint isRequired]) {
        CSWVariable *dummyVariable = [self createDummyVariableWithPrefix:@"d"];
        
        (*result)->plus = dummyVariable;
        (*result)->minus = dummyVariable;
        (*result)->previousConstant = constraintExpression.constant;
        [self setVariable:dummyVariable onExpression:newExpression withCoefficient:1];
        [_markerVariables setObject:dummyVariable forKey:constraint];
    } else {
        // cn is a non-required equality. Add a positive and a negative error
        // variable, making the resulting constraint
        //       expr = eplus - eminus
        // in other words:
        //       expr - eplus + eminus = 0
        
        _slackCounter++;
        CSWVariable *eplusVariable = [self createSlackVariableWithPrefix:@"ep"];
        CSWVariable *eminusVariable = [self createSlackVariableWithPrefix:@"em"];
        
        [self setVariable:eplusVariable onExpression:newExpression withCoefficient:-1];
        [self setVariable:eminusVariable onExpression:newExpression withCoefficient:1];
        [_markerVariables setObject:eplusVariable forKey:constraint];
        
        CSWLinearExpression *zRow = [self.rows objectForKey: _objective];
        CSWDouble swCoefficient = [constraint.strength value];
        
        [self setVariable:eplusVariable onExpression:zRow withCoefficient:swCoefficient];
        [self addMappingFromExpressionVariable:eplusVariable toRowVariable:_objective];
        
        [self setVariable:eminusVariable onExpression:zRow withCoefficient:swCoefficient];
        [self addMappingFromExpressionVariable:eminusVariable toRowVariable:_objective];
        
        [self insertErrorVariable:constraint variable:eminusVariable];
        [self insertErrorVariable:constraint variable:eplusVariable];
        
        if ([constraint isStayConstraint]) {
            [_stayPlusErrorVariables addObject:eplusVariable];
            [_stayMinusErrorVariables addObject:eminusVariable];
        } else if ([constraint isEditConstraint]) {
            (*result)->plus = eplusVariable;
            (*result)->minus = eminusVariable;
            (*result)->previousConstant = constraintExpression.constant;
        }
    }
}

/*
  Add a slack variable. The original constraint
 // is expr>=0, so that the resulting equality is expr-slackVar=0. If cn is
 // also non-required Add a negative error variable, giving:
 //
 //    expr - slackVar = -errorVar
 //
 // in other words:
 //
 //    expr - slackVar + errorVar = 0
 //
 // Since both of these variables are newly created we can just Add
 // them to the Expression (they can't be basic).
 */
- (void)applyInequityConstraint:(CSWConstraint *)constraint newExpression:(CSWLinearExpression *)newExpression {
    _slackCounter++;
    CSWVariable *slackVariable = [self createSlackVariableWithPrefix:@"s"];
    [self setVariable:slackVariable onExpression:newExpression withCoefficient:-1];
    
    [_markerVariables setObject:slackVariable forKey:constraint];
    
    if (![constraint isRequired]) {
        CSWVariable *eminusSlackVariable = [self createSlackVariableWithPrefix:@"em"];
        [newExpression addVariable:eminusSlackVariable coefficient:1];
        
        CSWDouble eminusCoefficient = [constraint.strength value];
        CSWLinearExpression *zRow = [self.rows objectForKey: _objective];
        [self setVariable:eminusSlackVariable onExpression:zRow withCoefficient: eminusCoefficient];
        
        [self insertErrorVariable:constraint variable:eminusSlackVariable];
        [self addMappingFromExpressionVariable:eminusSlackVariable toRowVariable: _objective];
    }
}

-(void)addWithArtificialVariable: (CSWLinearExpression*)expression error: (NSError **)error
{
    
    // The artificial objective is av, which we know is equal to expr
    // (which contains only parametric variables).
    CSWVariable *artificialVariable = [CSWVariable slackVariableWithName:[NSString stringWithFormat:@"%@%d", @"a", ++_artificialCounter]];
    
    CSWVariable *artificialZ = [CSWVariable objectiveVariableWithName:@"az"];
    CSWLinearExpression *row = [expression copy];
    
    // Objective is treated as a row in the tableau,
    // so do the substitution for its value (we are minimizing
    // the artificial variable).
    // This row will be removed from the tableau after optimizing.
    [self addRowForVariable:artificialZ equalsExpression:row];
    
    // Add the normal row to the tableau -- when artifical
    // variable is minimized to 0 (if possible)
    // this row remains in the tableau to maintain the constraint
    // we are trying to add.
    [self addRowForVariable: artificialVariable equalsExpression:expression];

    
    // Try to optimize az to 0.
    // Note we are *not* optimizing the real objective, but optimizing
    // the artificial objective to see if the error in the constraint
    // we are adding can be set to 0.
    [self optimize: artificialZ];
    
    CSWLinearExpression *azTableauRow = [self.rows objectForKey:artificialZ];
    
    if (![CSWFloatComparator isApproxiatelyZero:azTableauRow.constant]) {
        [self removeRowForVariable:artificialZ];
        [self removeColumn:artificialVariable];
        *error = [[NSError alloc] initWithDomain:CSWErrorDomain code:CSWErrorCodeRequired userInfo:nil];
        return;
    }
    
    CSWLinearExpression *rowExpression = [self rowExpressionForVariable: artificialVariable];
    if (rowExpression != nil) {
        if ([rowExpression isConstant]) {
            [self removeRowForVariable:artificialVariable];
            [self removeRowForVariable:artificialZ];
            return;
        }
        CSWVariable *entryVariable = [rowExpression anyPivotableVariable];
        [self pivotWithEntryVariable:entryVariable exitVariable:artificialVariable];
    }
    
    [self removeColumn:artificialVariable];
    [self removeRowForVariable:artificialZ];
}

-(void)solve
{
    [self optimize:_objective];
    [self _updateExternalVariables];
}

// Minimize the value of the objective.  (The tableau should already be feasible.)
-(void)optimize: (CSWVariable*)zVariable
{
    CSWLinearExpression *zRow = [self.rows objectForKey:zVariable];
    if (zRow == nil) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Optimize zRow is null" userInfo:nil] raise];
    }
        
    // Find the most negative coefficient in the objective function (ignoring
    // the non-pivotable dummy variables). If all coefficients are positive
    // we're done
    CSWVariable *entryVariable = [zRow findPivotableVariableWithMostNegativeCoefficient];
    CSWDouble objectiveCoefficient = entryVariable != nil ? [zRow coefficientForTerm:entryVariable] : 0;
    while (objectiveCoefficient < -CSWEpsilon) {
        // choose which variable to move out of the basis
        // Only consider pivotable basic variables
        // (i.e. restricted, non-dummy variables)
        CSWVariable *exitVariable = [self findPivotableExitVariable:entryVariable];
        [self pivotWithEntryVariable:entryVariable exitVariable:exitVariable];
        
        objectiveCoefficient = 0;
        entryVariable = [zRow findPivotableVariableWithMostNegativeCoefficient];
        if (entryVariable != nil) {
            objectiveCoefficient = [zRow coefficientForTerm:entryVariable];
        }
    }
}

- (CSWVariable*)findPivotableExitVariable:(CSWVariable *)entryVariable {
    CSWDouble minRatio = DBL_MAX;
    CSWDouble r = 0;
    CSWVariable *exitVariable = nil;
    for (CSWVariable *variable in [self.columns objectForKey: entryVariable]) {
        if ([variable isPivotable]) {
            CSWLinearExpression *expression = [self.rows objectForKey:variable];
            CSWDouble coefficient = [expression coefficientForTerm:entryVariable];
            
            if (coefficient < 0) {
                r = -expression.constant / coefficient;
                
                // Bland's anti-cycling rule:
                // if multiple variables are about the same,
                // always pick the lowest via some total
                // ordering -- in this implementation we preferred the variable created first
                if (r < minRatio || ([CSWFloatComparator isApproxiatelyEqual:r b:minRatio] && [self shouldPreferPivotableVariable:variable overPivotableVariable:exitVariable])) {
                    minRatio = r;
                    exitVariable = variable;
                }
            }
        }
    }
    
    if (exitVariable == nil) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Objective function is unbounded in optimize" userInfo:nil] raise];
    }
    
    return exitVariable;
}

-(BOOL)shouldPreferPivotableVariable: (CSWVariable*)lhs overPivotableVariable: (CSWVariable*)rhs
{
    return [lhs id] < [rhs id];
}

// We have set new values for the constants in the edit constraints.
// Re-Optimize using the dual simplex algorithm.
-(void)dualOptimize
{
    while ([_infeasibleRows count] > 0) {
        CSWVariable *exitVariable = [_infeasibleRows firstObject];
        [_infeasibleRows removeObject:exitVariable];
        
        CSWLinearExpression *exitVariableExpression = [self.rows objectForKey:exitVariable];
        if (!exitVariableExpression) {
              continue;
        }
        // exitVar might have become basic after some other pivoting
        // so allow for the case of its not being there any longer
        if (exitVariableExpression.constant < 0)
        {
            CSWVariable *entryVariable = [self resolveDualOptimizePivotEntryVariableForExpression: exitVariableExpression];
            [self pivotWithEntryVariable:entryVariable exitVariable:exitVariable];
        }
        
    }
}

- (CSWVariable*)resolveDualOptimizePivotEntryVariableForExpression:(CSWLinearExpression *)expression {
    CSWDouble ratio = DBL_MAX;
    CSWLinearExpression *zRow = [self.rows objectForKey:_objective];
    CSWVariable *entryVariable = nil;

    // Order of expression variables has an effect on the pivot and also when slack variables were created
    for (CSWVariable *term in expression.termVariables) {
        CSWDouble coefficient = [expression coefficientForTerm:term];
        if (coefficient > 0 && [term isPivotable]) {
            CSWDouble zCoefficient = [zRow coefficientForTerm:term];
            CSWDouble r = zCoefficient / coefficient;
            
            if (r < ratio || ([CSWFloatComparator isApproxiatelyEqual:r b:ratio] && [self shouldPreferPivotableVariable:term overPivotableVariable:entryVariable])) {
                entryVariable = term;
                ratio = r;
            }
        }
    }
    if (ratio == DBL_MAX) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"ratio == nil (MAX_VALUE) in dualOptimize" userInfo:nil] raise];
    }
    return entryVariable;
}

-(void)_updateExternalVariables
{
    for (CSWVariable *variable in _externalRows) {
        CSWDouble calculatedValue = [self rowExpressionForVariable:variable].constant;
        if (calculatedValue != variable.value) {
            [variable setValue:calculatedValue];
        }
    }
    
    [_updatedExternals removeAllObjects];
    _needsSolving = false;
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
        [_externalParametricVariables removeObject:entryVariable];
    }
    
    [self addRowForVariable:entryVariable equalsExpression:expression];
}

-(void)insertErrorVariable: (CSWConstraint*)constraint variable: (CSWVariable*)variable
{
    NSMutableSet *constraintSet = [_errorVariables objectForKey:constraint];
    if (constraintSet == nil) {
        constraintSet = [NSMutableSet set];
        [_errorVariables setObject:constraintSet forKey:constraint];
    }
    [constraintSet addObject:variable];
}

-(void)resetStayConstraints
{
    if (_stayPlusErrorVariables.count != _stayMinusErrorVariables.count) {
        [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected the number of stayPlusErrorVariables to match the number of stayMinusErrorVariables" userInfo:nil];
    }
    
    for (int i = 0; i < [_stayPlusErrorVariables count]; i++) {
        CSWVariable *stayPlusErrorVariable = [_stayPlusErrorVariables objectAtIndex:i];
        CSWVariable *stayMinusErrorVariable = [_stayMinusErrorVariables objectAtIndex:i];
        if ([self isBasicVariable:stayPlusErrorVariable]) {
            CSWLinearExpression *stayPlusErrorExpression = [self.rows objectForKey:stayPlusErrorVariable];
            [stayPlusErrorExpression setConstant:0];
        }
        if ([self isBasicVariable:stayMinusErrorVariable]) {
            CSWLinearExpression *stayMinusErrorExpression = [self.rows objectForKey:stayMinusErrorVariable];
            [stayMinusErrorExpression setConstant:0];
        }
    }
}

-(void)updateConstraint: (CSWConstraint*)constraint strength: (CSWStrength*)strength;
{
    NSArray *errorVariablesForConstraint = [_errorVariables objectForKey:constraint];
    if (errorVariablesForConstraint == nil) {
        return;
    }
    
    CSWDouble existingCoefficient = [constraint.strength value];
    [constraint setStrength:strength];
    
    CSWDouble newCoefficient = [constraint.strength value];
    
    if (newCoefficient == existingCoefficient) {
        return;
    }
    
    [self updateErrorVariablesForConstraint:constraint existingCoefficient:existingCoefficient newCoefficient:newCoefficient];

    _needsSolving = true;
    if (self.autoSolve) {
        [self solve];
    }
}

- (void)updateErrorVariablesForConstraint:(CSWConstraint *)constraint existingCoefficient:(CSWDouble)existingCoefficient newCoefficient:(CSWDouble)newCoefficient {
    CSWLinearExpression *objectiveRowExpression = [self rowExpressionForVariable: _objective];

    NSArray *errorVariablesForConstraint = [_errorVariables objectForKey:constraint];
    for (CSWVariable *variable in errorVariablesForConstraint) {
        if (![self isBasicVariable:variable]) {
            [self addVariable:variable toExpression:objectiveRowExpression withCoefficient:-existingCoefficient subject:_objective];
            [self addVariable:variable toExpression:objectiveRowExpression withCoefficient:newCoefficient subject:_objective];
        } else {
            CSWLinearExpression *expression = [[self rowExpressionForVariable:variable] copy];
            [self addNewExpression:expression toExpression:objectiveRowExpression n:-existingCoefficient subject:_objective];
            [self addNewExpression:expression toExpression:objectiveRowExpression n:newCoefficient subject:_objective];
        }
    }
}

-(BOOL)containsConstraint: (CSWConstraint*)constraint
{
    return [_markerVariables objectForKey:constraint] != nil;
}

-(BOOL)isValid
{
    return
        [self containsExternalRowForEachExternalRowVariable] &&
        [self containsExternalParametricVariableForEveryExternalTerm];
}

- (BOOL)containsExternalRowForEachExternalRowVariable {
    for (CSWVariable *rowVariable in self.rows) {
        if ([rowVariable isExternal]) {
            if ([_externalRows objectForKey:rowVariable] == nil) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (BOOL)containsExternalParametricVariableForEveryExternalTerm {
    for (CSWVariable *rowVariable in self.rows) {
        CSWLinearExpression *expression = [self.rows objectForKey:rowVariable];
        for (CSWVariable *variable in [expression termVariables]) {
            if ([variable isExternal]) {
                if (![_externalParametricVariables containsObject:variable]) {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

- (void)removeEditVariable: (CSWVariable*)variable
{
    NSArray *editInfos = [self.editVariableManager editInfosForVariable:variable];
    if (editInfos.count == 0) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Edit variable not found" userInfo:nil] raise];
    }
    
    [self removeConstraint:[[editInfos firstObject] constraint]];
}

-(NSUInteger)getNextVariableId
{
    return ++_variableCounter;
}

-(CSWVariable*)createSlackVariableWithPrefix: (NSString*)prefix
{
    CSWVariable *slackVariable = [CSWVariable slackVariableWithName:[NSString stringWithFormat:@"%@%d", prefix, _slackCounter]];
    // [[CSWSlackVariable alloc] initWithName:[NSString stringWithFormat:@"%@%d", prefix, _slackCounter]];
    slackVariable.id = [self getNextVariableId];
    _variableCounter++;
    return slackVariable;
}

-(CSWVariable*)createDummyVariableWithPrefix: (NSString*)prefix
{
    _dummyCounter++;
    return [CSWVariable dummyVariableWithName:[NSString stringWithFormat:@"%@%d", prefix, _dummyCounter]];
}
 
@end

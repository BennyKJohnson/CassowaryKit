#import "CSWSimplexSolver.h"
#import "CSWFloatComparator.h"
#import "CSWVariable.h"
#import "CSWEditInfo.h"
#import "CSWVariable+PrivateMethods.h"
#import "CSWSimplexSolverSolution.h"

NSString * const CSWErrorDomain = @"com.cassowary";

@implementation CSWSimplexSolver

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tableau = [[CSWTableau alloc] init];
        _stayMinusErrorVariables = [NSMutableArray array];
        _stayPlusErrorVariables = [NSMutableArray array];
  
        _markerVariables = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
        valueOptions:NSMapTableStrongMemory];
        _errorVariables = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
        valueOptions:NSMapTableStrongMemory];
                
        _artificialCounter = 0;
        
        _constraintConverter = [[CSWTableauConstraintConverter alloc] init];
        
        _addedConstraints = [NSMutableArray array];
                
        _objective = [CSWVariable objectiveVariableWithName:@"Z"];
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
        [_tableau addRowForVariable:_objective equalsExpression: expression];
        
        self.editVariableManager = [[CSWEditVariableManager alloc] init];

        _needsSolving = NO;
    }
    
    return self;
}

-(void)addConstraints: (NSArray*)constraints
{
    for (CSWConstraint *constraint in constraints) {
        [self _addConstraint:constraint tableau:_tableau entryVariable:nil];
        [_addedConstraints addObject: constraint];
    }
    
    if (self.autoSolve) {
        [self solve];
    }
}

-(void)addConstraint:(CSWConstraint *)constraint
{
    [self _addConstraint:constraint tableau:_tableau entryVariable:nil];
    
    [_addedConstraints addObject: constraint];
    if (self.autoSolve) {
        [self solve];
    }
}

-(void)_addConstraint: (CSWConstraint*)constraint tableau: (CSWTableau*)tableau entryVariable: (CSWVariable*)entryVariable
{
    if ([constraint isEditConstraint] && ![[constraint variable] isExternal]) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot have an edit variable with a non external variable" userInfo:nil] raise];
    }
    
    if ([constraint isKindOfClass:[CSWConstraint class]]) {
        for (CSWVariable *externalVariable in [constraint.expression externalVariables]) {
            [tableau.updatedExternals addObject:externalVariable];
        }
    }
    
    ExpressionResult expressionResult;
    
    CSWLinearExpression *expression = [_constraintConverter createExpression:constraint expressionResult:&expressionResult tableau:tableau objective: _objective];
    [_markerVariables setObject:expressionResult.marker forKey:constraint];

    if ([constraint isStayConstraint]) {
        if (expressionResult.plus != nil) {
            [_stayPlusErrorVariables addObject:expressionResult.plus];
        }
        if (expressionResult.minus != nil) {
            [_stayMinusErrorVariables addObject:expressionResult.minus];
        }
    }
    
    if (![constraint isInequality] && ![constraint isRequired]) {
        [self insertErrorVariable:constraint variable:expressionResult.minus];
        [self insertErrorVariable:constraint variable:expressionResult.plus];
    }
    if ([constraint isInequality] && ![constraint isRequired]) {
        [self insertErrorVariable:constraint variable:expressionResult.minus];
    }
    
    
    BOOL addedDirectly = [self tryAddingExpressionDirectly: expression tableau:tableau];
    if (!addedDirectly) {
        NSError *error = nil;
        [self addWithArtificialVariable:expression error:&error tableau:tableau entryVariable: entryVariable];
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

-(BOOL)tryAddingExpressionDirectly: (CSWLinearExpression*)expression tableau: (CSWTableau*)tableau {
    CSWVariable *subject = [self choseSubject:expression tableau:tableau];
    if (subject == nil) {
        return NO;
    }

    [expression newSubject: subject];
    if ([tableau hasColumnForVariable: subject]) {
        [tableau substituteOutVariable:subject forExpression:expression];
    }
    
    [tableau addRowForVariable:subject equalsExpression:expression];
    return YES;
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
    [self _removeConstraint:constraint tableau:_tableau];
    // Do additional housekeeping for edit/stay constraints
    if ([constraint isEditConstraint]) {
        CSWEditInfo *editInfoForConstraint = [self.editVariableManager editInfoForConstraint:constraint];
        [_tableau removeColumn:editInfoForConstraint.minusVariable];
        [self.editVariableManager removeEditInfoForConstraint:constraint];
    } else if ([constraint isStayConstraint] && [_errorVariables objectForKey:constraint] != nil) {
        [self removeStayErrorVariablesForConstraint:constraint];
    }
    [_addedConstraints removeObject:constraint];
    
    if (self.autoSolve) {
        [self solve];
    }
}

-(void)_removeConstraint: (CSWConstraint*)constraint tableau: (CSWTableau*)tableau
{
    [self resetStayConstraints];
    
    CSWLinearExpression *zRow = [tableau rowExpressionForVariable:_objective];
    NSArray *constraintErrorVars = [_errorVariables objectForKey:constraint];
    if (constraintErrorVars != nil) {
        for (CSWVariable *errorVariable in constraintErrorVars) {
            CSWDouble value = -[constraint.strength value];

            if ([tableau isBasicVariable:errorVariable]) {
                CSWLinearExpression *errorVariableRowExpression = [tableau rowExpressionForVariable:errorVariable];
                [tableau addNewExpression:errorVariableRowExpression toExpression:zRow n:value subject:_objective];
            } else {
                [tableau addVariable:errorVariable toExpression:zRow withCoefficient:value subject: _objective];
            }
        }
    }

    CSWVariable *constraintMarkerVariable = [_markerVariables objectForKey:constraint];
    if (constraintMarkerVariable == nil) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Marker variable not found for constraint" userInfo:nil] raise];
    }
    [_markerVariables removeObjectForKey:constraint];
    
    if ([tableau rowExpressionForVariable:constraintMarkerVariable] == nil) {
        CSWVariable * exitVariable = [self resolveExitVariableRemoveConstraint:constraintMarkerVariable];
        if (exitVariable) {
            [tableau pivotWithEntryVariable:constraintMarkerVariable exitVariable:exitVariable];
        } else {
            // ExitVar doesn't occur in any equations, so just remove it.
            [tableau removeColumn:constraintMarkerVariable];
        }
    }
    
    if ([tableau isBasicVariable:constraintMarkerVariable]) {
        [tableau removeRowForVariable:constraintMarkerVariable];
    }
    
    // Delete any error variables.  If cn is an inequality, it also
    // contains a slack variable; but we use that as the marker variable
    // and so it has been deleted when we removed its row.
    for (CSWVariable *errorVariable in constraintErrorVars) {
        if (errorVariable != constraintMarkerVariable) {
            [tableau removeColumn: errorVariable];
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
        NSSet *column = [_tableau columnForVariable:constraintMarkerVariable];
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
    
    NSSet *column = [_tableau columnForVariable:constraintMarkerVariable];
    for (CSWVariable *variable in column) {
        if ([variable isRestricted]) {
            CSWLinearExpression *expression = [_tableau rowExpressionForVariable:variable];
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

    NSSet *column = [_tableau columnForVariable:constraintMarkerVariable];
    for (CSWVariable *variable in column) {
        if ([variable isRestricted]) {
            CSWLinearExpression *expression = [_tableau rowExpressionForVariable:variable];
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

-(CSWVariable*)choseSubject: (CSWLinearExpression*)expression tableau: (CSWTableau*)tableau
{
    CSWVariable *subject = [self chooseSubjectFromExpression:expression tableau:tableau];
    if (subject != nil) {
        return subject;
    }
    
    if (![expression containsOnlyDummyVariables]) {
        return nil;
    }
    
    // variables, then we can pick a dummy variable as the subject.
    float coefficent = 0;
    for (CSWVariable *term in expression.termVariables) {
         if (![tableau hasColumnForVariable:term]) {
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

- (CSWVariable * _Nonnull)chooseSubjectFromExpression:(CSWLinearExpression * _Nonnull)expression tableau: (CSWTableau*)tableau {
    BOOL foundUnrestricted = NO;
    BOOL foundNewRestricted = NO;
    
    CSWVariable *subject = nil;
    for (CSWVariable *variable in expression.termVariables) {
        CGFloat coefficent = [[expression multiplierForTerm:variable] floatValue];
        BOOL isNewVariable = ![tableau hasColumnForVariable:variable];
        
        if (foundUnrestricted && ![variable isRestricted] && isNewVariable) {
            return variable;
        } else if (foundUnrestricted == NO) {
            if ([variable isRestricted]) {
                if (!foundNewRestricted && ![variable isDummy] && coefficent < 0) {
                    NSSet *col = [tableau columnForVariable:variable];
                    if (col == nil || ([col count] == 1 && [tableau hasColumnForVariable:_objective])) {
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
    [_tableau.infeasibleRows removeAllObjects];
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
    [_tableau.infeasibleRows removeAllObjects];
    [self resetStayConstraints];
}

-(void)removeEditVariableForEditInfo: (CSWEditInfo*)editInfoForVariable
{
    if (editInfoForVariable == nil) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Failed to find edit info for variable" userInfo:nil] raise];
    }
    
    [self _removeConstraint:editInfoForVariable.constraint tableau: _tableau];
    [_tableau removeColumn:editInfoForVariable.minusVariable];
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
    CSWLinearExpression *plusExpression = [_tableau rowExpressionForVariable:plusErrorVariable];
    if (plusExpression != nil) {
        plusExpression.constant += delta;
        if (plusExpression.constant < 0) {
            [_tableau.infeasibleRows addObject:plusErrorVariable];
        }
        return;
    }
    
    CSWLinearExpression *minusExpression = [_tableau rowExpressionForVariable:minusErrorVariable];
    if (minusExpression != nil) {
        minusExpression.constant += -delta;
        if (minusExpression.constant < 0) {
            [_tableau.infeasibleRows addObject:minusErrorVariable];
        }
        return;
    }
    
    // Neither is basic.  So they must both be nonbasic, and will both
    // occur in exactly the same expressions.  Find all the expressions
    // in which they occur by finding the column for the minusErrorVar
    // (it doesn't matter whether we look for that one or for
    // plusErrorVar).  Fix the constants in these expressions.
    
    NSSet *columnVars = [_tableau columnForVariable:minusErrorVariable];
    if (!columnVars) {
        NSLog(@"columns for variable is null");
    }
    
    for (CSWVariable *basicVariable in columnVars) {
        CSWLinearExpression *expression = [_tableau rowExpressionForVariable: basicVariable];
        CSWDouble coefficient = [expression coefficientForTerm:minusErrorVariable];
        expression.constant += coefficient * delta;
        if (basicVariable.isExternal) {
            [_tableau.updatedExternals addObject:basicVariable];
        }
        if (basicVariable.isRestricted && expression.constant < 0) {
            [_tableau.infeasibleRows addObject:basicVariable];
        }
    }
}


-(void)addEditVariableForVariable: (CSWVariable*)variable strength: (CSWStrength*)strength
{
    CSWConstraint *editVariableConstraint = [[CSWConstraint alloc] initEditConstraintWithVariable:variable stength:strength];
    [self addConstraint: editVariableConstraint];
}

-(void)addWithArtificialVariable: (CSWLinearExpression*)expression error: (NSError **)error tableau: (CSWTableau*)tableau entryVariable: (CSWVariable*)entryVariable
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
    [tableau addRowForVariable:artificialZ equalsExpression:row];
    
    // Add the normal row to the tableau -- when artifical
    // variable is minimized to 0 (if possible)
    // this row remains in the tableau to maintain the constraint
    // we are trying to add.
    [tableau addRowForVariable: artificialVariable equalsExpression:expression];

    
    // Try to optimize az to 0.
    // Note we are *not* optimizing the real objective, but optimizing
    // the artificial objective to see if the error in the constraint
    // we are adding can be set to 0.
    [self optimize: artificialZ tableau:tableau entryVariable: entryVariable];
    
    CSWLinearExpression *azTableauRow = [tableau rowExpressionForVariable:artificialZ];
    
    if (![CSWFloatComparator isApproxiatelyZero:azTableauRow.constant]) {
        [tableau removeRowForVariable:artificialZ];
        [tableau removeColumn:artificialVariable];
        *error = [[NSError alloc] initWithDomain:CSWErrorDomain code:CSWErrorCodeRequired userInfo:nil];
        return;
    }
    
    CSWLinearExpression *rowExpression = [tableau rowExpressionForVariable: artificialVariable];
    if (rowExpression != nil) {
        if ([rowExpression isConstant]) {
            [tableau removeRowForVariable:artificialVariable];
            [tableau removeRowForVariable:artificialZ];
            return;
        }
        CSWVariable *entryVariable = [rowExpression anyPivotableVariable];
        [tableau pivotWithEntryVariable:entryVariable exitVariable:artificialVariable];
    }
    
    [tableau removeColumn:artificialVariable];
    [tableau removeRowForVariable:artificialZ];
}

-(void)solve
{
    [self optimize:_objective tableau:_tableau entryVariable:nil];
    [self _updateExternalVariables];
}

- (CSWTableau *)createTableauWithObjective {
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWVariable *tableauObjective  = [CSWVariable objectiveVariableWithName:@"Z"];
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [tableau addRowForVariable:tableauObjective equalsExpression: expression];
    return tableau;
}

-(NSArray*)solveAll
{
    [self optimize:_objective tableau:_tableau entryVariable:nil];
    CSWSimplexSolverSolution *solution = [self solutionFromTableau: _tableau];

    NSArray *specialVariables = [_tableau substitedOutNonBasicPivotableVariables:_objective];
    if ([specialVariables count] == 0) {
        return [NSArray arrayWithObject:solution];
    }
    
    // TODO handle edit and stay constraints
    NSMutableArray *solutions = [NSMutableArray arrayWithObject:solution];
    for (CSWVariable *specialVariable in specialVariables) {
        CSWTableau * tableau = [self createTableauWithObjective];
        
        for (CSWConstraint *constraint in _addedConstraints) {
            [self _addConstraint:constraint tableau:tableau entryVariable:specialVariable];
        }
        
        [solutions addObject: [self solutionFromTableau:tableau]];
    }
    
    return solutions;
}

-(CSWSimplexSolverSolution*)solutionFromTableau: (CSWTableau*)tableau
{
    CSWSimplexSolverSolution *solution = [[CSWSimplexSolverSolution alloc] init];
    for (CSWVariable *variable in tableau.externalRows) {
        CSWDouble calculatedValue = [tableau rowExpressionForVariable:variable].constant;
        [solution setResult:calculatedValue forVariable: variable];
    }
        
    return solution;
}

// Minimize the value of the objective.  (The tableau should already be feasible.)
-(void)optimize: (CSWVariable*)zVariable tableau: (CSWTableau*)tableau entryVariable: (CSWVariable*)preferredEntryVariable
{
    CSWLinearExpression *zRow = [tableau rowExpressionForVariable:zVariable];
    if (zRow == nil) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Optimize zRow is null" userInfo:nil] raise];
    }
        
    // Find the most negative coefficient in the objective function (ignoring
    // the non-pivotable dummy variables). If all coefficients are positive
    // we're done
    NSArray *entryVariableCandidates = [zRow findPivotableVariablesWithMostNegativeCoefficient];
    CSWVariable *entryVariable = nil;
    if ([entryVariableCandidates count] > 0) {
        entryVariable = entryVariableCandidates[0];
        if (preferredEntryVariable && [entryVariableCandidates containsObject:preferredEntryVariable]) {
            entryVariable = preferredEntryVariable;
        }
    }
    
    CSWDouble objectiveCoefficient = entryVariable != nil ? [zRow coefficientForTerm:entryVariable] : 0;
    while (objectiveCoefficient < -CSWEpsilon) {
        // choose which variable to move out of the basis
        // Only consider pivotable basic variables
        // (i.e. restricted, non-dummy variables)
        CSWVariable *exitVariable = [self findPivotableExitVariable:entryVariable tableau: tableau];
        [tableau pivotWithEntryVariable:entryVariable exitVariable:exitVariable];
        
        objectiveCoefficient = 0;
        
        NSArray *entryVariableCandidatesB = [zRow findPivotableVariablesWithMostNegativeCoefficient];
        if ([entryVariableCandidatesB count] > 0) {
            entryVariable = entryVariableCandidatesB[0];
        }
        if (entryVariable != nil) {
            objectiveCoefficient = [zRow coefficientForTerm:entryVariable];
        }
    }
}

- (CSWVariable*)findPivotableExitVariable:(CSWVariable *)entryVariable tableau: (CSWTableau*)tableau {
    CSWDouble minRatio = DBL_MAX;
    CSWDouble r = 0;
    CSWVariable *exitVariable = nil;
    for (CSWVariable *variable in [tableau columnForVariable: entryVariable]) {
        if ([variable isPivotable]) {
            CSWLinearExpression *expression = [tableau rowExpressionForVariable:variable];
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
    while ([_tableau hasInfeasibleRows]) {
        CSWVariable *exitVariable = [_tableau.infeasibleRows firstObject];
        [_tableau.infeasibleRows removeObject:exitVariable];
        
        CSWLinearExpression *exitVariableExpression = [_tableau rowExpressionForVariable:exitVariable];
        if (!exitVariableExpression) {
              continue;
        }
        // exitVar might have become basic after some other pivoting
        // so allow for the case of its not being there any longer
        if (exitVariableExpression.constant < 0)
        {
            CSWVariable *entryVariable = [self resolveDualOptimizePivotEntryVariableForExpression: exitVariableExpression];
            [_tableau pivotWithEntryVariable:entryVariable exitVariable:exitVariable];
        }
        
    }
}

- (CSWVariable*)resolveDualOptimizePivotEntryVariableForExpression:(CSWLinearExpression *)expression {
    CSWDouble ratio = DBL_MAX;
    CSWLinearExpression *zRow = [_tableau rowExpressionForVariable:_objective];
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
    for (CSWVariable *variable in _tableau.externalRows) {
        CSWDouble calculatedValue = [_tableau rowExpressionForVariable:variable].constant;
        if (calculatedValue != variable.value) {
            [variable setValue:calculatedValue];
        }
    }
    
    [_tableau.updatedExternals removeAllObjects];
    _needsSolving = false;
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
        if ([_tableau isBasicVariable:stayPlusErrorVariable]) {
            CSWLinearExpression *stayPlusErrorExpression = [_tableau rowExpressionForVariable:stayPlusErrorVariable];
            [stayPlusErrorExpression setConstant:0];
        }
        if ([_tableau isBasicVariable:stayMinusErrorVariable]) {
            CSWLinearExpression *stayMinusErrorExpression = [_tableau rowExpressionForVariable:stayMinusErrorVariable];
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
    CSWLinearExpression *objectiveRowExpression = [_tableau rowExpressionForVariable: _objective];

    NSArray *errorVariablesForConstraint = [_errorVariables objectForKey:constraint];
    for (CSWVariable *variable in errorVariablesForConstraint) {
        if (![_tableau isBasicVariable:variable]) {
            [_tableau addVariable:variable toExpression:objectiveRowExpression withCoefficient:-existingCoefficient subject:_objective];
            [_tableau addVariable:variable toExpression:objectiveRowExpression withCoefficient:newCoefficient subject:_objective];
        } else {
            CSWLinearExpression *expression = [[_tableau rowExpressionForVariable:variable] copy];
            [_tableau addNewExpression:expression toExpression:objectiveRowExpression n:-existingCoefficient subject:_objective];
            [_tableau addNewExpression:expression toExpression:objectiveRowExpression n:newCoefficient subject:_objective];
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
        [_tableau containsExternalRowForEachExternalRowVariable] &&
        [_tableau containsExternalParametricVariableForEveryExternalTerm];
}

- (void)removeEditVariable: (CSWVariable*)variable
{
    NSArray *editInfos = [self.editVariableManager editInfosForVariable:variable];
    if (editInfos.count == 0) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Edit variable not found" userInfo:nil] raise];
    }
    
    [self removeConstraint:[[editInfos firstObject] constraint]];
}

-(BOOL)isMultipleSolutions
{
    // First find an optimal solution for the tableau
    [self solve];
    
    // When a non basic pivotable variable (has a zero) in the objective row, this is a sign there are multiple solutions
    return [[_tableau substitedOutNonBasicPivotableVariables: _objective] count] > 0;
}

@end

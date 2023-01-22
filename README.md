#  CassowaryKit

CassowaryKit is an Objective C implementation of the constraint solving algoithm Cassowary. This project was inspired by Rhea. 

## Features

Solve alternative solutions if the constraints have multiple solutions

Debugging ultities - is variable ambigous, constraints affecting varible

Ease of use - CassowaryKit is designed to be easy to use and integrate into iOS, macOS and Linux applications. It provides a simple, intuitive interface for working with linear constraints and expressions, and includes a number of useful features and utilities.

Optimized for readability - The code is written in a clear and consistent style, and is well-documented with comments and other helpful information. This makes it easier for developers to understand how the algorithm works, and to modify or extend the library to suit their specific needs.

### Key differences from other implementations
- Deterministic - One of the key differences between CassowaryKit and other implementations of the Cassowary algorithm is that it is deterministic. This means that, given the same set of inputs, CassowaryKit will always produce the same output. In contrast, many other implementations of the Cassowary algorithm are non-deterministic, which means that they may produce different outputs for the same inputs.. This is achieved with expression term ordering and resolving conflicting slack variables using the order they were created. 
- Symbolic weight and constraint weight are combined into a single class `CSWStrength`
- A single constraint and variable class is used rather than using separate subclasses for each different subtype
- Logging is performed in a separate subclass `CSWSimplexSolverTracable`
- Returns a solution object when solving rather than modifying values of the variable objects. 

## How to

Check the test cases included with the repository for more examples.

### Solution solving
````objective-c
CSWSimplexSolver *solver = [[CSWSimplexSolver alloc] init];
// Add constraint x = 100 to solver
CSWVariable *x = [CSWVariable variableWithValue:10];
CSWConstraint *ieq = [CSWConstraint constraintWithLeftConstant:100 operator:CSWConstraintOperatorLessThanOrEqual rightVariable:x];
[solver addConstraint:ieq];

// Solve returns a solution object that has the calculated value for each variable
CSWSimplexSolverSolution *solution = [solver solve];
// Access the result using resultForVariable, this method returns NSNumber of the result
XCTAssertEqual([[solution resultForVariable: x] floatValue], 100);
````

## Debugging
The solver contains several utility functions to help with debugging under and over constrained solvers.

### Solving for all possible solutions
In this example, there are two constraints for X that have equal strength. X equals 10 or 20.
Using `[solver solveAll]` method will attempt to solve for all possible solutions by selecting different entry and exit pivots.
````objective-c
CSWVariable *x = [CSWVariable variable];

CSWConstraint *xEquals10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];
xEquals10.strength = [CSWStrength strengthWeak];

CSWConstraint *xEquals20 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:20];
xEquals20.strength = [CSWStrength strengthWeak];

[solver addConstraints:@[xEquals10, xEquals20]];

NSArray *solutions = [solver solveAll];
XCTAssertEqual([solutions count], 2);

XCTAssertEqual([[solutions[0] resultForVariable: x] floatValue], 20);
XCTAssertEqual([[solutions[1] resultForVariable: x] floatValue], 10);
````

### Testing for ambiguous variables
When a variable has multiple possible solutions, it is said to be ambiguous. If a system contains an ambiguous variable, the system is under constrained.
````objective-c
CSWVariable *x = [CSWVariable variable];
CSWVariable *y = [CSWVariable variable];
CSWLinearExpression *xRhs = [[CSWLinearExpression alloc] initWithVariable:y coefficient:1 constant:100];
CSWConstraint *constraint = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightExpression:xRhs];
[solver addConstraint: constraint];

XCTAssertTrue([solver isVariableAmbiguous: x]);
XCTAssertTrue([solver isVariableAmbiguous: y]);
````

### Constraints affecting variable
Use this to query solver for constraints affecting a given variable optimal solution  
````objective-c
CSWVariable *x = [CSWVariable variable];
CSWConstraint *xConstraint = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:100];
[solver addConstraint:xConstraint];

CSWVariable *y = [CSWVariable variable];
CSWConstraint *yConstraint = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightConstant:100];
[solver addConstraint:yConstraint];

NSArray *affectingConstraintsForX = [solver constraintsAffectingVariable:x];
XCTAssertEqual([affectingConstraintsForX count], 1);
XCTAssertEqual(affectingConstraintsForX[0], xConstraint);
````

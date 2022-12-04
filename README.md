#  CassowaryKit

CassowaryKit is an Objective C implementation of the constraint solving algoithm Cassowary. This project took heavy inspiration of Rhea. 

## Features

Ease of use - CassowaryKit is designed to be easy to use and integrate into iOS, macOS and Linux applications. It provides a simple, intuitive interface for working with linear constraints and expressions, and includes a number of useful features and utilities.

Optimized for readability - The code is written in a clear and consistent style, and is well-documented with comments and other helpful information. This makes it easier for developers to understand how the algorithm works, and to modify or extend the library to suit their specific needs.

### Key differences from other implementations
- Deterministic - One of the key differences between CassowaryKit and other implementations of the Cassowary algorithm is that it is deterministic. This means that, given the same set of inputs, CassowaryKit will always produce the same output. In contrast, many other implementations of the Cassowary algorithm are non-deterministic, which means that they may produce different outputs for the same inputs.. This is achieved with expression term ordering and resolving conflicting slack variables using the order they were created. 
- Symbolic weight and constraint weight are combined into a single class `CSWStrength`
- A single constraint and variable class is used rather than using separate subclasses for each different subtype
- Logging is performed in a separate subclass `CSWSimplexSolverTracable`

## How to

````
CSWSimplexSolver *solver = [[CSWSimplexSolver alloc] init];
CSWVariable *x = [CSWVariable variableWithValue:10];
CSWConstraint *ieq = [CSWConstraint constraintWithLeftConstant:100 operator:CSWConstraintOperatorLessThanOrEqual rightVariable:x];
[solver addConstraint:ieq];
[solver solve];

XCTAssertEqual(x.value, 100);
````

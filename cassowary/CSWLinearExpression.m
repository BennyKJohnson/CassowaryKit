
#import "CSWLinearExpression.h"
#import "CSWFloatComparator.h"
#import "CSWVariable.h"

@implementation CSWLinearExpression

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.terms = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
        self.termVariables = [NSMutableArray array];
        self.constant = 0;
    }
    return self;
}

-(instancetype)initWithVariable: (CSWAbstractVariable*)variable
{
    self = [self init];
    if (self) {
        [self addVariable:variable coefficient:1.0];
    }
    
    return self;
}

-(instancetype)initWithVariables: (NSArray*)variables
{
    self = [self init];
    if (self) {
        for (CSWVariable *variable in variables) {
            [self addVariable:variable coefficient:1.0];
        }
    }
    
    return self;
}

-(instancetype)initWithConstant: (CSWDouble)constant
{
    self = [self init];
    if (self) {
        self.constant = constant;
    }
    
    return self;
}

-(instancetype)initWithVariable: (CSWAbstractVariable*)variable coefficient: (CSWDouble)coefficient constant: (CSWDouble)constant
{
    self = [self init];
    if (self) {
        [self addVariable:variable coefficient:coefficient];
        self.constant = constant;
    }
    return self;
}

-(void)removeVariable: (nonnull CSWAbstractVariable*)variable
{
    [self.terms removeObjectForKey:variable];
    [self.termVariables removeObject:variable];
}

-(NSNumber*)multiplierForTerm: (CSWAbstractVariable*)variable
{
    return [self.terms objectForKey:variable];
}

-(CSWDouble)newSubject:(CSWAbstractVariable*)subject
{
    CSWDouble reciprocal = 1.0 / [self coefficientForTerm:subject];
    
    [self multiplyConstantAndTermsBy:-reciprocal];
    
    [self removeVariable:subject];
    return reciprocal;
}

-(void)multiplyConstantAndTermsBy: (CSWDouble)value
{
    self.constant = self.constant * value;
    
    NSMutableArray *keys = [NSMutableArray arrayWithCapacity:[self.terms count]];
    for (CSWAbstractVariable *term in self.terms) {
        [keys addObject:term];
    }
    
    for (CSWAbstractVariable *term in keys) {
        NSNumber *termCoefficent = [self.terms objectForKey:term];
        CSWDouble multipliedTermCoefficent = [termCoefficent doubleValue] * value;
        [self.terms setObject:[NSNumber numberWithDouble:multipliedTermCoefficent] forKey:term];
    }
}

-(void)divideConstantAndTermsBy: (CSWDouble)value
{
    [self multiplyConstantAndTermsBy: 1 / value];
}

-(CSWDouble)coefficientForTerm: (CSWAbstractVariable*)variable
{
    return [[self multiplierForTerm:variable] floatValue];
}

-(void)normalize
{
    [self multiplyConstantAndTermsBy:-1];
}

- (id)copyWithZone:(NSZone *)zone
{
    CSWLinearExpression *expression = [[[self class] allocWithZone:zone] init];
    if (expression) {
        [expression setConstant:[self constant]];
        for (CSWAbstractVariable *variable in self.termVariables) {
            [expression addVariable:variable coefficient:[self coefficientForTerm:variable]];
        }
    }
    
    return expression;
}

-(CSWAbstractVariable*)findPivotableVariableWithMostNegativeCoefficient
{
    CSWDouble mostNegativeCoefficient = 0;
    CSWAbstractVariable *candidate;
    
    for (CSWAbstractVariable *term in self.termVariables) {
        CSWDouble coefficientForTerm = [self coefficientForTerm:term];
        if ([term isPivotable] && coefficientForTerm < mostNegativeCoefficient) {
            mostNegativeCoefficient = coefficientForTerm;
            candidate = term;
        }
    }
    
    return candidate;
}

- (BOOL)isConstant
{
    return [self.terms count] == 0;
}

-(BOOL)isTermForVariable: (CSWAbstractVariable*)variable
{
    return [self.terms objectForKey:variable] != nil;
}

-(CSWAbstractVariable*)anyPivotableVariable
{
    if ([self isConstant]) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"anyPivotableVariable invoked on a constant expression" userInfo:nil] raise];
    }
    
    for (CSWAbstractVariable *variable in self.termVariables) {
        if ([variable isPivotable]) {
            return variable;
        }
    }
    
    return nil;
}

-(BOOL)containsOnlyDummyVariables
{
    for (CSWAbstractVariable *term in self.termVariables) {
        if (![term isDummy]) {
            return NO;
        }
    }
    
    return YES;
}

-(NSArray*)externalVariables
{
    NSMutableArray *externalVariables = [NSMutableArray array];
    for (CSWAbstractVariable *variable in self.terms) {
        if ([variable isExternal]) {
            [externalVariables addObject:variable];
        }
    }
    
    return externalVariables;
}

-(NSArray*)termKeys
{
    NSMutableArray *variables = [NSMutableArray array];
    for (CSWAbstractVariable *variable in self.terms) {
        [variables addObject:variable];
    }
    
    return variables;
}

-(void)addVariable: (CSWAbstractVariable*)variable
{
    [self addVariable:variable coefficient:1];
}


-(void)addVariable: (CSWAbstractVariable*)variable coefficient: (CSWDouble)coefficient;
{
    if (![CSWFloatComparator isApproxiatelyZero:coefficient]) {
        if ([self isTermForVariable:variable]) {
            [self.termVariables removeObject:variable];
        }
        [self.terms setObject:[NSNumber numberWithFloat:coefficient] forKey:variable];
        [self.termVariables addObject:variable];
    }
}

- (NSString *)description
{
    NSString *descriptionString = [NSString stringWithFormat:@"%f", self.constant];
    for (CSWVariable *term in self.termVariables) {
        descriptionString = [descriptionString stringByAppendingString:     [NSString stringWithFormat:@" + %f * %@", [self coefficientForTerm:term], [term description]]];
    }
    
    return descriptionString;
}

-(void)addExpression: (CSWLinearExpression*)expression{
    [self addExpression:expression multiplier:1];
}

-(void)addExpression: (CSWLinearExpression*)expression multiplier: (CSWDouble)multiplier
{
    [self setConstant:self.constant + expression.constant * multiplier];
  
     for (CSWAbstractVariable *term in [expression termKeys]) {
         CSWDouble termCoefficient = [expression coefficientForTerm:term] * multiplier;
         [self addVariable:term coefficient:termCoefficient];
     }
}

@end


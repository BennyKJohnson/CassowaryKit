
#import "CSWLinearExpression.h"
#import "CSWFloatComparator.h"
#import "CSWVariable.h"

@implementation CSWLinearExpression

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.terms = [NSMapTable strongToStrongObjectsMapTable];
        self.termVariables = [NSMutableArray array];
        self.constant = 0;
    }
    return self;
}

-(instancetype)initWithVariable: (CSWVariable*)variable
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

-(instancetype)initWithVariable: (CSWVariable*)variable coefficient: (CSWDouble)coefficient constant: (CSWDouble)constant
{
    self = [self init];
    if (self) {
        [self addVariable:variable coefficient:coefficient];
        self.constant = constant;
    }
    return self;
}

-(void)removeVariable: (nonnull CSWVariable*)variable
{
    [self.terms removeObjectForKey:variable];
    [self.termVariables removeObject:variable];
}

-(NSNumber*)multiplierForTerm: (CSWVariable*)variable
{
    return [self.terms objectForKey:variable];
}

-(CSWDouble)newSubject:(CSWVariable*)subject
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
    for (CSWVariable *term in self.terms) {
        [keys addObject:term];
    }
    
    for (CSWVariable *term in keys) {
        NSNumber *termCoefficent = [self.terms objectForKey:term];
        CSWDouble multipliedTermCoefficent = [termCoefficent doubleValue] * value;
        [self.terms setObject:[NSNumber numberWithDouble:multipliedTermCoefficent] forKey:term];
    }
}

-(void)divideConstantAndTermsBy: (CSWDouble)value
{
    [self multiplyConstantAndTermsBy: 1 / value];
}

-(CSWDouble)coefficientForTerm: (CSWVariable*)variable
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
        for (CSWVariable *variable in self.termVariables) {
            [expression addVariable:variable coefficient:[self coefficientForTerm:variable]];
        }
    }
    
    return expression;
}

-(NSArray*)findPivotableVariablesWithMostNegativeCoefficient
{
    CSWDouble mostNegativeCoefficient = 0;
    for (CSWVariable *term in self.termVariables) {
        CSWDouble coefficientForTerm = [self coefficientForTerm:term];
        if ([term isPivotable] && coefficientForTerm < mostNegativeCoefficient) {
            mostNegativeCoefficient = coefficientForTerm;
        }
    }
    
    NSMutableArray *candidates = [NSMutableArray array];
    for (CSWVariable *term in self.termVariables) {
        CSWDouble coefficientForTerm = [self coefficientForTerm:term];
        if ([term isPivotable] && [CSWFloatComparator isApproxiatelyEqual:coefficientForTerm b:mostNegativeCoefficient]) {
            [candidates addObject: term];
        }
    }
    
    return candidates;
}

- (BOOL)isConstant
{
    return [self.terms count] == 0;
}

-(BOOL)isTermForVariable: (CSWVariable*)variable
{
    return [self.terms objectForKey:variable] != nil;
}

-(CSWVariable*)anyPivotableVariable
{
    if ([self isConstant]) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"anyPivotableVariable invoked on a constant expression" userInfo:nil] raise];
    }
    
    for (CSWVariable *variable in self.termVariables) {
        if ([variable isPivotable]) {
            return variable;
        }
    }
    
    return nil;
}

-(BOOL)containsOnlyDummyVariables
{
    for (CSWVariable *term in self.termVariables) {
        if (![term isDummy]) {
            return NO;
        }
    }
    
    return YES;
}

-(NSArray*)externalVariables
{
    NSMutableArray *externalVariables = [NSMutableArray array];
    for (CSWVariable *variable in self.terms) {
        if ([variable isExternal]) {
            [externalVariables addObject:variable];
        }
    }
    
    return externalVariables;
}

-(void)addVariable: (CSWVariable*)variable
{
    [self addVariable:variable coefficient:1];
}

-(void)addVariable: (CSWVariable*)variable coefficient: (CSWDouble)coefficient;
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
  
     for (CSWVariable *term in [expression termVariables]) {
         CSWDouble termCoefficient = [expression coefficientForTerm:term] * multiplier;
         [self addVariable:term coefficient:termCoefficient];
     }
}

@end


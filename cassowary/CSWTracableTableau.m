//
//  CSWTracableTableau.m
//  cassowary
//
//  Created by Benjamin Johnson on 12/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import "CSWTracableTableau.h"

@implementation CSWTracableTableau

- (void)removeRowForVariable:(CSWAbstractVariable *)variable
{
    NSLog(@"removeRowForVariable: %@", variable);
    [super removeRowForVariable:variable];
}

- (void)addRowForVariable:(CSWAbstractVariable *)variable equalsExpression:(CSWLinearExpression *)expression
{
    NSLog(@"addRowForVariable: %@ equalsExpression: %@", variable, expression);
    [super addRowForVariable:variable equalsExpression:expression];
    
    NSLog(@"%@", [self description]);
}

- (void)substituteOutVariable:(CSWAbstractVariable *)variable forExpression:(CSWLinearExpression *)expression
{
    NSLog(@"substituteOutVariable: %@ forExpression: %@", variable, expression);
    [super substituteOutVariable:variable forExpression:expression];
}

-(void)substituteOutTerm: (CSWAbstractVariable*)term withExpression:(CSWLinearExpression*)newExpression inExpression: (CSWLinearExpression*)expression subject: (CSWAbstractVariable*)subject
{
    NSLog(@"substituteOutTerm: %@ withExpression: %@ inExpression: %@ subject: %@", term, newExpression, expression, subject);
    [super substituteOutTerm: term withExpression: newExpression inExpression: expression subject: subject];
}

@end

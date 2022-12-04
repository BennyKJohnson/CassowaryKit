#import "CSWEditInfo.h"

@implementation CSWEditInfo

-(instancetype)initWithVariable: (CSWVariable*)variable constraint: (CSWConstraint*)constraint plusVariable: (CSWVariable*)plusVariable minusVariable: (CSWVariable*)minusVariable previousConstant: (NSInteger)previousConstant
{
    self = [super init];
    if (self != nil) {
        self.variable = variable;
        self.plusVariable = plusVariable;
        self.minusVariable = minusVariable;
        self.constraint = constraint;
        self.previousConstant = previousConstant;
    }
    
    return self;
}

@end

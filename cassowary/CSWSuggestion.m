#import "CSWSuggestion.h"

@implementation CSWSuggestion

- (instancetype)initWithVariable: (CSWVariable*)variable value: (double)value
{
    self = [super init];
    if (self) {
        self.variable = variable;
        self.value = value;
    }
    return self;
}

@end

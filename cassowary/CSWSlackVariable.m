#import "CSWSlackVariable.h"

@implementation CSWSlackVariable

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.id = 0;
    }
    return self;
}

- (BOOL)isPivotable
{
    return YES;
}

- (BOOL)isRestricted
{
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@:slack]", self.name];
}

@end

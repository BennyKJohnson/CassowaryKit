#import "CSWDummyVariable.h"

@implementation CSWDummyVariable

-(BOOL)isDummy
{
    return YES;
}

- (BOOL)isRestricted
{
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@:dummy]", self.name];
}

@end

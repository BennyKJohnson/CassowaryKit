#import "CSWStrength.h"
#import "CSWFloatComparator.h"

@implementation CSWStrength

-(instancetype)initWithName: (NSString*)name strength: (double)strength;
{
    if (self = [super init]) {
        self.name = name;
        self.strength = strength;
    }
    return self;
}

+(instancetype)strengthRequired
{
    return [[CSWStrength alloc] initWithName:@"<Required>" strength:1000];
}

+(instancetype)strengthStrong
{
    return [[CSWStrength alloc] initWithName:@"strong" strength:750];
}

+(instancetype)strengthMedium
{
    return [[CSWStrength alloc] initWithName:@"medium" strength:500];
}

+(instancetype)strengthWeak
{
    return [[CSWStrength alloc] initWithName:@"weak" strength:250];
}

-(BOOL)isEqualToStrength: (CSWStrength*)strength
{
    return [self.name isEqual:strength.name] && [CSWFloatComparator isApproxiatelyEqual:self.strength b:strength.strength];
}

- (BOOL)isEqual:(id)other
{
    if (other == nil) {
        return NO;
    }
    
    if (other == self) {
        return YES;
    }
    
    return [self isEqualToStrength:other];
}

-(BOOL)isRequired
{
    return [CSWFloatComparator isApproxiatelyEqual:self.strength b:[[CSWStrength strengthRequired] strength]];
}

-(double)value
{
    return self.strength;
}

- (id)copyWithZone:(NSZone *)zone
{
    CSWStrength *copy = [[[self class] allocWithZone:zone] initWithName:self.name strength:self.strength];
    
    return copy;
}

@end

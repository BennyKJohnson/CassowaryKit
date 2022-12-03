#import "CSWVariable.h"

@implementation CSWVariable

-(instancetype)initWithValue: (CGFloat)value
{
    return [self initWithValue:value name:nil];
}

-(instancetype)initWithValue: (CGFloat)value name: (NSString*)name
{
    if (self = [super initWithName:name]) {
        self.value = value;
    }
    
    return self;
}

+(instancetype)variable
{
    return [[CSWVariable alloc] init];
}

- (BOOL)isEqual:(id)other
{
    if (![other isKindOfClass:[CSWVariable class]]) {
        return NO;
    }
    
    CSWVariable *otherVariable = (CSWVariable*)other;
    
    if (self.value != otherVariable.value) {
        return NO;
    }
    if (![self.name isEqual: otherVariable.name]) {
        return NO;
    }
    
    return YES;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithValue:self.value name:[self.name copyWithZone:zone]];
}

- (BOOL)isExternal
{
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@:%.02f]", self.name, self.value];
}

@end

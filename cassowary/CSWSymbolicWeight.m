#import "CSWSymbolicWeight.h"

@implementation CSWSymbolicWeight

-(instancetype)initWithLevelsCount: (NSUInteger)count
{
    if (self = [super init]) {
        self.levels = (CGFloat*)malloc(count * sizeof(CGFloat));
        self.levelCount = count;
        for (int i = 0; i < count;i++) {
            self.levels[i] = 0;
        }
    }
    
    return self;
}

-(instancetype)initWithLevels: (NSArray*)levels
{
    if (self = [super init]) {
        self.levels = (CGFloat*)malloc([levels count] * sizeof(CGFloat));
        self.levelCount = [levels count];
        for (int i = 0; i < [levels count];i++) {
            self.levels[i] = [[levels objectAtIndex:i] doubleValue];
        }
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    CSWSymbolicWeight *copy = [[[self class] allocWithZone:zone] initWithLevelsCount:_levelCount];
    
    for (int i = 0; i < self.levelCount;i++) {
        copy.levels[i] = self.levels[i];
    }
        
    return copy;
}

-(BOOL)isEqualToSymbolicWeight: (CSWSymbolicWeight*)weight
{
    if (self.levelCount != weight.levelCount) {
        return NO;
    }
    
    for (int i = 0;i < [self levelCount];i++) {
        if (self.levels[i] != weight.levels[i]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)isEqual:(id)other
{
    if (other == nil) {
        return NO;
    }
    if (self == other) {
        return YES;
    }
    
    return [self isEqualToSymbolicWeight:other];
}

-(double)value
{
    double sum = 0;
    double factor = 1;
    double multiplier = 1000;
    
    for (NSInteger i = self.levelCount - 1;i >= 0;i--) {
        sum += self.levels[i] * factor;
        factor *= multiplier;
    }
    
    return sum;
}

- (void)dealloc
{
    free(self.levels);
}

@end

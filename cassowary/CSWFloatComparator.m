#import "CSWFloatComparator.h"
#import "CSWEpsilon.h"

@implementation CSWFloatComparator

const float CSWEpsilon = 1.0e-8;

+(BOOL)isApproxiatelyEqual: (CGFloat)a b: (CGFloat)b
{
    BOOL result = fabs (a - b) <= CSWEpsilon;
    return result;
}

+(BOOL)isApproxiatelyZero: (CGFloat)value
{
    return [self isApproxiatelyEqual:value b:0];
}

@end

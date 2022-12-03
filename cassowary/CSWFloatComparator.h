#import <Foundation/Foundation.h>

extern const float CSWEpsilon;

NS_ASSUME_NONNULL_BEGIN

@interface CSWFloatComparator : NSObject

+(BOOL)isApproxiatelyEqual: (CGFloat)a b: (CGFloat)b;

+(BOOL)isApproxiatelyZero: (CGFloat)value;

@end

NS_ASSUME_NONNULL_END

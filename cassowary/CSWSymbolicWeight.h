#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSWSymbolicWeight : NSObject <NSCopying>

@property CGFloat *levels;

@property NSInteger levelCount;

-(instancetype)initWithLevelsCount: (NSUInteger)count;

-(instancetype)initWithLevels: (NSArray*)levels;

-(BOOL)isEqualToSymbolicWeight: (CSWSymbolicWeight*)weight;

-(double)value;

@end

NS_ASSUME_NONNULL_END

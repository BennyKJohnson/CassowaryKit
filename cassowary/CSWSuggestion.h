#import <Foundation/Foundation.h>
#import "CSWVariable.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWSuggestion : NSObject

@property (nonatomic, strong) CSWVariable *variable;

@property double value;

- (instancetype)initWithVariable: (CSWVariable*)variable value: (double)value;

@end

NS_ASSUME_NONNULL_END

#import "CSWVariable.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWVariable (PrivateMethods)

+(instancetype)dummyVariableWithName: (NSString*)name;

+(instancetype)slackVariableWithName: (NSString*)name;

+(instancetype)objectiveVariableWithName: (NSString*)name;

@end

NS_ASSUME_NONNULL_END

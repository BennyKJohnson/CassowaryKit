#import <Foundation/Foundation.h>
#import "CSWEditInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWEditVariableManager : NSObject
{
    NSMutableArray *_editVariablesList;
    NSMutableArray *_editVariablesStack;
    NSMapTable *_editVariablesMap;
}

-(NSArray*)editInfos;

-(BOOL)isEmpty;

-(void)addEditInfo: (CSWEditInfo*)editInfo;

-(void)removeEditInfo: (CSWEditInfo*)editInfo;

-(CSWEditInfo*)editInfoForConstraint: (CSWConstraint*)constraint;

-(NSArray*)editInfosForVariable: (CSWAbstractVariable*)editVariable;

-(void)removeEditInfoForConstraint: (CSWConstraint*)constraint;

-(void)pushEditVariableCount;

-(NSInteger)topEditVariableStack;

-(NSInteger)editVariableStackCount;

-(NSArray*)getNextSet;

@end

NS_ASSUME_NONNULL_END

#import "CSWEditVariableManager.h"

@implementation CSWEditVariableManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _editVariablesList = [NSMutableArray array];
        _editVariablesStack = [NSMutableArray array];
        _editVariablesMap = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
        valueOptions:NSMapTableStrongMemory];
        [self pushEditVariableCount];
    }
    return self;
}

-(BOOL)isEmpty
{
    return _editVariablesList.count == 0;
}

-(NSArray*)editInfos
{
    return _editVariablesList;
}

-(NSInteger)editVariableStackCount
{
    return _editVariablesStack.count;
}

-(NSInteger)topEditVariableStack
{
    return [_editVariablesStack.lastObject integerValue];
}

-(void)pushEditVariableCount
{
    [_editVariablesStack addObject:[NSNumber numberWithInteger:[_editVariablesList count]]];
}

-(void)popEditVariableStack
{
    [_editVariablesStack removeLastObject];
}

-(void)addEditInfo: (CSWEditInfo*)editInfo
{
    [_editVariablesMap setObject:editInfo forKey:editInfo.variable];
    [_editVariablesList addObject:editInfo];
}

-(void)removeEditInfo: (CSWEditInfo*)editInfo
{
    [_editVariablesList removeObject:editInfo];
}

-(void)removeEditInfoForConstraint: (CSWConstraint*)constraint
{
    CSWEditInfo *editInfo = [self editInfoForConstraint:constraint];
    [self removeEditInfo:editInfo];
}

-(CSWEditInfo*)editInfoForConstraint: (CSWConstraint*)constraint
{
    for (CSWEditInfo *editInfo in _editVariablesList) {
        if (editInfo.constraint == constraint) {
            return editInfo;
        }
    }
    return nil;
}

-(NSArray*)editInfosForVariable: (CSWAbstractVariable*)editVariable
{
    NSMutableArray *editInfos = [NSMutableArray array];
    for (CSWEditInfo *editInfo in _editVariablesList) {
        if (editInfo.variable == editVariable) {
            [editInfos addObject:editInfo];
        }
    }
    
    return editInfos;
}

-(NSArray*)getNextSet
{
    [_editVariablesStack removeLastObject];
    NSInteger index = [self topEditVariableStack];
    NSInteger count = _editVariablesList.count;
    NSMutableArray *editableInfosInDescendingOrder = [NSMutableArray array];
    while (count > index) {
        [editableInfosInDescendingOrder addObject: self.editInfos[count - 1]];
        count--;
    }
    
    return editableInfosInDescendingOrder;
}

@end

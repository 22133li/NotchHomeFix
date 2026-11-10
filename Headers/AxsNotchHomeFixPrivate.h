#pragma once

#import <Foundation/Foundation.h>

@interface SBFullScreenToHomeIconZoomSwitcherModifier : NSObject
- (BOOL)_isEffectivelyHome;
- (BOOL)_isIndexZoomAppLayout:(id)layout;
- (void)transitionWillBegin;
- (void)transitionDidEnd;
- (void)interruptAndEndTransition;
@end

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "AxsNotchHomeFixConfig.h"
#import "AxsNotchHomeFixPrivate.h"

static const void *AxsNotchHomeFixTransitionDepthKey = &AxsNotchHomeFixTransitionDepthKey;

static BOOL axs_notchhomefix_enabled(void) {
    return [[AxsNotchHomeFixConfig axs_notchhomefix_shared] axs_notchhomefix_isEnabled];
}

static NSUInteger axs_notchhomefix_transitionDepth(id object) {
    return [objc_getAssociatedObject(object, AxsNotchHomeFixTransitionDepthKey) unsignedIntegerValue];
}

static void axs_notchhomefix_setTransitionDepth(id object, NSUInteger depth) {
    objc_setAssociatedObject(object, AxsNotchHomeFixTransitionDepthKey,
                             depth ? @(depth) : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%hook SBFullScreenToHomeIconZoomSwitcherModifier

- (void)transitionWillBegin {
    if (axs_notchhomefix_enabled()) {
        axs_notchhomefix_setTransitionDepth(self, axs_notchhomefix_transitionDepth(self) + 1);
    }
    %orig;
}

- (void)transitionDidEnd {
    %orig;
    NSUInteger depth = axs_notchhomefix_transitionDepth(self);
    axs_notchhomefix_setTransitionDepth(self, depth > 1 ? depth - 1 : 0);
}

- (void)interruptAndEndTransition {
    %orig;
    axs_notchhomefix_setTransitionDepth(self, 0);
}

- (BOOL)_isEffectivelyHome {
    if (axs_notchhomefix_enabled()) {
        return YES;
    }
    return %orig;
}

- (BOOL)_isIndexZoomAppLayout:(id)layout {
    if (axs_notchhomefix_enabled()) {
        return YES;
    }
    return %orig(layout);
}

%end

%ctor {
    @autoreleasepool {
        [AxsNotchHomeFixConfig axs_notchhomefix_shared];
    }
}

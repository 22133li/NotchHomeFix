#import "AxsNotchHomeFixConfig.h"
#import "AxsNotchHomeFixPreferences.h"

@interface AxsNotchHomeFixConfig ()
@property (atomic, copy) NSDictionary *snapshot;
@property (nonatomic, strong) dispatch_queue_t reloadQueue;
@property (nonatomic, assign) BOOL disabledByOriginalMarker;
@end

static void axs_notchhomefix_preferencesDidChange(CFNotificationCenterRef center, void *observer,
                                          CFStringRef name, const void *object, CFDictionaryRef info) {
    AxsNotchHomeFixConfig *config = (__bridge AxsNotchHomeFixConfig *)observer;
    dispatch_async(config.reloadQueue, ^{
        [config axs_notchhomefix_reload];
    });
}

@implementation AxsNotchHomeFixConfig

+ (instancetype)axs_notchhomefix_shared {
    static AxsNotchHomeFixConfig *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _reloadQueue = dispatch_queue_create("com.axs.notchhomefix.preferences", DISPATCH_QUEUE_SERIAL);
        _disabledByOriginalMarker = [[NSFileManager defaultManager]
            fileExistsAtPath:@"/var/mobile/Library/Logs/NotchHome/disable-repair"];
        [self axs_notchhomefix_reload];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)self, axs_notchhomefix_preferencesDidChange,
            (__bridge CFStringRef)AxsNotchHomeFixPreferencesChanged, NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        // Close the window between the first read and observer registration.
        dispatch_async(_reloadQueue, ^{ [self axs_notchhomefix_reload]; });
    }
    return self;
}

- (void)axs_notchhomefix_reload {
    self.snapshot = axs_notchhomefix_readPreferences();
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:AxsNotchHomeFixPreferencesChanged object:self];
    });
}

- (id)axs_notchhomefix_valueForKey:(NSString *)key defaultValue:(id)defaultValue {
    return self.snapshot[key] ?: defaultValue;
}

- (BOOL)axs_notchhomefix_isEnabled {
    if (self.disabledByOriginalMarker) {
        return NO;
    }
    id value = [self axs_notchhomefix_valueForKey:@"enabled" defaultValue:@(YES)];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : YES;
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            (__bridge const void *)self);
}

@end

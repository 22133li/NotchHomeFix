#pragma once

#import <Foundation/Foundation.h>

@interface AxsNotchHomeFixConfig : NSObject
+ (instancetype)axs_notchhomefix_shared;
- (BOOL)axs_notchhomefix_isEnabled;
- (id)axs_notchhomefix_valueForKey:(NSString *)key defaultValue:(id)defaultValue;
- (void)axs_notchhomefix_reload;
@end

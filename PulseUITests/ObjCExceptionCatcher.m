#import "ObjCExceptionCatcher.h"

@implementation ObjCExceptionCatcher

+ (BOOL)tryBlock:(void (NS_NOESCAPE ^)(void))block {
    @try {
        block();
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
}

+ (BOOL)tryBoolBlock:(BOOL (NS_NOESCAPE ^)(void))block fallback:(BOOL)fallback {
    @try {
        return block();
    } @catch (NSException *exception) {
        return fallback;
    }
}

@end

#import "ObjCExceptionCatcher.h"
#import <dispatch/dispatch.h>

@implementation ObjCExceptionCatcher

+ (BOOL)safeExistsForElement:(XCUIElement *)element {
    // Run .exists on a background thread with a timeout to prevent hangs.
    // When XCTest's accessibility framework is overloaded on slow CI runners,
    // a single .exists call can block for 30+ seconds before throwing a C++ exception.
    __block BOOL result = NO;
    __block BOOL finished = NO;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @try {
            result = element.exists;
        } @catch (...) {
            result = NO;
        }
        finished = YES;
        dispatch_semaphore_signal(semaphore);
    });

    // Wait at most 5 seconds for the .exists check to complete.
    // If it takes longer, the accessibility framework is unresponsive — return NO.
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));

    return finished ? result : NO;
}

+ (void)safeTapElement:(XCUIElement *)element {
    @try {
        XCUICoordinate *center = [element coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
        [center tap];
    } @catch (...) {
        // Tap failed due to C++ exception — element may not be interactive
    }
}

+ (BOOL)safeTapIfExists:(XCUIElement *)element {
    @try {
        if (!element.exists) return NO;
        XCUICoordinate *center = [element coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
        [center tap];
        return YES;
    } @catch (...) {
        return NO;
    }
}

+ (NSInteger)safeCountForQuery:(XCUIElementQuery *)query {
    @try {
        return (NSInteger)query.count;
    } @catch (...) {
        return 0;
    }
}

@end

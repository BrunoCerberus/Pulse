#import "ObjCExceptionCatcher.h"

@implementation ObjCExceptionCatcher

+ (BOOL)safeExistsForElement:(XCUIElement *)element {
    // Wrap .exists in @try/@catch on the calling thread (main thread for UI tests).
    // XCUIElement APIs are NOT thread-safe and must run on the main thread.
    // The @try/@catch catches C++ exceptions from Xcode 26's accessibility framework
    // ("Timed out while evaluating UI query") before they reach the Swift runtime.
    @try {
        return element.exists;
    } @catch (...) {
        return NO;
    }
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

+ (void)safeTerminateApp:(XCUIApplication *)app {
    @try {
        [app terminate];
    } @catch (...) {
        // "Failed to terminate" throws C++ exception — swallow it
    }
}

+ (BOOL)safeWaitForApp:(XCUIApplication *)app state:(XCUIApplicationState)state timeout:(NSTimeInterval)timeout {
    @try {
        return [app waitForState:state timeout:timeout];
    } @catch (...) {
        return NO;
    }
}

+ (void)safeSetDeviceOrientation:(UIDeviceOrientation)orientation {
    @try {
        XCUIDevice.sharedDevice.orientation = orientation;
    } @catch (...) {
        // Orientation reset failed — runner may be in a bad state after a C++ exception
    }
}

+ (void)safeLongPressElement:(XCUIElement *)element duration:(NSTimeInterval)duration {
    @try {
        XCUICoordinate *center = [element coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
        [center pressForDuration:duration];
    } @catch (...) {
        // Long press failed due to C++ exception — element may not be interactive
    }
}

+ (void)safeSwipeLeftEdge:(XCUIApplication *)app {
    // Use coordinate-based drag from left edge to trigger back navigation.
    // Unlike app.swipeRight(), this does NOT evaluate the full accessibility tree,
    // so it cannot hang when the accessibility framework is degraded on Xcode 26.
    @try {
        XCUICoordinate *start = [app coordinateWithNormalizedOffset:CGVectorMake(0.01, 0.5)];
        XCUICoordinate *end = [app coordinateWithNormalizedOffset:CGVectorMake(0.6, 0.5)];
        [start pressForDuration:0 thenDragToCoordinate:end];
    } @catch (...) {
        // Swipe gesture failed due to C++ exception — skip back navigation
    }
}

+ (void)safeTapAppAtNormalizedX:(CGFloat)x y:(CGFloat)y app:(XCUIApplication *)app {
    @try {
        XCUICoordinate *target = [app coordinateWithNormalizedOffset:CGVectorMake(x, y)];
        [target tap];
    } @catch (...) {
        // Tap failed due to C++ exception
    }
}

@end

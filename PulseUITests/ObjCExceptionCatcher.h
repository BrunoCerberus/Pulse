#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

/// Wraps XCTest element queries in ObjC++ @try/@catch to catch C++ exceptions
/// that Xcode 26 throws ("Timed out while evaluating UI query"). These exceptions
/// crash the Swift runtime with SIGABRT because Swift doesn't support C++ exceptions.
///
/// By performing the actual XCTest API calls in ObjC++ code (not in Swift closures),
/// the C++ exception is thrown and caught entirely within the ObjC++ stack frame.
@interface ObjCExceptionCatcher : NSObject

/// Checks element.exists, catching any C++ exception. Returns NO on exception.
+ (BOOL)safeExistsForElement:(XCUIElement *)element;

/// Taps an element using coordinate-based tap, catching any C++ exception.
+ (void)safeTapElement:(XCUIElement *)element;

/// Checks element.exists and taps if it exists. Returns whether the tap happened.
+ (BOOL)safeTapIfExists:(XCUIElement *)element;

/// Returns query.count, catching any C++ exception. Returns 0 on exception.
+ (NSInteger)safeCountForQuery:(XCUIElementQuery *)query;

/// Terminates an application, catching any C++ exception from "Failed to terminate".
+ (void)safeTerminateApp:(XCUIApplication *)app;

/// Waits for app to reach a given state, catching any C++ exception. Returns NO on exception.
+ (BOOL)safeWaitForApp:(XCUIApplication *)app state:(XCUIApplicationState)state timeout:(NSTimeInterval)timeout;

/// Sets device orientation, catching any C++ exception that may occur when the runner is in a bad state.
+ (void)safeSetDeviceOrientation:(UIDeviceOrientation)orientation;

/// Long-presses an element for a given duration, catching any C++ exception.
+ (void)safeLongPressElement:(XCUIElement *)element duration:(NSTimeInterval)duration;

/// Performs a left-edge swipe-back gesture using normalized coordinates, catching any C++ exception.
/// Use this instead of app.swipeRight() to avoid Xcode 26 accessibility query hangs.
/// app.swipeRight() evaluates the full accessibility tree and can hang for 30+ minutes
/// when the accessibility framework is degraded. Coordinate-based gestures bypass this.
+ (void)safeSwipeLeftEdge:(XCUIApplication *)app;

@end

NS_ASSUME_NONNULL_END

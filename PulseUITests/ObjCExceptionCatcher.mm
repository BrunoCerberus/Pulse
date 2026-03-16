#import "ObjCExceptionCatcher.h"

@implementation ObjCExceptionCatcher

+ (BOOL)safeExistsForElement:(XCUIElement *)element {
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

@end

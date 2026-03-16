#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Catches Objective-C and C++ exceptions that would otherwise crash the Swift runtime.
/// Xcode 26's XCTest accessibility queries can throw C++ exceptions ("Timed out while
/// evaluating UI query") which Swift cannot catch, causing SIGABRT.
@interface ObjCExceptionCatcher : NSObject

/// Executes a block and catches any ObjC/C++ exception.
/// Returns YES if the block executed without throwing, NO otherwise.
+ (BOOL)tryBlock:(void (NS_NOESCAPE ^)(void))block;

/// Executes a block that returns a BOOL, catching any ObjC/C++ exception.
/// Returns the block's return value, or the fallback value if an exception was caught.
+ (BOOL)tryBoolBlock:(BOOL (NS_NOESCAPE ^)(void))block fallback:(BOOL)fallback;

@end

NS_ASSUME_NONNULL_END

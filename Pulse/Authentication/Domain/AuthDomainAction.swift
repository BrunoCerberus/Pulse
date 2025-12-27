import UIKit

enum AuthDomainAction {
    case signInWithGoogle(presenting: UIViewController)
    case signInWithApple
    case signOut
    case clearError
}

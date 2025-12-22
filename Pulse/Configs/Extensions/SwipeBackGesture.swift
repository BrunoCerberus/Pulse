import SwiftUI
import UIKit

struct SwipeBackGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> UIViewController {
        SwipeBackGestureViewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

private final class SwipeBackGestureViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
}

extension View {
    func enableSwipeBack() -> some View {
        background(SwipeBackGestureEnabler())
    }
}

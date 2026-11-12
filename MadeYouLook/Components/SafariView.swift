import SwiftUI
import SafariServices

/// Identifiable wrapper so a URL can drive `.fullScreenCover(item:)`.
struct WebLink: Identifiable {
    let id = UUID()
    let url: URL
}

/// In-app browser (Safari engine) used for "Buy at Sephora" so people stay inside the app.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(Theme.primary)
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

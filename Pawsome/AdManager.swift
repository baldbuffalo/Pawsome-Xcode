import SwiftUI

#if os(iOS)
import GoogleMobileAds
import UIKit
#elseif os(macOS)
import WebKit
import AppKit
#endif

// MARK: - AdManager
final class AdManager: ObservableObject {
    static let shared = AdManager()

    enum AppScreen {
        case home, scan, profile, form, other
    }

    @Published var currentScreen: AppScreen = .home

    private init() {}

    var shouldShowAd: Bool {
        currentScreen != .form
    }

    // MARK: - GLOBAL OVERLAY
    var overlay: some View {
        VStack {
            Spacer()

            if shouldShowAd {
                BannerAdView()
                    .frame(height: 90)
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: shouldShowAd)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Banner Wrapper
struct BannerAdView: View {
    var body: some View {
        #if os(iOS)
        AdMobBannerView()
        #elseif os(macOS)
        WebAdBannerView()
        #endif
    }
}

//
// MARK: - iOS (REAL ADMOB)
//
#if os(iOS)

struct AdMobBannerView: UIViewRepresentable {

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)

        // 🔥 REPLACE WITH YOUR REAL ADMOB BANNER ID
        banner.adUnitID = "ca-app-pub-1515384434837305/7343539401"

        banner.rootViewController =
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?
                .rootViewController

        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

#endif

//
// MARK: - macOS (WEB BANNER ADS)
//
#if os(macOS)

struct WebAdBannerView: NSViewRepresentable {

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()

        // Transparent background fix
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.clear.cgColor
        webView.setValue(false, forKey: "drawsBackground") // optional, works for older versions

        let html = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin:0;padding:0;background:transparent;">
            <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
            <ins class="adsbygoogle"
                 style="display:block"
                 data-ad-client="ca-pub-1515384434837305"
                 data-ad-slot="7343539401"
                 data-ad-format="auto"
                 data-full-width-responsive="true"></ins>
            <script>
                (adsbygoogle = window.adsbygoogle || []).push({});
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

#endif

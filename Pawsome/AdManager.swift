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
        WebAdBannerView(adManager: AdManager.shared)
        #endif
    }
}

//
// MARK: - iOS (REAL ADMOB — UNCHANGED)
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
// MARK: - macOS (WKWEBVIEW BANNER ADS — reload on view change)
//
#if os(macOS)

struct WebAdBannerView: NSViewRepresentable {
    @ObservedObject var adManager: AdManager

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.clear.cgColor
        webView.setValue(false, forKey: "drawsBackground")

        loadAd(webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Reload the ad only when the screen changes
        if context.coordinator.lastScreen != adManager.currentScreen {
            loadAd(webView)
            context.coordinator.lastScreen = adManager.currentScreen
        }
    }

    private func loadAd(_ webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html, body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    width: 100%;
                    display: flex;
                    justify-content: center;
                    align-items: flex-end;
                }
                .adsbygoogle {
                    display: block;
                    width: 100%;
                    max-width: 728px;
                    height: 90px;
                }
            </style>
            <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
        </head>
        <body>
            <ins class="adsbygoogle"
                 data-ad-client="ca-pub-1515384434837305"
                 data-ad-slot="7343539401"
                 data-ad-format="auto"
                 style="width:100%; height:90px;">
            </ins>
            <script>
                (adsbygoogle = window.adsbygoogle || []).push({});
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://googleads.g.doubleclick.net"))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(lastScreen: adManager.currentScreen)
    }

    class Coordinator {
        var lastScreen: AdManager.AppScreen
        init(lastScreen: AdManager.AppScreen) {
            self.lastScreen = lastScreen
        }
    }
}

#endif

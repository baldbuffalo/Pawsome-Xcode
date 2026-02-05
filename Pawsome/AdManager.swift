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

    // ❌ Form screen has no ads
    var hideAds: Bool {
        currentScreen == .form
    }

    func updateCurrentScreen(
        selectedTab: Int,
        activeHomeFlow: PawsomeApp.HomeFlow?
    ) {
        if activeHomeFlow == .form {
            currentScreen = .form
        } else {
            currentScreen = .other
        }
    }

    // MARK: - GLOBAL OVERLAY (Sides Only)
    var overlay: some View {
        HStack {
            if !hideAds {
                BannerAdView()
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .leading))
                
                Spacer()
                
                BannerAdView()
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hideAds)
        .ignoresSafeArea()
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
// MARK: - iOS (ADMOB)
//
#if os(iOS)

struct AdMobBannerView: UIViewRepresentable {
    private var adUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        return "ca-app-pub-1515384434837305/7343539401"
        #endif
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
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
// MARK: - macOS (WKWebView Banner)
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
        if context.coordinator.lastScreen != adManager.currentScreen {
            loadAd(webView)
            context.coordinator.lastScreen = adManager.currentScreen
        }
    }

    private func loadAd(_ webView: WKWebView) {
        let adClient: String
        let adSlot: String
        #if DEBUG
        adClient = "ca-pub-3940256099942544"
        adSlot = "6300978111"
        #else
        adClient = "ca-pub-1515384434837305"
        adSlot = "7343539401"
        #endif

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
                    height: 100%;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                }
                .adsbygoogle {
                    display: block;
                    width: 100%;
                    height: 90px;
                }
            </style>
            <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
        </head>
        <body>
            <ins class="adsbygoogle"
                 data-ad-client="\(adClient)"
                 data-ad-slot="\(adSlot)"
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

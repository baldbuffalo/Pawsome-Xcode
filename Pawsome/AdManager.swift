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

    private var sideAdWidth: CGFloat {
        #if os(macOS)
        return 180
        #else
        return 80
        #endif
    }

    // MARK: - GLOBAL OVERLAY (Sides Only)
    var overlay: some View {
        return HStack {
            if !hideAds {
                BannerAdView()
                    .frame(width: sideAdWidth)
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .leading))
                
                Spacer()
                
                BannerAdView()
                    .frame(width: sideAdWidth)
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: hideAds)
        .ignoresSafeArea()
        .zIndex(1000)
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
        return "ca-app-pub-3940256099942544/2435281174"
        #else
        return "ca-app-pub-1515384434837305/7343539401"
        #endif
    }

    func makeUIView(context: Context) -> BannerView {
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["SIMULATOR"]
        #endif

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
        #if DEBUG
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html, body {
                    margin: 0;
                    padding: 0;
                    background: #111827;
                    width: 100%;
                    height: 100%;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    color: white;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
                .test-ad {
                    width: calc(100% - 16px);
                    height: 90px;
                    border-radius: 10px;
                    border: 2px dashed #60a5fa;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    font-weight: 700;
                    background: linear-gradient(90deg, #2563eb, #9333ea);
                }
            </style>
        </head>
        <body>
            <div class="test-ad">TEST AD (DEBUG)</div>
        </body>
        </html>
        """
        #else
        let adClient = "ca-pub-1515384434837305"
        let adSlot = "7343539401"

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
        #endif

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

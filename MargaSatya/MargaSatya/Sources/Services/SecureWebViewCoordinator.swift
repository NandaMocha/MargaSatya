//
//  SecureWebViewCoordinator.swift
//  MargaSatya
//
//  Secure Exam Browser - iOS
//

import Foundation
import WebKit
import SwiftUI

/// Coordinator for managing secure WebView
class SecureWebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: SecureWebView
    var onComplete: (() -> Void)?
    var shouldReload = false
    private var lastReloadTrigger = false

    init(_ parent: SecureWebView, onComplete: (() -> Void)? = nil) {
        self.parent = parent
        self.onComplete = onComplete
        self.lastReloadTrigger = parent.reloadTrigger
    }

    func checkReloadTrigger() {
        if parent.reloadTrigger != lastReloadTrigger {
            shouldReload = true
            lastReloadTrigger = parent.reloadTrigger
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // Only allow Google Forms domain
        let allowedHosts = ["docs.google.com", "accounts.google.com"]

        if let host = url.host {
            if allowedHosts.contains(where: { host.contains($0) }) {
                decisionHandler(.allow)
                return
            }
        }

        // Block external apps and schemes
        let blockedSchemes = ["mailto", "tel", "sms", "facetime", "itms-apps"]
        if let scheme = url.scheme, blockedSchemes.contains(scheme) {
            decisionHandler(.cancel)
            return
        }

        // For http/https, only allow whitelisted domains
        if url.scheme == "http" || url.scheme == "https" {
            if let host = url.host, allowedHosts.contains(where: { host.contains($0) }) {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        } else {
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        parent.isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        parent.isLoading = false

        // Disable text selection and context menu
        let disableScript = """
        var style = document.createElement('style');
        style.innerHTML = `
            * {
                -webkit-user-select: none !important;
                -webkit-touch-callout: none !important;
                user-select: none !important;
            }
            input, textarea {
                -webkit-user-select: text !important;
                user-select: text !important;
            }
        `;
        document.head.appendChild(style);

        document.addEventListener('contextmenu', function(e) {
            e.preventDefault();
        }, false);

        document.addEventListener('copy', function(e) {
            // Allow copy within form inputs
        }, false);
        """

        webView.evaluateJavaScript(disableScript, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        parent.isLoading = false
        parent.loadError = error.localizedDescription
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, with error: Error) {
        parent.isLoading = false
        parent.loadError = error.localizedDescription
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Prevent opening new windows/tabs
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        // Handle JavaScript alerts from Google Forms
        completionHandler()
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        // Handle JavaScript confirms
        completionHandler(true)
    }
}

// MARK: - SecureWebView SwiftUI Wrapper
struct SecureWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: String?
    @Binding var reloadTrigger: Bool
    var onComplete: (() -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        // Create private data store (no caching)
        let dataStore = WKWebsiteDataStore.nonPersistent()

        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.bounces = false

        // Disable magnification
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Check if reload was triggered
        context.coordinator.checkReloadTrigger()

        // Load initially or when reload is triggered
        if webView.url == nil || context.coordinator.shouldReload {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            webView.load(request)
            context.coordinator.shouldReload = false
        }
    }

    func makeCoordinator() -> SecureWebViewCoordinator {
        SecureWebViewCoordinator(self, onComplete: onComplete)
    }
}

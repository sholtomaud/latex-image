// Minimal service worker — exists only to satisfy the PWA installability
// requirement. We do NOT intercept any fetches here because OpenVSCode Server
// registers its own service worker that proxies extension resources and
// webview content. Intercepting those requests breaks the PDF viewer and
// other extension webviews.
self.addEventListener("install",  () => self.skipWaiting());
self.addEventListener("activate", () => self.clients.claim());

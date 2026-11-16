# Architecture

How `flutter-sandbox-template` is put together — the layer map, the reasoning behind each decision, and the two ways the web build gets served.

## Layer map

```
main.dart
  └── SandboxApp (app.dart) — owns AppSettings
        ├── state/app_settings.dart
        │     └── AppSettings extends ChangeNotifier
        │           └── themeMode: system | light | dark  (+ toggleBrightness)
        ├── theme.dart — SandboxTheme
        │     └── ColorScheme.fromSeed(seed Color(0xFF0D9488)) → light + dark ThemeData
        └── MaterialApp (inside a ListenableBuilder listening to AppSettings)
              ├── themeAnimationDuration: 250 ms
              └── AdaptiveShell (widgets/adaptive_scaffold.dart)
                    └── LayoutBuilder — maxWidth >= 840 dp?
                          ├── no  → Scaffold + bottom NavigationBar
                          └── yes → Scaffold + Row[ NavigationRail | VerticalDivider | body ]
                                └── IndexedStack — keeps every tab's state alive
                                      ├── HomeScreen (screens/home_screen.dart)
                                      │     └── interactive counter + theme toggle (AppBar action)
                                      ├── ExploreScreen (screens/explore_screen.dart)
                                      │     └── ListView.builder ← data/features.dart (kFeatures)
                                      │           └── onTap → ScaffoldMessenger SnackBar
                                      └── SettingsScreen (screens/settings_screen.dart)
                                            └── SegmentedButton<ThemeMode> ← AppSettings
```

Data flows one way: `AppSettings` (the only mutable state) calls `notifyListeners()` → the `ListenableBuilder` at the root rebuilds `MaterialApp` → the new `themeMode` animates in. Screens receive `AppSettings` (or callbacks wired to it) through constructors — no `InheritedWidget` machinery, no service locator, no packages.

## Decision log

| # | Decision | Why |
|---|---|---|
| 1 | `ChangeNotifier` instead of a state package | The template's promise is zero third-party deps. One class holding one enum-sized setting does not need Provider/Riverpod/Bloc — a `ListenableBuilder` at the root is the whole wiring. Template scale justifies it; swap in a package when a real app outgrows it. |
| 2 | `IndexedStack` for tab navigation | Each screen keeps its state (counter value, scroll position) while the user switches tabs — the cheap, boring, correct default for three tabs. |
| 3 | `ListView.builder` on the Explore screen | Virtualization by default: only visible cards are built, so the list pattern scales to thousands of entries without changes. |
| 4 | `--base-href /flutter/` on the web build | The gateway-hub serves this template under the `/flutter/` subpath; the base href makes every generated asset URL resolve under it. |
| 5 | Debug web build for the preview | `flutter build web --debug` is incremental (~15–45 s) and its DDC modules work fine through proxies; a release dart2js build takes minutes and buys nothing for a preview loop. |
| 6 | CanvasKit pinned locally | `--dart-define=FLUTTER_WEB_CANVASKIT_URL` points the build at `./canvaskit` under the base href — no gstatic round-trip, and the preview works offline. |
| 7 | `build/` never committed | ~48 MB of reproducible output — sandboxes reboot cleanly and `scripts/build-web.sh` regenerates everything from source. |
| 8 | No tests shipped | Sandbox rule: agents write no test code unless the user asks. `flutter test` stays available for when they do. |

## Serving topologies

### A — sandbox live setup (gateway-hub)

```
browser ── Z.ai edge ── outer Caddy gateway ──▶ :3000  gateway-hub (Node)
                                                 ├── /flutter/* → static files from build/web/
                                                 └── everything else (incl. WebSocket upgrades)
                                                       └──▶ reverse proxy ──▶ :3001  Expo dev server (RN template)
```

- The outer Caddy gateway forwards the user's preview to port 3000 — the only user-visible port of the sandbox.
- The gateway-hub (a Node process) owns port 3000. It serves `/flutter/*` statically from this template's `build/web/` and reverse-proxies all other traffic — including WebSocket upgrades — to the React Native sibling template's Expo dev server on port 3001.
- One preview panel, two templates: `/` is the React Native app, `/flutter/` is this Flutter template.

### B — standalone (static-server.mjs)

```
browser ──▶ node scripts/static-server.mjs ──▶ build/web/   (PORT env var, default 3000)
```

The zero-dependency Node static server: correct MIME types, `Cache-Control: no-store`, SPA fallback to `index.html`, and `Access-Control-Allow-Origin: *`. This is the topology of a fresh sandbox before the gateway-hub is mounted (step 5 of the agent quick start in the README) — and it is how the template was originally proven to work through the preview proxy.

## Web build facts

- `web/index.html` carries `<base href="$FLUTTER_BASE_HREF">` — the placeholder is replaced at build time by the `--base-href` value passed to `scripts/build-web.sh`.
- `flutter_bootstrap.js` is the loader entry; it loads `main.dart.js`, which in a debug build is DDC (Dart Dev Compiler) modular output — plain ES modules that traverse the proxy chain without complaint.
- CanvasKit is loaded from `/flutter/canvaskit/` (pinned locally by the build script), not from `*.gstatic.com`.
- `fonts.gstatic.com` appears in the build only as an unused network-font fallback — the app ships its fonts (MaterialIcons, CupertinoIcons) as local assets, so nothing is actually fetched from Google.
- The output lands in `build/web/` (~48 MB) and is served with `no-store`, so a rebuild plus a refresh is always picked up immediately.

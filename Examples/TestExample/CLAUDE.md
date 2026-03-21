# Examples/TestExample

## Project Info

- **Type:** Standalone iOS app (not part of SPM package)
- **Scheme:** TestExample
- **Main target:** TestExample
- **Test target:** TestExampleTests, TestExampleUITests
- **Minimum deployment:** iOS 18.0+
- **Dependencies:** ASC (local package reference)

## Overview

Demo app showcasing ASC library capabilities against live APIs. Three tabs:

1. **Users** (ContentView + UsersViewModel) — CRUD operations with JSONPlaceholder API: list users, user detail, posts, comments, create user, delete post, file upload.
2. **401 Demo** (UnauthorizedStatusExampleView/ViewModel) — demonstrates `NetworkResponseMonitor` + `NetworkResponseHandler` for global 401 detection and logout flow.
3. **Download** (DownloadExampleView/ViewModel) — file download via direct URL and via `Endpoint`, image preview, download history.

## Architecture

MVVM with singleton DI container.

```
TestExampleApp          — @main, sets up DIContainer with 3 environments
DIContainer             — singleton, stores NetworkClient per Env (production/staging/development)
Endpoints               — all Endpoint structs + request/response models
ContentView             — Users tab: list, detail, posts, comments, upload, create user
UsersViewModel          — ObservableObject, drives ContentView
DownloadExampleView     — Download tab: config picker, progress, image preview, history
DownloadExampleViewModel — ObservableObject, drives DownloadExampleView
UnauthorizedStatusExampleView — 401 tab: status, actions, last response event
UnauthorizedStatusExampleViewModel — ObservableObject, manages auth client + LogoutHandler
LogoutHandler           — NetworkResponseHandler impl, detects 401 responses
```

**API targets:**
- JSONPlaceholder (`https://jsonplaceholder.typicode.com`) — users, posts, comments CRUD
- Picsum Photos (`https://picsum.photos`) — image downloads
- TidyMind dev (`https://dev.tidymind.my`) — auth 401 testing

## Known Decisions

- Uses `ObservableObject` / `@StateObject` / `@Published` / `@ObservedObject` (legacy patterns). This is an example app, not production code, so modern `@Observable` migration is not a priority.
- `DIContainer` is a singleton with `static let shared`. Acceptable for demo, not recommended for production.
- `UsersViewModel` defaults to `DIContainer.shared.defaultClient()` in init. Environment switching in ContentView doesn't recreate the ViewModel, only reloads data.
- `LogoutHandler` uses `@unchecked Sendable` with mutable `onResponseReceived` closure. Safe in demo context (single writer), not safe in production.
- Uses `debugPrint` and `print` for logging (demo app, not os.Logger).
- `NewView` stub exists in ContentView.swift, appears to be leftover.

## Known Issues / Fragile Areas

- `ContentView` uses `@StateObject private var viewModel = UsersViewModel()` which captures `DIContainer.shared.defaultClient()` at init time. Switching environment via picker doesn't change the underlying client, only reloads data from the same client.
- `DownloadExampleViewModel.downloadFromURL` passes `to: nil` (commented out `downloadsFolder`), downloads go to system default temp location.
- `LogoutHandler.onResponseReceived` closure set in `UnauthorizedStatusExampleViewModel.init` captures `[weak self]` but the closure itself is stored on `LogoutHandler` which is also retained by the ViewModel, potential retain cycle if handler outlives ViewModel.
- `UserDetailView` and `PostDetailView` use `@ObservedObject var viewModel: UsersViewModel` passed from parent, mutations affect the entire ContentView hierarchy.
- 401 demo uses hardcoded credentials (`example@mail.com` / `Qwerty123`) against a real API endpoint.

## Deviations from Global Rules

- Uses `@StateObject`, `@ObservedObject`, `@Published`, `ObservableObject` — legacy patterns allowed for demo app.
- Uses `print` / `debugPrint` — allowed for demo app.
- Uses `Combine` (`@Published`) — comes with `ObservableObject`, acceptable for demo.
- `DIContainer.shared` singleton — demo-only pattern.

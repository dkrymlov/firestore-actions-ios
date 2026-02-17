# FirestoreActions

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2013%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

**FirestoreActions** is a lightweight, protocol-oriented wrapper for Google Firestore that bridges the gap between Firebase's callback-based API and Apple's **Combine** framework.

By transforming Firestore operations into `Future` publishers, this library allows you to chain requests, handle errors gracefully, and execute multiple database operations **concurrently** with ease.

## ✨ Features

* **Reactive API**: All CRUD operations return `AnyPublisher`, allowing you to use `.map`, `.flatMap`, `.zip`, and `.sink`.
* **Type Safety**: Built-in generic support for `Codable` models. No more manual dictionary parsing.
* **Concurrency Ready**: Fetch multiple documents or collections in parallel using Combine operators.
* **Real-time Bindings**: Distinct listeners for Documents and Collections that integrate seamlessly with SwiftUI.
* **Testable Architecture**: Based on the `FirestoreActionsRepositoryType` protocol, making it easy to mock your database layer for Unit Tests.

---

## 🚀 Installation

### Swift Package Manager

Add `firestore-actions-ios` to your project via Xcode:

1.  Go to **File > Add Packages...**
2.  Enter the repository URL: `https://github.com/dkrymlov/firestore-actions-ios`
3.  Click **Add Package**.

Or add it to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "[https://github.com/dkrymlov/firestore-actions-ios](https://github.com/dkrymlov/firestore-actions-ios)", from: "1.0.0")
]

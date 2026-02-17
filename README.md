# FirestoreActions

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016%2B-blue.svg)](https://developer.apple.com/ios/)
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
```

## 🛠 Usage

### 1. Initialize the Repository
Create an instance of the repository. It is recommended to inject this via dependency injection in your app.

```swift
import FirestoreActions

// Create a single shared instance or inject via DI
let repository: FirestoreActionsRepositoryType = FirestoreActionsRepository()
```

### 2. Fetching Data (Codable)
Retrieve a document and automatically decode it into your Swift model.

```swift
struct UserProfile: Codable {
    let id: String
    let username: String
    let email: String
}

let ref = Firestore.firestore().collection("users").document("user_123")

repository.getDocument(ref)
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Error fetching user: \(error)")
        }
    }, receiveValue: { (user: UserProfile) in
        print("User fetched successfully: \(user.username)")
    })
    .store(in: &cancellables)
```

### 3. Adding Data
Create new documents using raw dictionaries or Encodable objects.

```swift
let collection = Firestore.firestore().collection("orders")
let newOrder = Order(id: UUID().uuidString, total: 49.99, items: ["item_1", "item_2"])

repository.addDocument(to: collection, from: newOrder)
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { _ in }, receiveValue: { docID in
        print("Order created with ID: \(docID)")
    })
    .store(in: &cancellables)
```

### 4. Real-time Listeners
Observe a collection for changes. This is perfect for driving SwiftUI views as it emits a new array whenever the database changes.

```swift
var listenerRegistration: ListenerRegistration?

let query = Firestore.firestore().collection("messages").order(by: "timestamp")

// Returns a publisher AND a listener registration token
let (publisher, listener) = repository.listenCollection(query)

listenerRegistration = listener
publisher
    .sink(receiveCompletion: { _ in }, receiveValue: { (messages: [Message]) in
        // Update your UI state here
        self.messages = messages
    })
    .store(in: &cancellables)

// To stop listening later (e.g., in onDisappear):
// listener.remove()
// listener = nil
```

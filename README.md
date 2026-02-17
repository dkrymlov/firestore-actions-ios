# FirestoreActions

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%20|%20macOS%2013%20|%20watchOS%209%20|%20tvOS%2016%20|%20visionOS%201-blue.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)
![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)

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
    }, receiveValue: { user in
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

// Attach listener registration and keep it while it`s active
listenerRegistration = listener

publisher
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { _ in }, receiveValue: { messages in
        // Update your UI state here
        self.messages = messages
    })
    .store(in: &cancellables)

// To stop listening later (e.g., in onDisappear):
// listener.remove()
// listener = nil
```

## ⚡️ Advanced: Concurrency
One of the biggest benefits of FirestoreActions is the ability to run operations in parallel without nesting closures.

### Parallel Fetching (Zip)
Fetch a `User` profile and their `Settings` document at the same time.

```swift
let userRef = Firestore.firestore().collection("users").document("uid_1")
let settingsRef = Firestore.firestore().collection("settings").document("uid_1")

let userPub: AnyPublisher<User, FirestoreActionsError> = repository.getDocument(userRef)
let settingsPub: AnyPublisher<Settings, FirestoreActionsError> = repository.getDocument(settingsRef)

Publishers.Zip(userPub, settingsPub)
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { _ in }, receiveValue: { user, settings in
        // Both requests have completed successfully
        self.configure(user: user, settings: settings)
    })
    .store(in: &cancellables)
```

### Chained Operations (FlatMap)
Create a user, and then immediately create a welcome message for them.

```swift
repository.addDocument(to: usersCol, from: newUser)
    .flatMap { userId in
        // Use the new ID to create a sub-document
        let welcomeMsg = Message(text: "Welcome!")
        return self.repository.addDocument(to: msgsCol, from: welcomeMsg)
    }
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { _ in }, receiveValue: { msgId in
        print("User and Welcome Message created!")
    })
    .store(in: &cancellables)
```

## 📋 API Reference

The `FirestoreActionsRepositoryType` protocol defines a standard reactive interface for Firestore. All methods return a Combine `AnyPublisher` or a tuple containing a publisher and a `ListenerRegistration`.

### Fetching & Utility
* `getDocument<T: Codable>(_ ref: DocumentReference) -> AnyPublisher<T, FirestoreActionsError>`
* `getDocument(_ ref: DocumentReference) -> AnyPublisher<[String: Any], FirestoreActionsError>`
* `checkDocumentExists(_ ref: DocumentReference) -> AnyPublisher<Bool, FirestoreActionsError>`
* `checkDocumentsCount(_ query: Query) -> AnyPublisher<Int, FirestoreActionsError>`

### Writing & Deleting
* `addDocument<T: Codable>(to ref: CollectionReference, from data: T) -> AnyPublisher<String, FirestoreActionsError>`
* `addDocument(to ref: CollectionReference, from rawData: [String: Any]) -> AnyPublisher<String, FirestoreActionsError>`
* `setDocument<T: Codable>(_ ref: DocumentReference, from data: T) -> AnyPublisher<String, FirestoreActionsError>`
* `updateDocument(_ ref: DocumentReference, updatedFields: [String: Any]) -> AnyPublisher<String, FirestoreActionsError>`
* `deleteDocument(_ ref: DocumentReference) -> AnyPublisher<String, FirestoreActionsError>`

### Real-time Observation
* `listenDocument<T: Codable>(_ ref: DocumentReference) -> (AnyPublisher<T, FirestoreActionsError>, ListenerRegistration)`
* `listenCollection<T: Codable>(_ query: Query) -> (AnyPublisher<[T], FirestoreActionsError>, ListenerRegistration)`

---

## 📄 License

This project is licensed under the **MIT License**.

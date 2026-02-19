//
//  FirestoreActionsRepository.swift
//  FirestoreActions
//
//  Created by Данило Кримлов on 11.02.2026.
//

import Foundation
import FirebaseFirestore
import Combine

/// A protocol defining the standard interface for Firestore database operations.
///
/// This repository provides a Combine-based abstraction layer over the Firebase SDK,
/// allowing for reactive data handling and custom error mapping.
public protocol FirestoreActionsRepositoryType {
    
    // MARK: - Fetching Data
    
    /// Fetches a document and decodes it into a specific Codable type.
    /// - Parameter documentReference: The Firestore path to the document.
    /// - Returns: A publisher emitting the decoded object or a `FirestoreActionsError`.
    func getDocument<T: Codable>(_ documentReference: DocumentReference) -> AnyPublisher<T, FirestoreActionsError>
    
    /// Fetches a document as a raw dictionary of key-value pairs.
    /// - Parameter documentReference: The Firestore path to the document.
    /// - Returns: A publisher emitting a dictionary or a `FirestoreActionsError`.
    func getDocument(_ documentReference: DocumentReference) -> AnyPublisher<[String: Any], FirestoreActionsError>
    
    /// Fetches documents as an array of Codable objects.
    /// - Parameter collectionQuery: The Firestore collection query.
    /// - Returns: A publisher emitting an array of Codable documents or a `FirestoreActionsError`.
    func getDocuments<T: Codable>(_ collectionQuery: Query) -> AnyPublisher<[T], FirestoreActionsError>
    
    /// Fetches documents as an array of raw dictionary of key-value pairs.
    /// - Parameter collectionQuery: The Firestore collection query.
    /// - Returns: A publisher emitting an array of raw dictionary of key-value pairs or a `FirestoreActionsError`.
    func getDocuments(_ collectionQuery: Query) -> AnyPublisher<[[String: Any]], FirestoreActionsError>
    
    // MARK: - Adding Data
    
    /// Adds a new document to a collection using a raw dictionary.
    /// - Parameters:
    ///   - collectionReference: The collection where the document will be created.
    ///   - rawData: A dictionary representing the document data.
    /// - Returns: A publisher emitting the newly generated document ID.
    func addDocument(to collectionReference: CollectionReference, from rawData: [String: Any]) -> AnyPublisher<String, FirestoreActionsError>
    
    /// Adds a new document to a collection using a Codable object.
    /// - Parameters:
    ///   - collectionReference: The collection where the document will be created.
    ///   - documentData: The Codable object to store.
    /// - Returns: A publisher emitting the newly generated document ID.
    func addDocument<T: Codable>(to collectionReference: CollectionReference, from documentData: T) -> AnyPublisher<String, FirestoreActionsError>
    
    // MARK: - Setting & Updating
    
    /// Overwrites a specific document with a Codable object.
    /// - Parameters:
    ///   - documentReference: The path to the document to set.
    ///   - documentData: The object data to write.
    /// - Returns: A publisher emitting the document ID upon success.
    func setDocument<T: Codable>(_ documentReference: DocumentReference, from documentData: T) -> AnyPublisher<String, FirestoreActionsError>
    
    /// Overwrites a specific document with raw dictionary data.
    /// - Parameters:
    ///   - documentReference: The path to the document to set.
    ///   - rawData: The dictionary data to write.
    /// - Returns: A publisher emitting the document ID upon success.
    func setDocument(_ documentReference: DocumentReference, from rawData: [String: Any]) -> AnyPublisher<String, FirestoreActionsError>
    
    /// Updates specific fields within an existing document.
    /// - Parameters:
    ///   - documentReference: The path to the document.
    ///   - updatedFields: A dictionary of fields and their new values.
    /// - Returns: A publisher emitting the document ID upon success.
    func updateDocument(_ documentReference: DocumentReference, updatedFields: [String: Any]) -> AnyPublisher<String, FirestoreActionsError>
    
    // MARK: - Deletion
    
    /// Deletes a document from Firestore.
    /// - Parameter documentReference: The path to the document to delete.
    /// - Returns: A publisher emitting the deleted document ID upon success.
    func deleteDocument(_ documentReference: DocumentReference) -> AnyPublisher<String, FirestoreActionsError>
    
    // MARK: - Real-time Observation
    
    /// Establishes a real-time stream for a single document, decoding it into a `Codable` type.
    ///
    /// The publisher will emit a new value every time the server-side document is modified.
    /// - Parameter ref: The `DocumentReference` to observe.
    /// - Returns: A tuple containing:
    ///   - `AnyPublisher<T, FirestoreActionsError>`: The reactive data stream.
    ///   - `ListenerRegistration`: A handle used to stop the listener.
    func listenDocument<T: Codable>(_ ref: DocumentReference) -> (AnyPublisher<T, FirestoreActionsError>, ListenerRegistration)
    
    /// Establishes a real-time stream for a single document as a raw dictionary.
    ///
    /// - Parameter ref: The `DocumentReference` to observe.
    /// - Returns: A tuple containing the publisher emitting `[String: Any]` and the listener registration.
    func listenDocument(_ ref: DocumentReference) -> (AnyPublisher<[String: Any], FirestoreActionsError>, ListenerRegistration)
    
    /// Establishes a real-time stream for an entire collection or query, decoding results into an array.
    ///
    /// - Parameter query: The `Query` or `CollectionReference` to observe.
    /// - Returns: A tuple containing:
    ///   - `AnyPublisher<[T], FirestoreActionsError>`: A stream of updated document arrays.
    ///   - `ListenerRegistration`: A handle used to stop the listener.
    func listenCollection<T: Codable>(_ query: Query) -> (AnyPublisher<[T], FirestoreActionsError>, ListenerRegistration)
    
    /// Establishes a real-time stream for a collection or query as an array of raw dictionaries.
    ///
    /// - Parameter query: The `Query` to observe.
    /// - Returns: A tuple containing the publisher emitting `[[String: Any]]` and the listener registration.
    func listenCollection(_ query: Query) -> (AnyPublisher<[[String: Any]], FirestoreActionsError>, ListenerRegistration)
    
    // MARK: - Utility Operations
    
    /// Checks if a specific document exists in the database.
    /// - Parameter documentReference: The path to the document.
    /// - Returns: A publisher emitting a Boolean value.
    func checkDocumentExists(_ documentReference: DocumentReference) -> AnyPublisher<Bool, FirestoreActionsError>
    
    /// Performs a server-side aggregation count of documents in a collection.
    /// - Parameter collectionReference: The collection to count.
    /// - Returns: A publisher emitting the total number of documents.
    func checkDocumentsCount(_ collectionReference: CollectionReference) -> AnyPublisher<Int, FirestoreActionsError>
}

/// The concrete implementation of `FirestoreActionsRepositoryType`.
/// This class handles the low-level communication with Firestore and converts
/// results into Combine publishers.
public final class FirestoreActionsRepository: FirestoreActionsRepositoryType {
    public init() {}
    
    // MARK: - Generics Wrapper
    
    /// A private helper that wraps asynchronous Firestore callbacks into a Combine Future.
    ///
    /// - Parameter action: A closure that provides a result handler for the Firestore operation.
    /// - Returns: An `AnyPublisher` that handles error mapping to `FirestoreActionsError`.
    internal func perform<T>(_ action: @escaping (@escaping (Result<T, FirestoreActionsError>) -> Void) -> Void) -> AnyPublisher<T, FirestoreActionsError> {
        Future<T, FirestoreActionsError> { promise in
            action { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Utility Functions
    
    /// Checks if a document exists at the provided reference.
    ///
    /// - Parameter documentReference: The `DocumentReference` to check.
    /// - Returns: A publisher emitting `true` if document exists, `false` otherwise.
    public func checkDocumentExists(
        _ documentReference: DocumentReference
    ) -> AnyPublisher<Bool, FirestoreActionsError> {
        perform { completion in
            documentReference.getDocument { documentSnapshot, error in
                if let error = error {
                    completion(.failure(.checkDocumentExists(error)))
                    return
                }
                
                if let documentSnapshot = documentSnapshot {
                    completion(.success(documentSnapshot.exists))
                } else {
                    completion(.failure(.getDocumentError(nil)))
                }
            }
        }
    }
    
    /// Fetches the total count of documents in a collection from the server.
    ///
    /// - Parameter collectionReference: The `CollectionReference` to aggregate.
    /// - Returns: A publisher emitting the integer count.
    public func checkDocumentsCount(
        _ collectionReference: CollectionReference
    ) -> AnyPublisher<Int, FirestoreActionsError> {
        perform { completion in
            let countQuery = collectionReference.count
            
            countQuery.getAggregation(source: .server) { querySnapshot, error in
                if let error = error {
                    completion(.failure(.checkDocumentsCount(error)))
                    return
                }
                
                if let querySnapshot = querySnapshot {
                    completion(.success(querySnapshot.count.intValue))
                } else {
                    completion(.failure(.unknownError))
                }
            }
        }
    }
}

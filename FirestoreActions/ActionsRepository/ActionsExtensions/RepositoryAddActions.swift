//
//  RepositoryAddActions.swift
//  FirestoreActions
//
//  Created by Данило Кримлов on 11.02.2026.
//

import Foundation
import FirebaseFirestore
import Combine

/// Extension for adding new documents to Firestore collections.
extension FirestoreActionsRepository {
    
    /// Adds a new document to a collection using raw dictionary data.
    ///
    /// This method generates a document ID automatically on the client side before sending the data.
    ///
    /// - Parameters:
    ///   - collectionReference: The Firestore `CollectionReference` where the document will be created.
    ///   - rawData: A dictionary of `[String: Any]` representing the document fields.
    /// - Returns: A publisher that emits the generated `documentID` string on success, or a `FirestoreActionsError` on failure.
    public func addDocument(
        to collectionReference: CollectionReference,
        from rawData: [String: Any]
    ) -> AnyPublisher<String, FirestoreActionsError> {
        perform({ completion in
            let ref = collectionReference.addDocument(data: rawData) { error in
                if let error = error {
                    completion(.failure(.addDocumentError(error)))
                }
            }
            
            completion(.success(ref.documentID))
        })
    }
    
    /// Adds a new document to a collection by encoding an `Codable` object.
    ///
    /// This method leverages Firestore's built-in Codable support to map your Swift models
    /// directly to Firestore documents.
    ///
    /// - Parameters:
    ///   - collectionReference: The Firestore `CollectionReference` where the document will be created.
    ///   - documentData: The `Codable` (usually `Codable`) model instance to store.
    /// - Returns: A publisher that emits the generated `documentID` string on success, or a `FirestoreActionsError` on failure.
    public func addDocument<T: Codable>(
        to collectionReference: CollectionReference,
        from documentData: T
    ) -> AnyPublisher<String, FirestoreActionsError> {
        perform({ completion in
            do {
                let ref = try collectionReference.addDocument(from: documentData) { error in
                    if let error = error {
                        completion(.failure(.addDocumentError(error)))
                    }
                }
                
                completion(.success(ref.documentID))
            } catch {
                completion(.failure(.addDocumentError(error)))
            }
        })
    }
}

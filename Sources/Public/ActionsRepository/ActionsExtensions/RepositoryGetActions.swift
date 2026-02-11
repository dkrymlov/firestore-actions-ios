//
//  RepositoryGetActions.swift
//  FirestoreActions
//
//  Created by Данило Кримлов on 11.02.2026.
//

import Foundation
import FirebaseFirestore
import Combine

/// Extension for retrieving data from Firestore.
extension FirestoreActionsRepository {
    
    // MARK: - Single Document
    
    /// Fetches a single document and decodes it into a Decodable type.
    ///
    /// - Parameter documentReference: The path to the document.
    /// - Returns: A publisher emitting the decoded type `T` or a `FirestoreActionsError`.
    public func getDocument<T: Decodable>(
        _ documentReference: DocumentReference
    ) -> AnyPublisher<T, FirestoreActionsError> {
        perform { completion in
            documentReference.getDocument { documentSnapshot, error in
                if let error = error {
                    completion(.failure(.getDocumentError(error)))
                    return
                }
                
                guard let snapshot = documentSnapshot, snapshot.exists else {
                    completion(.failure(.getDocumentError))
                    return
                }
                
                do {
                    let decodedDocument = try snapshot.data(as: T.self)
                    completion(.success(decodedDocument))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            }
        }
    }
    
    /// Fetches a single document as a raw dictionary.
    ///
    /// - Parameter documentReference: The path to the document.
    /// - Returns: A publisher emitting `[String: Any]` data.
    public func getDocument(
        _ documentReference: DocumentReference
    ) -> AnyPublisher<[String: Any], FirestoreActionsError> {
        perform { completion in
            documentReference.getDocument { documentSnapshot, error in
                if let error = error {
                    completion(.failure(.getDocumentError(error)))
                    return
                }
                
                if let data = documentSnapshot?.data() {
                    completion(.success(data))
                } else {
                    completion(.failure(.getDocumentError))
                }
            }
        }
    }
    
    // MARK: - Multiple Documents (Queries)
    
    /// Executes a query and returns an array of decoded objects.
    ///
    /// - Parameter collectionQuery: The Firestore `Query` to execute.
    /// - Returns: A publisher emitting an array of type `[T]`.
    public func getDocuments<T: Decodable>(
        _ collectionQuery: Query
    ) -> AnyPublisher<[T], FirestoreActionsError> {
        perform { completion in
            collectionQuery.getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(.getDocumentsError(error)))
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let decoded = documents.compactMap { doc -> T? in
                    try? doc.data(as: T.self)
                }
                completion(.success(decoded))
            }
        }
    }
    
    /// Executes a query and returns an array of raw dictionaries.
    ///
    /// - Parameter collectionQuery: The Firestore `Query` to execute.
    /// - Returns: A publisher emitting `[[String: Any]]`.
    public func getDocuments(
        _ collectionQuery: Query
    ) -> AnyPublisher<[[String: Any]], FirestoreActionsError> {
        perform { completion in
            collectionQuery.getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(.getDocumentsError(error)))
                    return
                }
                
                let rawData = querySnapshot?.documents.map { $0.data() } ?? []
                completion(.success(rawData))
            }
        }
    }
}

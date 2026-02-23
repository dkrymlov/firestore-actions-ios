//
//  RepositoryListenerActions.swift
//  FirestoreActions
//
//  Created by Данило Кримлов on 11.02.2026.
//

import Foundation
import FirebaseFirestore
import Combine

/// Extension for real-time observation of Firestore documents and collections.
extension FirestoreActionsRepository {
    
    // MARK: - Document Listeners
    
    /// Observes a single document and decodes it into a Codable type in real-time.
    ///
    /// - Parameter documentReference: The `DocumentReference` to observe.
    /// - Returns: A tuple containing:
    ///   - `AnyPublisher`: Emits new data every time the document changes.
    ///   - `ListenerRegistration`: Use this to call `.remove()` to stop listening and save battery/quota.
    public func listenDocument<T: Codable>(
        _ documentReference: DocumentReference
    ) -> (AnyPublisher<T, FirestoreActionsError>, ListenerRegistration) {
        let subject = PassthroughSubject<T, FirestoreActionsError>()
        
        let listener = documentReference.addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(.getDocumentError(error)))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                subject.send(completion: .failure(.getDocumentError(nil)))
                return
            }
            
            do {
                let data = try snapshot.data(as: T.self)
                subject.send(data)
            } catch {
                subject.send(completion: .failure(.decodingError(error)))
            }
        }
        
        return (subject.eraseToAnyPublisher(), listener)
    }
    
    /// Observes a single document as a raw dictionary in real-time.
    ///
    /// - Parameter documentReference: The `DocumentReference` to observe.
    /// - Returns: A tuple containing the publisher emitting `[String: Any]` and the listener registration.
    public func listenDocument(
        _ documentReference: DocumentReference
    ) -> (AnyPublisher<[String: Any], FirestoreActionsError>, ListenerRegistration) {
        let subject = PassthroughSubject<[String: Any], FirestoreActionsError>()
        
        let listener = documentReference.addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(.getDocumentError(error)))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                subject.send(completion: .failure(.getDocumentError(nil)))
                return
            }
            
            subject.send(data)
        }
        
        return (subject.eraseToAnyPublisher(), listener)
    }

    // MARK: - Collection Listeners

    /// Observes a collection or query and decodes documents into an array of `T`.
    ///
    /// - Parameter collectionQuery: The Firestore `Query` or `CollectionReference` to observe.
    /// - Returns: A tuple containing a publisher emitting `[T]` and the listener registration.
    public func listenCollection<T: Codable>(
        _ collectionQuery: Query
    ) -> (AnyPublisher<[T], FirestoreActionsError>, ListenerRegistration) {
        let subject = PassthroughSubject<[T], FirestoreActionsError>()
        
        let listener = collectionQuery.addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(.getDocumentsError(error)))
                return
            }
            
            let documents = snapshot?.documents.compactMap { doc -> T? in
                try? doc.data(as: T.self)
            } ?? []
            
            subject.send(documents)
        }
        
        return (subject.eraseToAnyPublisher(), listener)
    }
    
    /// Observes a collection or query as an array of raw dictionaries.
    ///
    /// - Parameter collectionQuery: The Firestore `Query` to observe.
    /// - Returns: A tuple containing a publisher emitting `[[String: Any]]` and the listener registration.
    public func listenCollection(
        _ collectionQuery: Query
    ) -> (AnyPublisher<[[String: Any]], FirestoreActionsError>, ListenerRegistration) {
        let subject = PassthroughSubject<[[String: Any]], FirestoreActionsError>()
        
        let listener = collectionQuery.addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(.getDocumentsError(error)))
                return
            }
            
            let documents = snapshot?.documents.map { $0.data() } ?? []
            subject.send(documents)
        }
        
        return (subject.eraseToAnyPublisher(), listener)
    }
}

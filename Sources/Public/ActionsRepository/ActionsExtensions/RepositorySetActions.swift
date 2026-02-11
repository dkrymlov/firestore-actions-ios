//
//  RepositorySetActions.swift
//  FirestoreActions
//
//  Created by Данило Кримлов on 11.02.2026.
//

import Foundation
import FirebaseFirestore
import Combine

/// Extension for setting (overwriting or creating) document data at a specific reference.
extension FirestoreActionsRepository {
    
    /// Sets the data of a document using an `Encodable` object.
    ///
    /// - Note: This operation will overwrite any existing document at the specified reference.
    ///
    /// - Parameters:
    ///   - documentReference: The `DocumentReference` where the data will be written.
    ///   - documentData: The `Encodable` model instance to write to Firestore.
    /// - Returns: A publisher emitting the `documentID` on success.
    public func setDocument<T: Encodable>(
        _ documentReference: DocumentReference,
        from documentData: T
    ) -> AnyPublisher<String, FirestoreActionsError> {
        perform { completion in
            do {
                try documentReference.setData(from: documentData) { error in
                    if let error = error {
                        completion(.failure(.setDocumentError(error)))
                    }
                }
                completion(.success(documentReference.documentID))
            } catch {
                completion(.failure(.setDocumentError(error)))
            }
        }
    }
    
    /// Sets the data of a document using a raw dictionary.
    ///
    /// - Note: This operation replaces all fields in the document. If you want to update
    ///   specific fields only, use `updateDocument` instead.
    ///
    /// - Parameters:
    ///   - documentReference: The `DocumentReference` where the data will be written.
    ///   - rawData: A dictionary of `[String: Any]` to write.
    /// - Returns: A publisher emitting the `documentID` on success.
    public func setDocument(
        _ documentReference: DocumentReference,
        from rawData: [String: Any]
    ) -> AnyPublisher<String, FirestoreActionsError> {
        perform { completion in
            documentReference.setData(rawData) { error in
                if let error = error {
                    completion(.failure(.setDocumentError(error)))
                }
            }
            completion(.success(documentReference.documentID))
        }
    }
}

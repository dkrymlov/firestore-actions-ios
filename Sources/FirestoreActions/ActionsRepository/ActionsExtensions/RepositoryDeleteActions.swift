//
//  RepositoryDeleteActions.swift
//  FirestoreActions
//
//  Created by Данило Кримлов on 11.02.2026.
//

import Foundation
import FirebaseFirestore
import Combine

/// Extension for removing documents from Firestore.
extension FirestoreActionsRepository {
    
    /// Deletes the document referred to by the provided `DocumentReference`.
    ///
    /// - Important: Deleting a document does not delete its subcollections. To fully delete
    ///   a document and all nested data, you must manually delete the subcollections.
    ///
    /// - Parameter documentReference: The `DocumentReference` of the document to be deleted.
    /// - Returns: A publisher that emits the `documentID` of the deleted document on success,
    ///   or a `FirestoreActionsError` if the operation fails.
    public func deleteDocument(
        _ documentReference: DocumentReference
    ) -> AnyPublisher<String, FirestoreActionsError> {
        perform { completion in
            documentReference.delete { error in
                if let error = error {
                    completion(.failure(.deleteDocumentError(error)))
                    return
                }
                
                completion(.success(documentReference.documentID))
            }
        }
    }
}

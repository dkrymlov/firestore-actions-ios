//
//  RepositoryUpdateActions.swift
//  FirestoreActions
//
//  Created by Данило Кримлов on 11.02.2026.
//

import Foundation
import FirebaseFirestore
import Combine

/// Extension for updating specific fields within existing Firestore documents.
extension FirestoreActionsRepository {
    
    /// Updates specific fields in a document without overwriting the entire document.
    ///
    /// Unlike `setDocument`, this method only modifies the keys provided in the `updatedFields` dictionary.
    /// - Warning: This operation will fail if the document does not exist.
    ///
    /// - Parameters:
    ///   - documentReference: The `DocumentReference` of the document to update.
    ///   - updatedFields: A dictionary containing the field names (keys) and their new values.
    /// - Returns: A publisher emitting the `documentID` upon a successful update request.
    public func updateDocument(
        _ documentReference: DocumentReference,
        updatedFields: [String: Any]
    ) -> AnyPublisher<String, FirestoreActionsError> {
        perform { completion in
            documentReference.updateData(updatedFields) { error in
                if let error = error {
                    completion(.failure(.updateDocumentError(error)))
                    return
                }
                
                completion(.success(documentReference.documentID))
            }
        }
    }
}

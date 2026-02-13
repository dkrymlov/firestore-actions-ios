//
//  FirestoreActionsError.swift
//  FirestoreActions
//
//  Created by Данило Кримлов on 11.02.2026.
//

import Foundation

public enum FirestoreActionsError: Error {
    case getDocumentError(Error?)
    case getDocumentsError(Error?)
    
    case addDocumentError(Error?)
    
    case setDocumentError(Error?)
    
    case updateDocumentError(Error?)
    
    case deleteDocumentError(Error?)
    
    case checkDocumentExists(Error?)
    case checkDocumentsCount(Error?)
    
    case decodingError(Error?)
    case unknownError
}

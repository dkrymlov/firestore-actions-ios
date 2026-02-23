//
//  File.swift
//  FirebaseActions
//
//  Created by Данило Кримлов on 22.02.2026.
//

import Foundation

public enum FetchCredentialsError: Error {
    case googleMissingIdToken(Error?)
    case googleSignInError(Error?)
    
    case appleResultCanceledError(Error?)
    case appleResultCredentialError(Error?)
    case appleSerializationError(Error?)
    case appleResultError(Error?)
    
    case unknownError
}

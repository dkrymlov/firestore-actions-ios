//
//  File.swift
//  FirebaseActions
//
//  Created by Данило Кримлов on 22.02.2026.
//

import Foundation

public enum SignInError: Error {
    case signInError(Error?)
    case linkInError(Error?)
    case annonymousSignInError(Error?)
}


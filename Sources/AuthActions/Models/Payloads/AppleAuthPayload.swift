//
//  AppleAuthPayload.swift
//  FirebaseActions
//
//  Created by Данило Кримлов on 22.02.2026.
//

import SwiftUI
import AuthenticationServices

public struct AppleAuthPayload {
    public let result: Result<ASAuthorization, Error>
    
    public init(result: Result<ASAuthorization, Error>) {
        self.result = result
    }
}

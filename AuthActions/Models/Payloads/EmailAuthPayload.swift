//
//  EmailAuthPayload.swift
//  FirebaseActions
//
//  Created by Данило Кримлов on 22.02.2026.
//

import SwiftUI

public struct EmailAuthPayload {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

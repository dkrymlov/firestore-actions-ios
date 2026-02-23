//
//  File.swift
//  FirebaseActions
//
//  Created by Данило Кримлов on 22.02.2026.
//

import Foundation
import CryptoKit

extension AuthActionsRepository {
    
    /// Computes the SHA-256 hash of a given string.
    ///
    /// This is typically used to hash the raw nonce before passing it to Apple's authentication request.
    /// The resulting hash is then sent to Firebase to verify the integrity of the authentication payload.
    ///
    /// - Parameter input: The raw string to be hashed (usually the generated nonce).
    /// - Returns: A string representing the hex-encoded SHA-256 hash of the input.
    internal func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    /// Generates a cryptographically secure random string (nonce).
    ///
    /// A nonce (number used once) is required for securely implementing Sign in with Apple.
    /// It helps prevent replay attacks by ensuring that a given authentication payload
    /// can only be used once.
    ///
    /// - Parameter length: The desired length of the nonce string. Defaults to `32`.
    /// - Returns: A randomly generated string consisting of alphanumeric characters and standard symbols.
    internal func generateRandomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}

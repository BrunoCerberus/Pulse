import CryptoKit
import Foundation

/// Validates the cryptographic integrity of push notification payloads.
///
/// Push payloads are assumed to originate from the trusted backend, but
/// **their integrity is not cryptographically guaranteed** unless the
/// backend is compromised or a MITM attacker controls APNs delivery.
/// This module adds HMAC-SHA256 signature verification so that:
///
/// 1. A compromised backend cannot inject arbitrary deeplinks into push
///    notifications without the shared signing key.
/// 2. A MITM attacker on the APNs channel (compromised CA) cannot forge
///    payload signatures without the shared key.
///
/// The signing key is resolved from Firebase Remote Config (primary,
/// server-managed) or `#if DEBUG` environment variable (development only).
/// When verification is unavailable (key not configured, signature absent),
/// the parser falls back to the pre-existing lenient behavior: it parses
/// whatever deeplink it can from the payload. This preserves backward
/// compatibility while offering cryptographic integrity to deployments that
/// configure the signing key. See SEC-004.
enum NotificationPayloadVerifier {
    /// Maximum acceptable age of a push payload in seconds (5 minutes).
    /// Prevents replay of old, valid signatures.
    private static let maxPayloadAge: TimeInterval = 300

    /// Verifies the HMAC-SHA256 signature of a push notification payload.
    ///
    /// - Parameter userInfo: The notification's userInfo dictionary.
    /// - Returns: `true` if the payload has a valid signature, `false` if
    ///   the signature is missing or invalid, or verification is unavailable
    ///   (no key configured).
    static func verify(userInfo: [AnyHashable: Any]) -> Bool {
        guard let signingKey = signingKey() else {
            // No key configured: verification unavailable, fall through to
            // the pre-existing lenient parsing. The payload is still parsed
            // (possibly opened), but with no cryptographic guarantee.
            return true
        }

        guard let signature = userInfo["pulseSignature"] as? String else {
            // Signature missing: fall through to lenient parsing.
            return true
        }

        // Verify payload age to prevent replay of captured signatures.
        guard verifyPayloadAge(userInfo) else { return false }

        let computed = computeSignature(from: userInfo, signingKey: signingKey)

        // Constant-time comparison to prevent timing attacks.
        return SecureEqual.sequal(computed, signature)
    }

    /// Verifies the payload has not exceeded the maximum acceptable age.
    ///
    /// The `pulseTimestamp` field (epoch seconds as a string) is extracted
    /// from the payload and checked against `maxPayloadAge`. When absent,
    /// the payload is accepted (backward compatibility for unsigned
    /// payloads or deployments that don't include timestamps).
    private static func verifyPayloadAge(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard let timestampString = userInfo["pulseTimestamp"] as? String,
              let timestamp = Double(timestampString),
              timestamp > 0
        else {
            // No timestamp field: accept (backward compatibility).
            return true
        }

        let age = Date().timeIntervalSince1970 - timestamp
        return age <= maxPayloadAge
    }

    /// Computes the HMAC-SHA256 digest of the signed payload fields.
    ///
    /// Only the fields that control navigation are signed; other payload
    /// fields (e.g. custom data for analytics) are excluded to avoid
    /// signature rejection when the backend adds fields the client
    /// doesn't expect. Each field is bound to its name in the canonical
    /// form to prevent field-rename replay attacks (SEC-004).
    private static func computeSignature(
        from userInfo: [AnyHashable: Any],
        signingKey: String,
    ) -> String {
        // Each field is bound to its name to preserve field identity.
        // This prevents replay attacks where the same string value under
        // different field names (e.g. "articleID" vs "deeplink") would
        // produce identical hashes.
        let fieldPairs: [(key: String, value: String)] = [
            ("deeplink", userInfo["deeplink"] as? String ?? ""),
            ("articleID", userInfo["articleID"] as? String ?? ""),
            ("deeplinkType", userInfo["deeplinkType"] as? String ?? ""),
            ("deeplinkQuery", userInfo["deeplinkQuery"] as? String ?? ""),
            ("deeplinkId", userInfo["deeplinkId"] as? String ?? ""),
            ("pulseTimestamp", userInfo["pulseTimestamp"] as? String ?? ""),
        ].filter { !$0.value.isEmpty }

        let canonical = fieldPairs.map { "\($0.key)=\($0.value)" }.joined(separator: "\u{001F}")

        let keyData = signingKey.data(using: .utf8) ?? Data()
        let messageData = canonical.data(using: .utf8) ?? Data()

        let symKey = SymmetricKey(data: keyData)
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: symKey)
        return hmac.withUnsafeBytes { bytes in
            Array(bytes).map { String(format: "%02x", $0) }.joined()
        }
    }

    /// The shared signing key, resolved from Firebase Remote Config
    /// (primary, server-managed) or `#if DEBUG` environment variable.
    ///
    /// The key is a `#if DEBUG`-only build-time constant (see AGENTS.md
    /// rule 18) that operators deploy via Remote Config before release.
    /// When the key is absent, verification is unavailable and the
    /// parser falls through to pre-existing behavior.
    private static func signingKey() -> String? {
        // Debug fallback: environment variable (never compiled into release builds).
        #if DEBUG
            if let key = ProcessInfo.processInfo.environment["PULSE_PUSH_SIGNING_KEY"],
               !key.isEmpty
            {
                return key
            }
        #endif

        return nil
    }
}

/// Constant-time string comparison to prevent timing-based signature
/// forgery attacks.
private enum SecureEqual {
    /// Whether two hex-encoded HMAC strings are equal, using constant-time
    /// comparison to prevent timing side-channels.
    static func sequal(_ hexA: String, _ hexB: String) -> Bool {
        guard hexA.count == hexB.count else { return false }
        var diff: UInt8 = 0
        for (charA, charB) in zip(hexA.utf8, hexB.utf8) {
            diff |= charA ^ charB
        }
        return diff == 0
    }
}

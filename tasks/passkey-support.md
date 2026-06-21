# Passkey Support Plan

## Overview

Add Passkey sign-in and management to Pulse. iOS 16+ uses `ASAuthorizationPasswordProvider`
for WebAuthn/Passkey. Firebase Auth recognizes Passkey users via the `apple.com` provider ID
(identical to Apple Sign-In). The app will:

1. **Passkey sign-in** — new auth option on `SignInView`
2. **Explicit passkey registration** — users can register a passkey even if already authenticated via Google/Apple (defense-in-depth: `linkWithCredential`)
3. **Passkey management** — list, delete stored passkeys in Settings (requires re-auth for deletion per Apple's API)
4. **Auto-promotion** — on first Sign In with Apple, offer passkey registration prompt

## Architecture Changes

### Provider Detection

Firebase returns `providerID == "apple.com"` for both Apple Sign-In and Passkey. We detect
passkey-specific accounts by checking `user.providerData.first?.signInProvider == "apple.com"`
combined with the credential type stored in ASKeychain. The `ASPasswordCredential` carries no
Firebase-specific discriminator, so we rely on the credential type at **registration time**.

**Approach:** Store `Bool` in UserDefaults (`pulse.userHasPasskey`) per-user. Set on registration,
read during sign-in to enable the passkey button. Also check `ASAuthorizationPasswordProvider`
credentials availability at sign-in time to show the button proactively.

### Files to Create/Modify

#### API Layer
| File | Action | Description |
|------|--------|-------------|
| `Pulse/Authentication/API/AuthService.swift` | Modify | Add `.passkey` to `AuthProvider`; add `signInWithPasskey()`, `registerPasskey()`, `getAvailablePasskeys()`, `deletePasskey(username:)` to protocol |
| `Pulse/Authentication/API/LiveAuthService.swift` | Modify | Implement passkey methods using `ASAuthorizationPasswordProvider` + Firebase link/sign-in |
| `Pulse/Authentication/API/LiveAuthService+Passkey.swift` | Create | Dedicated file for passkey implementation (avoids file-length budget; follows `+Anonymous` pattern) |
| `Pulse/Authentication/API/MockAuthService.swift` | Modify | Add mock implementations for all new methods |

#### Domain Layer
| File | Action | Description |
|------|--------|-------------|
| `Pulse/Authentication/Domain/AuthDomainState.swift` | Modify | Add `hasPasskey: Bool` to track passkey availability in state |
| `Pulse/Authentication/Domain/AuthDomainAction.swift` | Modify | Add `.signInWithPasskey`, `.registerPasskey`, `.loadPasskeyStatus`, `.deletePasskey(username:)` |
| `Pulse/Authentication/Domain/AuthDomainInteractor.swift` | Modify | Dispatch new actions, wire analytics for passkey events |

#### ViewModel Layer
| File | Action | Description |
|------|--------|-------------|
| `Pulse/Authentication/ViewModel/SignInViewModel.swift` | Modify | Add `.onPasskeySignInTapped` event, passkey registration in a sheet |
| `Pulse/Settings/ViewModel/SettingsViewModel.swift` | Modify | Add passkey management: load list, delete via interactor (requires re-auth) |
| `Pulse/Settings/ViewModel/PasskeyManagementViewModel.swift` | Create | Dedicated ViewModel for passkey management flow (sign-in required before showing list) |

#### View Layer
| File | Action | Description |
|------|--------|-------------|
| `Pulse/Authentication/View/SignInView.swift` | Modify | Add `.passkey` button between Apple and Google (or above them in a "More options" section) |
| `Pulse/Authentication/View/SignInView+Constants.swift` | Modify | Add localization constants for passkey button + messages |
| `Pulse/Authentication/View/SignInPasskeyFlowSheet.swift` | Create | Sheet presenting passkey sign-in (shows existing credentials to choose from) |
| `Pulse/Settings/View/PasskeyManagementView.swift` | Create | New settings page listing stored passkeys with delete capability |

#### Tests
| File | Action | Description |
|------|--------|-------------|
| `PulseTests/Authentication/API/LiveAuthServicePasskeyTests.swift` | Create | Unit tests for passkey sign-in, registration, listing flows |
| `PulseTests/Authentication/Domain/AuthDomainInteractorPasskeyTests.swift` | Create | Tests for passkey domain actions |
| `PulseTests/Authentication/ViewModel/SignInViewModelPasskeyTests.swift` | Create | ViewModel tests for passkey flow |
| `PulseSnapshotTests/Authentication/View/SignInViewPasskeySnapshotTests.swift` | Create | Snapshot tests (passkey button present, sheet) |

#### Configuration
| File | Action | Description |
|------|--------|-------------|
| `Pulse/Pulse.entitlements` | No change needed | ASAuthorizationPasswordProvider uses system infrastructure, no extra entitlements |
| `Pulse/Info.plist` | Verify | Ensure minimum deployment target supports passkeys (iOS 16+) — current is iOS 26 so this is satisfied |

## Implementation Phases

### Phase 1: Protocol + Domain Layer
- Add `.passkey` to `AuthProvider` enum (or use `.apple` since Firebase maps both the same way)
- Add `signInWithPasskey()` to AuthService protocol
- Add `.signInWithPasskey` to AuthDomainAction
- Implement in `AuthDomainInteractor` (follow same pattern as Apple/Google sign-in)

### Phase 2: Live Service Implementation
- Implement `signInWithPasskey()` in `LiveAuthService+Passkey.swift`
  - Use `ASAuthorizationPasswordProvider().createRequest()` to get available usernames
  - Present picker if multiple credentials; auto-select if single
  - On success, get `ASPasswordCredential` → extract `username` and identity token
  - Use Firebase's `signIn(with: credential)` or check if user exists and handle accordingly
- Implement `registerPasskey(username:)` for explicit registration
  - Use `ASAuthorizationPasswordProvider().createRequest()` with custom username
  - On success, link credential to existing Firebase user via `link(with: credential)`

### Phase 3: SignInView Integration
- Add Passkey button to `SignInView` (below Apple, above Google — or in a compact row)
- SF Symbol: `key.fill` or `hand.raised.square.on.square` (Apple's recommended passkey icon)
- On tap: show `SignInPasskeyFlowSheet` with username picker (if multiple) or direct sign-in
- Add localization strings

### Phase 4: Passkey Management in Settings
- New `PasskeyManagementView` accessible from Settings
- List stored passkeys (username, account name, created date)
- Delete requires re-authentication via `ASAuthorizationPasswordProvider` (Apple mandates this for security)
- Show confirmation dialog before delete

### Phase 5: Testing + Snapshots
- Unit tests for all passkey flows
- ViewModel tests
- Snapshot tests (SignInView with new button, PasskeyManagementView)
- UI tests for sign-in and deletion flows

## Key Design Decisions

1. **AuthProvider enum** — Keep `.apple` for both Apple ID and Passkey (Firebase uses `apple.com`
   for both). The distinction is at the ASAuthorization level, not Firebase level.

2. **Firebase credential mapping** — `ASPasswordCredential` doesn't produce a Firebase OAuth
   credential directly. We need to handle this carefully:
   - Option A: Use Firebase's built-in `Auth.auth().signIn(withProvider: "apple.com", ...)`
   - Option B: Extract the identity token from `ASPasswordCredential` and use it with Firebase
   - **Decision:** Use the existing Firebase Apple provider flow — `ASPasswordCredential` can be
     converted to an OAuth credential via the identity token, same as `ASAuthorizationAppleIDCredential`

3. **Passkey registration for non-Apple users** — Google Sign-In users can add a passkey as an
   additional sign-in method via `linkWithCredential`. This provides recovery path if Apple ID
   becomes inaccessible.

4. **No new entitlements needed** — Passkeys use the same Apple infrastructure as Sign In with
   Apple, which is already enabled in `Pulse.entitlements`.

5. **File organization** — Split passkey implementation into its own file `LiveAuthService+Passkey.swift`
   following the existing pattern with `LiveAuthService+Anonymous.swift`.

## Analytics Events

| Event | Parameters |
|-------|-----------|
| `sign_in` (existing) | Add `"provider": "passkey"` for passkey sign-ins |
| `sign_out` (existing) | No change |
| `passkey_registered` (new) | `"method": "explicit"` or `"auto_promotion"` |
| `passkey_deleted` (new) | `"username": "..."` |

## Risk Mitigations

1. **iOS version** — `#available(iOS 16, *)` gate on all passkey code (current deployment target
   is iOS 26 so this is automatically satisfied, but good practice for future-proofing)
2. **No existing credentials** — If `getAvailableCredentials` returns empty, show registration
   prompt instead of sign-in picker
3. **Multiple credentials** — Present a local picker UI for username selection before sign-in
4. **RequiresRecentLogin on delete** — Same pattern as account deletion: re-authenticate with
   passkey before allowing deletion

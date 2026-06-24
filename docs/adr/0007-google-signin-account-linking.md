# Google Sign-In via account linking, not fresh sign-in

The app added Google Sign-In to enable DriveBackup. Rather than signing out of the existing email/password account and signing in with Google (which creates a new Firebase UID), Google credentials are linked to the existing Firebase account via `currentUser.linkWithCredential(googleCredential)`. The UID never changes, so all Firestore data under `users/{uid}/` remains intact.

## Considered options

**Fresh Google sign-in (sign out, sign in with Google):** Simple to implement. But a Google Sign-In that has never been linked to this Firebase account creates a new UID — all existing Sales, Buyers, Repairs, and photos become unreachable under the old UID. A manual data migration would be required, and there is no safe automatic path to merge two Firebase accounts.

**Account linking (chosen):** While the seller is signed in with email/password, `linkWithCredential` adds Google as a second provider on the same account. The UID is preserved; Drive access is granted through the same session. Both email/password and Google Sign-In continue to work after linking — email/password is kept as a fallback until Google Sign-In is proven stable on both devices.

## Trade-offs to watch

- `linkWithCredential` throws `credential-already-in-use` if the Google account is already attached to a *different* Firebase account. This error must be surfaced clearly to the seller — never swallowed silently — as it indicates an account conflict that requires manual resolution.
- Email/password is intentionally kept after linking. Removing it is a separate, deliberate step taken only once Google Sign-In is confirmed reliable on both devices.

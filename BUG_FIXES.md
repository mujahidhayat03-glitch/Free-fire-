# FF Pro Arena PK — Bug Fixes

## Bug #1 — Double `init()` call (Critical)
**File:** `lib/screens/splash_screen.dart`

`main.dart` already calls `AppProvider()..init()`, which registers the
`authStateChanges` listener. `SplashScreen._navigate()` was calling
`provider.init()` again — registering the listener **twice**, causing
duplicate state updates and unpredictable behavior.

**Fix:** Removed `provider.init()` from `_navigate()`.

---

## Bug #2 — Race condition: auth state not ready at navigation (Critical)
**File:** `lib/screens/splash_screen.dart`

The old code called `init()` then immediately checked `provider.currentUser`,
but the Firebase auth stream hadn't fired yet. `currentUser` was always `null`
at that point — so logged-in users were always sent to `LoginScreen`.

**Fix:** Added a polling loop that waits for `isInitializing == false` before
navigating. This guarantees the first auth event has been processed.

---

## Bug #3 — Missing `isInitializing` state (Critical)
**File:** `lib/providers/app_provider.dart`

No way to know when the first auth state had been determined. Splash had no
signal to wait for, causing the race condition above.

**Fix:** Added `_isInitializing = true` field, set to `false` on the first
auth event (either logged-in user loaded or logged-out state confirmed).

---

## Bug #4 — Non-atomic balance deduction in `joinTournament` (Critical)
**File:** `lib/services/services.dart`

Old code: read user balance → compute new value locally → write absolute value.
This is a classic read-modify-write race condition. If two join operations
fire at the same millisecond, both read the same balance and one deduction
is lost.

**Fix:** Use `ServerValue.increment(-amount)` for atomic server-side
deduction. Wallet and winning balances are each decremented atomically.

---

## Bug #5 — `rejectWithdrawal` missing — funds lost on rejection (Critical)
**File:** `lib/services/services.dart`

`submitWithdrawal` immediately deducts the user's `winningBalance` (optimistic).
But there was **no `rejectWithdrawal` method** — if an admin rejected a
withdrawal, the user's money was permanently lost.

**Fix:** Added `rejectWithdrawal(txId, adminNote)` that updates the status
AND refunds the amount back to `winningBalance` via `ServerValue.increment`.

---

## Bug #6 — Missing `userName` in withdrawal notification (Minor)
**File:** `lib/services/services.dart`

`submitDeposit` included `userName` in the admin notification.
`submitWithdrawal` did not — inconsistent and made admin tracking harder.

**Fix:** Added `'userName': tx.userName` to withdrawal notification payload.

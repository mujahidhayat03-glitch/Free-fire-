// functions/index.js
// Deploy with: firebase deploy --only functions

const functions = require("firebase-functions");
const admin     = require("firebase-admin");
admin.initializeApp();

const db  = admin.firestore();
const msg = admin.messaging();

// ── 1. Deposit Approval Notification ──────────────────────────────────────────
exports.onDepositApproved = functions.firestore
  .document("transactions/{txId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();
    if (before.status !== "pending" || after.status !== "approved") return;

    const userDoc = await db.collection("users").doc(after.userId).get();
    const token   = userDoc.data()?.fcmToken;
    if (!token) return;

    const isDeposit = after.type === "deposit";
    await msg.send({
      token,
      notification: {
        title: isDeposit ? "✅ Deposit Approved!" : "✅ Withdrawal Approved!",
        body: `Rs. ${after.amount} has been ${isDeposit ? "added to your wallet" : "sent to your account"}.`,
      },
      android: { priority: "high", notification: { color: "#00FF88" } },
    });
  });

// ── 2. Deposit Rejection Notification ─────────────────────────────────────────
exports.onDepositRejected = functions.firestore
  .document("transactions/{txId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();
    if (before.status !== "pending" || after.status !== "rejected") return;

    const userDoc = await db.collection("users").doc(after.userId).get();
    const token   = userDoc.data()?.fcmToken;
    if (!token) return;

    await msg.send({
      token,
      notification: {
        title: "❌ Transaction Rejected",
        body: after.adminNote || `Your ${after.type} of Rs. ${after.amount} was rejected.`,
      },
      android: { priority: "high", notification: { color: "#FF3D3D" } },
    });
  });

// ── 3. Broadcast Push Notification ────────────────────────────────────────────
exports.onBroadcast = functions.firestore
  .document("broadcasts/{bId}")
  .onCreate(async (snap, context) => {
    const data    = snap.data();
    const message = data.message;

    // Get all user FCM tokens
    const usersSnap = await db.collection("users")
      .where("isBanned", "==", false)
      .get();

    const tokens = usersSnap.docs
      .map(d => d.data().fcmToken)
      .filter(Boolean);

    if (tokens.length === 0) return;

    // Send in batches of 500
    const chunkSize = 500;
    for (let i = 0; i < tokens.length; i += chunkSize) {
      const chunk = tokens.slice(i, i + chunkSize);
      await msg.sendEachForMulticast({
        tokens: chunk,
        notification: {
          title: "📣 FF Pro Arena PK",
          body: message,
        },
        android: {
          priority: "high",
          notification: { color: "#FFD700", icon: "ic_notification" },
        },
      });
    }
  });

// ── 4. Tournament Room ID Notification ────────────────────────────────────────
exports.onRoomIdShared = functions.firestore
  .document("tournaments/{tId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();

    // Trigger only when roomVisible first becomes true
    if (before.roomVisible || !after.roomVisible) return;

    const joinedUsers = after.joinedUsers || [];
    if (joinedUsers.length === 0) return;

    // Get FCM tokens of joined users
    const userDocs = await Promise.all(
      joinedUsers.map(uid => db.collection("users").doc(uid).get())
    );
    const tokens = userDocs
      .map(d => d.data()?.fcmToken)
      .filter(Boolean);

    if (tokens.length === 0) return;

    // Send in batches
    const chunkSize = 500;
    for (let i = 0; i < tokens.length; i += chunkSize) {
      const chunk = tokens.slice(i, i + chunkSize);
      await msg.sendEachForMulticast({
        tokens: chunk,
        notification: {
          title: "🎮 Room ID Released!",
          body: `Room credentials for "${after.title}" are now available. Open the app!`,
        },
        android: {
          priority: "high",
          notification: { color: "#00FF88", icon: "ic_notification" },
        },
        data: { tournamentId: context.params.tId },
      });
    }
  });

// ── 5. New Deposit Request → Admin Notification ───────────────────────────────
exports.onNewDeposit = functions.firestore
  .document("notifications/{nId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (data.type !== "deposit_request") return;

    // Get admin FCM tokens
    const adminsSnap = await db.collection("users")
      .where("role", "==", "admin")
      .get();

    const tokens = adminsSnap.docs
      .map(d => d.data().fcmToken)
      .filter(Boolean);

    if (tokens.length === 0) return;

    await msg.sendEachForMulticast({
      tokens,
      notification: {
        title: "💰 New Deposit Request",
        body: `${data.userName} wants to deposit Rs. ${data.amount}.`,
      },
      android: { priority: "high" },
      data: { type: "deposit_request", transactionId: data.transactionId },
    });
  });

// ── 6. Cleanup old animations (runs every hour) ───────────────────────────────
exports.cleanupAnimations = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const now  = admin.firestore.Timestamp.now();
    const snap = await db.collection("animations")
      .where("expiresAt", "<", now)
      .get();
    const batch = db.batch();
    snap.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    console.log(`Deleted ${snap.size} expired animations`);
  });

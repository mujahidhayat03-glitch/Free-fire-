// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register ───────────────────────────────────────────────────────────────
  Future<UserModel?> register({
    required String mobile,
    required String password,
    required String freeFireUid,
    required String displayName,
  }) async {
    try {
      // Use mobile@ffpro.pk as fake email for Firebase Auth
      final email = '${mobile.replaceAll('+', '')}@ffproarenapk.app';
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      final user = UserModel(
        uid: cred.user!.uid,
        mobile: mobile,
        freeFireUid: freeFireUid,
        displayName: displayName,
        role: AppConstants.roleUser,
        createdAt: DateTime.now(),
        isOnline: true,
      );
      await _db.collection(AppConstants.usersCol)
               .doc(cred.user!.uid).set(user.toMap());
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<UserModel?> login({
    required String mobile,
    required String password,
  }) async {
    try {
      final email = '${mobile.replaceAll('+', '')}@ffproarenapk.app';
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      final doc = await _db.collection(AppConstants.usersCol)
                            .doc(cred.user!.uid).get();
      if (!doc.exists) return null;
      final user = UserModel.fromFirestore(doc);
      if (user.isBanned) {
        await _auth.signOut();
        throw Exception('Your account has been banned. Contact support.');
      }
      // Mark online & update FCM
      await _db.collection(AppConstants.usersCol).doc(cred.user!.uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      // Broadcast VIP/Admin login animation
      await _broadcastLoginAnimation(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout(String uid) async {
    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    await _auth.signOut();
  }

  // ── Broadcast login animation ──────────────────────────────────────────────
  Future<void> _broadcastLoginAnimation(UserModel user) async {
    if (!user.isVip) return;
    await _db.collection('animations').add({
      'type': user.isAdmin ? 'golden_commander' : 'silver_crown',
      'triggeredBy': user.uid,
      'userName': user.displayName,
      'userRole': user.role,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(seconds: 8))),
    });
  }

  // ── Get current user data ──────────────────────────────────────────────────
  Stream<UserModel?> userStream(String uid) {
    return _db.collection(AppConstants.usersCol).doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ── Update FCM token ───────────────────────────────────────────────────────
  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection(AppConstants.usersCol).doc(uid)
             .update({'fcmToken': token});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/services/firestore_service.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════ TOURNAMENTS ═══════════════════════════════════════════

  Stream<List<TournamentModel>> tournamentsStream({String? status}) {
    Query q = _db.collection(AppConstants.tournamentsCol)
                 .orderBy('scheduledAt');
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((snap) =>
        snap.docs.map(TournamentModel.fromFirestore).toList());
  }

  Future<TournamentModel?> getTournament(String id) async {
    final doc = await _db.collection(AppConstants.tournamentsCol).doc(id).get();
    return doc.exists ? TournamentModel.fromFirestore(doc) : null;
  }

  Future<String> createTournament(TournamentModel t) async {
    final ref = await _db.collection(AppConstants.tournamentsCol).add(t.toMap());
    return ref.id;
  }

  Future<void> updateTournament(String id, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.tournamentsCol).doc(id).update(data);
  }

  Future<void> deleteTournament(String id) async {
    await _db.collection(AppConstants.tournamentsCol).doc(id).delete();
  }

  Future<bool> joinTournament({
    required String tournamentId,
    required String userId,
    required double entryFee,
  }) async {
    return _db.runTransaction((tx) async {
      final tRef = _db.collection(AppConstants.tournamentsCol).doc(tournamentId);
      final uRef = _db.collection(AppConstants.usersCol).doc(userId);
      final tSnap = await tx.get(tRef);
      final uSnap = await tx.get(uRef);
      final t = TournamentModel.fromFirestore(tSnap);
      final u = UserModel.fromFirestore(uSnap);
      if (t.isFull) throw Exception('Tournament is full!');
      if (t.joinedUsers.contains(userId)) throw Exception('Already joined!');
      if (u.totalBalance < entryFee) throw Exception('Insufficient balance!');
      // Deduct from wallet (prefer walletBalance first)
      double walBal = u.walletBalance;
      double winBal = u.winningBalance;
      if (walBal >= entryFee) {
        walBal -= entryFee;
      } else {
        final rem = entryFee - walBal;
        walBal = 0; winBal -= rem;
      }
      tx.update(tRef, {
        'filledSlots': FieldValue.increment(1),
        'joinedUsers': FieldValue.arrayUnion([userId]),
      });
      tx.update(uRef, {
        'walletBalance': walBal,
        'winningBalance': winBal,
        'joinedTournaments': FieldValue.arrayUnion([tournamentId]),
      });
      // Log transaction
      final txRef = _db.collection(AppConstants.transactionsCol).doc();
      tx.set(txRef, {
        'userId': userId, 'userName': u.displayName,
        'type': 'tournament_entry', 'amount': -entryFee,
        'status': 'approved',
        'note': 'Entry fee - ${t.title}',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> updateRoomInfo(String tournamentId, String roomId, String pass) async {
    await _db.collection(AppConstants.tournamentsCol).doc(tournamentId).update({
      'roomId': roomId,
      'roomPassword': pass,
      'roomVisible': true,
    });
  }

  // ═══════════════════ CHAT ══════════════════════════════════════════════════

  Stream<List<MessageModel>> messagesStream({int limit = 60}) {
    return _db.collection(AppConstants.messagesCol)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(MessageModel.fromFirestore).toList().reversed.toList());
  }

  Stream<MessageModel?> pinnedMessageStream() {
    return _db.collection(AppConstants.messagesCol)
        .where('isPinned', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isNotEmpty ? MessageModel.fromFirestore(s.docs.first) : null);
  }

  Future<void> sendMessage(MessageModel msg) async {
    await _db.collection(AppConstants.messagesCol).add(msg.toMap());
  }

  Future<void> deleteMessage(String msgId) async {
    await _db.collection(AppConstants.messagesCol).doc(msgId).update({
      'isDeleted': true, 'content': 'This message was deleted.',
    });
  }

  Future<void> pinMessage(String msgId) async {
    // Unpin all first
    final pinned = await _db.collection(AppConstants.messagesCol)
        .where('isPinned', isEqualTo: true).get();
    final batch = _db.batch();
    for (final doc in pinned.docs) batch.update(doc.reference, {'isPinned': false});
    batch.update(_db.collection(AppConstants.messagesCol).doc(msgId), {'isPinned': true});
    await batch.commit();
  }

  // ═══════════════════ USERS (ADMIN) ═════════════════════════════════════════

  Stream<List<UserModel>> allUsersStream() {
    return _db.collection(AppConstants.usersCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(UserModel.fromFirestore).toList());
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final snap = await _db.collection(AppConstants.usersCol).get();
    final q = query.toLowerCase();
    return snap.docs
        .map(UserModel.fromFirestore)
        .where((u) =>
            u.displayName.toLowerCase().contains(q) ||
            u.mobile.contains(q) ||
            u.freeFireUid.contains(q))
        .toList();
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection(AppConstants.usersCol).doc(uid).update({'role': role});
  }

  Future<void> banUser(String uid, bool ban) async {
    await _db.collection(AppConstants.usersCol).doc(uid)
             .update({'isBanned': ban});
  }

  Future<void> muteUser(String uid, bool mute) async {
    await _db.collection(AppConstants.usersCol).doc(uid)
             .update({'isMuted': mute});
  }

  Future<void> adjustBalance(String uid, double walletDelta, double winningDelta) async {
    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'walletBalance': FieldValue.increment(walletDelta),
      'winningBalance': FieldValue.increment(winningDelta),
    });
  }

  // ═══════════════════ TRANSACTIONS ══════════════════════════════════════════

  Stream<List<TransactionModel>> transactionsStream(String userId) {
    return _db.collection(AppConstants.transactionsCol)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TransactionModel.fromFirestore).toList());
  }

  Stream<List<TransactionModel>> pendingTransactionsStream() {
    return _db.collection(AppConstants.transactionsCol)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TransactionModel.fromFirestore).toList());
  }

  Future<String> submitDeposit(TransactionModel tx) async {
    final ref = await _db.collection(AppConstants.transactionsCol).add(tx.toMap());
    // Notify admin via Firestore trigger
    await _db.collection('notifications').add({
      'type': 'deposit_request',
      'transactionId': ref.id,
      'userId': tx.userId,
      'userName': tx.userName,
      'amount': tx.amount,
      'status': 'unread',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> approveDeposit(TransactionModel tx) async {
    final batch = _db.batch();
    batch.update(_db.collection(AppConstants.transactionsCol).doc(tx.id), {
      'status': 'approved', 'processedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection(AppConstants.usersCol).doc(tx.userId), {
      'walletBalance': FieldValue.increment(tx.amount),
    });
    await batch.commit();
  }

  Future<void> rejectDeposit(String txId, String adminNote) async {
    await _db.collection(AppConstants.transactionsCol).doc(txId).update({
      'status': 'rejected',
      'adminNote': adminNote,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> submitWithdrawal(TransactionModel tx) async {
    // Lock balance first
    await _db.collection(AppConstants.usersCol).doc(tx.userId).update({
      'winningBalance': FieldValue.increment(-tx.amount),
    });
    final ref = await _db.collection(AppConstants.transactionsCol).add(tx.toMap());
    await _db.collection('notifications').add({
      'type': 'withdrawal_request',
      'transactionId': ref.id,
      'userId': tx.userId,
      'amount': tx.amount,
      'status': 'unread',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> approveWithdrawal(String txId) async {
    await _db.collection(AppConstants.transactionsCol).doc(txId).update({
      'status': 'approved', 'processedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════ BROADCAST ═════════════════════════════════════════════

  Future<void> sendBroadcast(String message, String adminId) async {
    // Send as system message in chat
    await _db.collection(AppConstants.messagesCol).add({
      'senderId': adminId, 'senderName': 'FF PRO ARENA PK',
      'senderRole': 'admin', 'content': message,
      'type': 'system', 'isPinned': false, 'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Push notification document (Cloud Function picks it up)
    await _db.collection('broadcasts').add({
      'message': message, 'adminId': adminId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════ TYPING INDICATOR ══════════════════════════════════════

  Future<void> setTyping(String uid, bool isTyping) async {
    await _db.collection('typing').doc(uid).set({
      'uid': uid, 'isTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> typingUsersStream(String currentUid) {
    return _db.collection('typing')
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => d.id)
            .where((id) => id != currentUid)
            .toList());
  }

  // ═══════════════════ ANIMATIONS ════════════════════════════════════════════

  Stream<Map<String, dynamic>?> loginAnimationStream() {
    return _db.collection('animations')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) {
      if (s.docs.isEmpty) return null;
      final d = s.docs.first.data();
      final expires = (d['expiresAt'] as Timestamp?)?.toDate();
      if (expires != null && DateTime.now().isAfter(expires)) return null;
      return d;
    });
  }
}

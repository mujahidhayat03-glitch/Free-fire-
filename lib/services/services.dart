// lib/services/services.dart  –– Firebase Realtime Database version
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthService
// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  DatabaseReference _usersRef() => _rtdb.ref(AppConstants.usersCol);

  // ── Register ───────────────────────────────────────────────────────────────
  Future<UserModel?> register({
    required String mobile,
    required String password,
    required String freeFireUid,
    required String displayName,
  }) async {
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
    final map = user.toMap();
    map['createdAt'] = ServerValue.timestamp;
    await _usersRef().child(cred.user!.uid).set(map);
    return user;
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<UserModel?> login({
    required String mobile,
    required String password,
  }) async {
    final email = '${mobile.replaceAll('+', '')}@ffproarenapk.app';
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    final snap = await _usersRef().child(cred.user!.uid).get();
    if (!snap.exists) return null;
    final user = UserModel.fromSnapshot(snap);
    if (user.isBanned) {
      await _auth.signOut();
      throw Exception('Your account has been banned. Contact support.');
    }
    await _usersRef().child(cred.user!.uid).update({
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
    });
    await _broadcastLoginAnimation(user);
    return user;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout(String uid) async {
    await _usersRef().child(uid).update({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });
    await _auth.signOut();
  }

  Future<void> _broadcastLoginAnimation(UserModel user) async {
    if (!user.isVip) return;
    final ref = _rtdb.ref('animations').push();
    await ref.set({
      'type': user.isAdmin ? 'golden_commander' : 'silver_crown',
      'triggeredBy': user.uid,
      'userName': user.displayName,
      'userRole': user.role,
      'createdAt': ServerValue.timestamp,
      'expiresAt': DateTime.now()
          .add(const Duration(seconds: 8))
          .millisecondsSinceEpoch,
    });
  }

  Stream<UserModel?> userStream(String uid) {
    return _usersRef().child(uid).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return UserModel.fromSnapshot(event.snapshot);
    });
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _usersRef().child(uid).update({'fcmToken': token});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreService  (now actually FirebaseService – Realtime DB)
// ─────────────────────────────────────────────────────────────────────────────
class FirestoreService {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  DatabaseReference _ref(String path) => _rtdb.ref(path);

  // ══════════════════ TOURNAMENTS ═══════════════════════════════════════════

  Stream<List<TournamentModel>> tournamentsStream({String? status}) {
    Query q = _ref(AppConstants.tournamentsCol).orderByChild('scheduledAt');
    return q.onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return [];
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      final list = map.entries
          .map((e) {
            final child = snap.child(e.key.toString());
            return TournamentModel.fromSnapshot(child);
          })
          .where((t) => status == null || t.status == status)
          .toList();
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return list;
    });
  }

  Future<TournamentModel?> getTournament(String id) async {
    final snap = await _ref('${AppConstants.tournamentsCol}/$id').get();
    return snap.exists ? TournamentModel.fromSnapshot(snap) : null;
  }

  Future<String> createTournament(TournamentModel t) async {
    final ref = _ref(AppConstants.tournamentsCol).push();
    final map = t.toMap();
    map['createdAt'] = ServerValue.timestamp;
    map['scheduledAt'] = t.scheduledAt.millisecondsSinceEpoch;
    await ref.set(map);
    return ref.key!;
  }

  Future<void> updateTournament(String id, Map<String, dynamic> data) async {
    await _ref('${AppConstants.tournamentsCol}/$id').update(data);
  }

  Future<void> deleteTournament(String id) async {
    await _ref('${AppConstants.tournamentsCol}/$id').remove();
  }

  Future<bool> joinTournament({
    required String tournamentId,
    required String userId,
    required double entryFee,
  }) async {
    final tSnap = await _ref('${AppConstants.tournamentsCol}/$tournamentId').get();
    final uSnap = await _ref('${AppConstants.usersCol}/$userId').get();
    if (!tSnap.exists || !uSnap.exists) throw Exception('Data not found!');

    final t = TournamentModel.fromSnapshot(tSnap);
    final u = UserModel.fromSnapshot(uSnap);

    if (t.isFull) throw Exception('Tournament is full!');
    if (t.joinedUsers.contains(userId)) throw Exception('Already joined!');
    if (u.totalBalance < entryFee) throw Exception('Insufficient balance!');

    // ✅ FIX #4: Use ServerValue.increment for atomic balance deduction.
    //    The old code read balances, computed locally, then wrote absolute
    //    values — a race condition if two operations fired simultaneously.
    //    We now split the deduction atomically across wallet → winning.
    double walletDeduct  = u.walletBalance >= entryFee ? entryFee : u.walletBalance;
    double winningDeduct = entryFee - walletDeduct;

    final txKey = _ref(AppConstants.transactionsCol).push().key!;
    final updates = <String, dynamic>{
      '${AppConstants.tournamentsCol}/$tournamentId/filledSlots':
          ServerValue.increment(1),
      '${AppConstants.tournamentsCol}/$tournamentId/joinedUsers/$userId': true,
      '${AppConstants.usersCol}/$userId/joinedTournaments/$tournamentId': true,
      '${AppConstants.transactionsCol}/$txKey': {
        'userId': userId, 'userName': u.displayName,
        'type': 'tournament_entry', 'amount': -entryFee,
        'status': 'approved',
        'note': 'Entry fee - ${t.title}',
        'createdAt': ServerValue.timestamp,
      },
    };
    if (walletDeduct  > 0) updates['${AppConstants.usersCol}/$userId/walletBalance']  = ServerValue.increment(-walletDeduct);
    if (winningDeduct > 0) updates['${AppConstants.usersCol}/$userId/winningBalance'] = ServerValue.increment(-winningDeduct);
    await _rtdb.ref().update(updates);
    return true;
  }

  Future<void> updateRoomInfo(
      String tournamentId, String roomId, String pass) async {
    await _ref('${AppConstants.tournamentsCol}/$tournamentId').update({
      'roomId': roomId,
      'roomPassword': pass,
      'roomVisible': true,
    });
  }

  // ══════════════════ CHAT ══════════════════════════════════════════════════

  Stream<List<MessageModel>> messagesStream({int limit = 60}) {
    return _ref(AppConstants.messagesCol)
        .orderByChild('createdAt')
        .limitToLast(limit)
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return [];
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      return map.entries
          .map((e) => MessageModel.fromSnapshot(snap.child(e.key.toString())))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

  Stream<MessageModel?> pinnedMessageStream() {
    return _ref(AppConstants.messagesCol)
        .orderByChild('isPinned')
        .equalTo(true)
        .limitToLast(1)
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return null;
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      if (map.isEmpty) return null;
      final key = map.keys.first.toString();
      return MessageModel.fromSnapshot(snap.child(key));
    });
  }

  Future<void> sendMessage(MessageModel msg) async {
    final ref = _ref(AppConstants.messagesCol).push();
    final map = msg.toMap();
    map['createdAt'] = ServerValue.timestamp;
    await ref.set(map);
  }

  Future<void> deleteMessage(String msgId) async {
    await _ref('${AppConstants.messagesCol}/$msgId').update({
      'isDeleted': true,
      'content': 'This message was deleted.',
    });
  }

  Future<void> pinMessage(String msgId) async {
    // Unpin all first
    final snap = await _ref(AppConstants.messagesCol)
        .orderByChild('isPinned')
        .equalTo(true)
        .get();
    final updates = <String, dynamic>{};
    if (snap.exists && snap.value != null) {
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      for (final key in map.keys) {
        updates['${AppConstants.messagesCol}/$key/isPinned'] = false;
      }
    }
    updates['${AppConstants.messagesCol}/$msgId/isPinned'] = true;
    await _rtdb.ref().update(updates);
  }

  // ══════════════════ USERS (ADMIN) ═════════════════════════════════════════

  Stream<List<UserModel>> allUsersStream() {
    return _ref(AppConstants.usersCol)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return [];
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      final list = map.entries
          .map((e) => UserModel.fromSnapshot(snap.child(e.key.toString())))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final snap = await _ref(AppConstants.usersCol).get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    final q = query.toLowerCase();
    return map.entries
        .map((e) => UserModel.fromSnapshot(snap.child(e.key.toString())))
        .where((u) =>
            u.displayName.toLowerCase().contains(q) ||
            u.mobile.contains(q) ||
            u.freeFireUid.contains(q))
        .toList();
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _ref('${AppConstants.usersCol}/$uid').update({'role': role});
  }

  Future<void> banUser(String uid, bool ban) async {
    await _ref('${AppConstants.usersCol}/$uid').update({'isBanned': ban});
  }

  Future<void> muteUser(String uid, bool mute) async {
    await _ref('${AppConstants.usersCol}/$uid').update({'isMuted': mute});
  }

  Future<void> adjustBalance(
      String uid, double walletDelta, double winningDelta) async {
    await _rtdb.ref().update({
      '${AppConstants.usersCol}/$uid/walletBalance':
          ServerValue.increment(walletDelta),
      '${AppConstants.usersCol}/$uid/winningBalance':
          ServerValue.increment(winningDelta),
    });
  }

  // ══════════════════ TRANSACTIONS ══════════════════════════════════════════

  Stream<List<TransactionModel>> transactionsStream(String userId) {
    return _ref(AppConstants.transactionsCol)
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return [];
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      final list = map.entries
          .map((e) =>
              TransactionModel.fromSnapshot(snap.child(e.key.toString())))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<TransactionModel>> pendingTransactionsStream() {
    return _ref(AppConstants.transactionsCol)
        .orderByChild('status')
        .equalTo('pending')
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return [];
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      final list = map.entries
          .map((e) =>
              TransactionModel.fromSnapshot(snap.child(e.key.toString())))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> submitDeposit(TransactionModel tx) async {
    final ref = _ref(AppConstants.transactionsCol).push();
    final map = tx.toMap();
    map['createdAt'] = ServerValue.timestamp;
    await ref.set(map);
    // Notification for admin
    await _ref('notifications').push().set({
      'type': 'deposit_request',
      'transactionId': ref.key,
      'userId': tx.userId,
      'userName': tx.userName,
      'amount': tx.amount,
      'status': 'unread',
      'createdAt': ServerValue.timestamp,
    });
    return ref.key!;
  }

  Future<void> approveDeposit(TransactionModel tx) async {
    await _rtdb.ref().update({
      '${AppConstants.transactionsCol}/${tx.id}/status': 'approved',
      '${AppConstants.transactionsCol}/${tx.id}/processedAt':
          ServerValue.timestamp,
      '${AppConstants.usersCol}/${tx.userId}/walletBalance':
          ServerValue.increment(tx.amount),
    });
  }

  Future<void> rejectDeposit(String txId, String adminNote) async {
    await _ref('${AppConstants.transactionsCol}/$txId').update({
      'status': 'rejected',
      'adminNote': adminNote,
      'processedAt': ServerValue.timestamp,
    });
  }

  Future<String> submitWithdrawal(TransactionModel tx) async {
    final ref = _ref(AppConstants.transactionsCol).push();
    final map = tx.toMap();
    map['createdAt'] = ServerValue.timestamp;
    await _rtdb.ref().update({
      '${AppConstants.usersCol}/${tx.userId}/winningBalance':
          ServerValue.increment(-tx.amount),
      '${AppConstants.transactionsCol}/${ref.key}': map,
    });
    // ✅ FIX #6: Added missing userName field to withdrawal notification
    //    (deposit notification included it; withdrawal did not — inconsistent)
    await _ref('notifications').push().set({
      'type': 'withdrawal_request',
      'transactionId': ref.key,
      'userId': tx.userId,
      'userName': tx.userName,   // ✅ added
      'amount': tx.amount,
      'status': 'unread',
      'createdAt': ServerValue.timestamp,
    });
    return ref.key!;
  }

  Future<void> approveWithdrawal(String txId) async {
    await _ref('${AppConstants.transactionsCol}/$txId').update({
      'status': 'approved',
      'processedAt': ServerValue.timestamp,
    });
  }

  // ✅ FIX #5: rejectWithdrawal was missing. submitWithdrawal deducts balance
  //    immediately (optimistic). If admin rejects, we must REFUND the user.
  Future<void> rejectWithdrawal(String txId, String adminNote) async {
    final snap = await _ref('${AppConstants.transactionsCol}/$txId').get();
    if (!snap.exists) throw Exception('Transaction not found');
    final tx = TransactionModel.fromSnapshot(snap);
    await _rtdb.ref().update({
      '${AppConstants.transactionsCol}/$txId/status': 'rejected',
      '${AppConstants.transactionsCol}/$txId/adminNote': adminNote,
      '${AppConstants.transactionsCol}/$txId/processedAt': ServerValue.timestamp,
      // ✅ Refund the deducted amount back to winning balance
      '${AppConstants.usersCol}/${tx.userId}/winningBalance':
          ServerValue.increment(tx.amount),
    });
  }

  // ══════════════════ BROADCAST ══════════════════════════════════════════════

  Future<void> sendBroadcast(String message, String adminId) async {
    final msgRef = _ref(AppConstants.messagesCol).push();
    final bcRef  = _ref('broadcasts').push();
    await _rtdb.ref().update({
      '${AppConstants.messagesCol}/${msgRef.key}': {
        'senderId': adminId,
        'senderName': 'FF PRO ARENA PK',
        'senderRole': 'admin',
        'content': message,
        'type': 'system',
        'isPinned': false,
        'isDeleted': false,
        'createdAt': ServerValue.timestamp,
      },
      'broadcasts/${bcRef.key}': {
        'message': message,
        'adminId': adminId,
        'createdAt': ServerValue.timestamp,
      },
    });
  }

  // ══════════════════ TYPING INDICATOR ══════════════════════════════════════

  Future<void> setTyping(String uid, bool isTyping) async {
    await _ref('typing/$uid').update({
      'uid': uid,
      'isTyping': isTyping,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Stream<List<String>> typingUsersStream(String currentUid) {
    return _ref('typing').orderByChild('isTyping').equalTo(true).onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return [];
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      return map.keys
          .map((k) => k.toString())
          .where((id) => id != currentUid)
          .toList();
    });
  }

  // ══════════════════ ANIMATIONS ═════════════════════════════════════════════

  Stream<Map<String, dynamic>?> loginAnimationStream() {
    return _ref('animations').orderByChild('createdAt').limitToLast(1).onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return null;
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      if (map.isEmpty) return null;
      final key = map.keys.last.toString();
      final d = Map<String, dynamic>.from(map[key] as Map);
      final expires = d['expiresAt'];
      if (expires != null) {
        final expDate = DateTime.fromMillisecondsSinceEpoch(
            expires is int ? expires : (expires as num).toInt());
        if (DateTime.now().isAfter(expDate)) return null;
      }
      return d;
    });
  }

  // ══════════════════ PAYMENT SETTINGS ══════════════════════════════════════

  Future<void> savePaymentNumbers({
    required String jazzCash,
    required String easyPaisa,
  }) async {
    await _rtdb.ref('settings/payment').update({
      'jazzCash':  jazzCash.trim(),
      'easyPaisa': easyPaisa.trim(),
      'updatedAt': ServerValue.timestamp,
    });
  }

  Stream<Map<String, String>> paymentNumbersStream() {
    return _rtdb.ref('settings/payment').onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) {
        return {'jazzCash': '0300-0000000', 'easyPaisa': '0300-0000000'};
      }
      final m = Map<String, dynamic>.from(snap.value as Map);
      return {
        'jazzCash':  m['jazzCash']?.toString()  ?? '0300-0000000',
        'easyPaisa': m['easyPaisa']?.toString() ?? '0300-0000000',
      };
    });
  }
}

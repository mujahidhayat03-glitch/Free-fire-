// lib/models/models.dart  –– Firebase Realtime Database version
import 'package:firebase_database/firebase_database.dart';

// ── Helper ─────────────────────────────────────────────────────────────────────
DateTime _tsToDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return DateTime.fromMillisecondsSinceEpoch((v as num).toInt());
}

DateTime? _tsToDateNullable(dynamic v) {
  if (v == null) return null;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return DateTime.fromMillisecondsSinceEpoch((v as num).toInt());
}

List<String> _mapToList(dynamic v) {
  if (v == null) return [];
  if (v is List) return List<String>.from(v);
  if (v is Map) return v.values.map((e) => e.toString()).toList();
  return [];
}

// ── UserModel ──────────────────────────────────────────────────────────────────
class UserModel {
  final String uid;
  final String mobile;
  final String freeFireUid;
  final String displayName;
  final String role;
  final double walletBalance;
  final double winningBalance;
  final String? avatarUrl;
  final bool isOnline;
  final bool isBanned;
  final bool isMuted;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final List<String> joinedTournaments;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.mobile,
    required this.freeFireUid,
    required this.displayName,
    required this.role,
    this.walletBalance = 0.0,
    this.winningBalance = 0.0,
    this.avatarUrl,
    this.isOnline = false,
    this.isBanned = false,
    this.isMuted = false,
    required this.createdAt,
    this.lastSeen,
    this.joinedTournaments = const [],
    this.fcmToken,
  });

  bool get isAdmin => role == 'admin';
  bool get isVip => role == 'vip' || role == 'admin';
  double get totalBalance => walletBalance + winningBalance;

  factory UserModel.fromSnapshot(DataSnapshot snap) {
    final d = Map<dynamic, dynamic>.from(snap.value as Map? ?? {});
    return UserModel(
      uid: snap.key ?? '',
      mobile: (d['mobile'] ?? '').toString(),
      freeFireUid: (d['freeFireUid'] ?? '').toString(),
      displayName: (d['displayName'] ?? 'Player').toString(),
      role: (d['role'] ?? 'user').toString(),
      walletBalance: (d['walletBalance'] ?? 0).toDouble(),
      winningBalance: (d['winningBalance'] ?? 0).toDouble(),
      avatarUrl: d['avatarUrl']?.toString(),
      isOnline: d['isOnline'] ?? false,
      isBanned: d['isBanned'] ?? false,
      isMuted: d['isMuted'] ?? false,
      createdAt: _tsToDate(d['createdAt']),
      lastSeen: _tsToDateNullable(d['lastSeen']),
      joinedTournaments: _mapToList(d['joinedTournaments']),
      fcmToken: d['fcmToken']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'mobile': mobile,
    'freeFireUid': freeFireUid,
    'displayName': displayName,
    'role': role,
    'walletBalance': walletBalance,
    'winningBalance': winningBalance,
    'avatarUrl': avatarUrl,
    'isOnline': isOnline,
    'isBanned': isBanned,
    'isMuted': isMuted,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'lastSeen': lastSeen?.millisecondsSinceEpoch,
    'joinedTournaments': joinedTournaments.isEmpty
        ? null
        : {for (var t in joinedTournaments) t: true},
    'fcmToken': fcmToken,
  };

  UserModel copyWith({
    String? role, double? walletBalance, double? winningBalance,
    bool? isOnline, bool? isBanned, bool? isMuted,
    String? avatarUrl, String? fcmToken, List<String>? joinedTournaments,
  }) => UserModel(
    uid: uid, mobile: mobile, freeFireUid: freeFireUid,
    displayName: displayName, createdAt: createdAt,
    role: role ?? this.role,
    walletBalance: walletBalance ?? this.walletBalance,
    winningBalance: winningBalance ?? this.winningBalance,
    isOnline: isOnline ?? this.isOnline,
    isBanned: isBanned ?? this.isBanned,
    isMuted: isMuted ?? this.isMuted,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    fcmToken: fcmToken ?? this.fcmToken,
    joinedTournaments: joinedTournaments ?? this.joinedTournaments,
  );
}

// ── TournamentModel ────────────────────────────────────────────────────────────
class TournamentModel {
  final String id;
  final String title;
  final String map;
  final String mode;
  final double entryFee;
  final double prizePool;
  final int totalSlots;
  final int filledSlots;
  final String status;
  final DateTime scheduledAt;
  final String? bannerUrl;
  final String? roomId;
  final String? roomPassword;
  final bool roomVisible;
  final List<String> joinedUsers;
  final Map<String, dynamic> prizeDistribution;
  final String createdBy;
  final DateTime createdAt;

  TournamentModel({
    required this.id,
    required this.title,
    required this.map,
    required this.mode,
    required this.entryFee,
    required this.prizePool,
    required this.totalSlots,
    this.filledSlots = 0,
    this.status = 'upcoming',
    required this.scheduledAt,
    this.bannerUrl,
    this.roomId,
    this.roomPassword,
    this.roomVisible = false,
    this.joinedUsers = const [],
    this.prizeDistribution = const {},
    required this.createdBy,
    required this.createdAt,
  });

  int get slotsRemaining => totalSlots - filledSlots;
  bool get isFull => filledSlots >= totalSlots;
  double get fillPercentage => filledSlots / totalSlots;
  bool get isUpcoming => status == 'upcoming';
  bool get isLive => status == 'live';
  bool get isEnded => status == 'ended';

  String get mapEmoji {
    switch (map) {
      case 'Bermuda':    return '🏝️';
      case 'Purgatory':  return '🏔️';
      case 'Kalahari':   return '🏜️';
      case 'Alpine':     return '❄️';
      case 'Neextarra':  return '🌌';
      default:           return '🗺️';
    }
  }

  factory TournamentModel.fromSnapshot(DataSnapshot snap) {
    final d = Map<dynamic, dynamic>.from(snap.value as Map? ?? {});
    return TournamentModel(
      id: snap.key ?? '',
      title: (d['title'] ?? '').toString(),
      map: (d['map'] ?? 'Bermuda').toString(),
      mode: (d['mode'] ?? 'Squad').toString(),
      entryFee: (d['entryFee'] ?? 0).toDouble(),
      prizePool: (d['prizePool'] ?? 0).toDouble(),
      totalSlots: (d['totalSlots'] ?? 100) as int,
      filledSlots: (d['filledSlots'] ?? 0) as int,
      status: (d['status'] ?? 'upcoming').toString(),
      scheduledAt: _tsToDate(d['scheduledAt']),
      bannerUrl: d['bannerUrl']?.toString(),
      roomId: d['roomId']?.toString(),
      roomPassword: d['roomPassword']?.toString(),
      roomVisible: d['roomVisible'] ?? false,
      joinedUsers: _mapToList(d['joinedUsers']),
      prizeDistribution: d['prizeDistribution'] != null
          ? Map<String, dynamic>.from(d['prizeDistribution'] as Map)
          : {},
      createdBy: (d['createdBy'] ?? '').toString(),
      createdAt: _tsToDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title, 'map': map, 'mode': mode,
    'entryFee': entryFee, 'prizePool': prizePool,
    'totalSlots': totalSlots, 'filledSlots': filledSlots,
    'status': status,
    'scheduledAt': scheduledAt.millisecondsSinceEpoch,
    'bannerUrl': bannerUrl, 'roomId': roomId,
    'roomPassword': roomPassword, 'roomVisible': roomVisible,
    'joinedUsers': joinedUsers.isEmpty
        ? null
        : {for (var u in joinedUsers) u: true},
    'prizeDistribution': prizeDistribution,
    'createdBy': createdBy,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}

// ── MessageModel ───────────────────────────────────────────────────────────────
enum MessageType { text, image, voice, system }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final bool isPinned;
  final bool isDeleted;
  final String? mediaUrl;
  final int? audioDurationSec;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.senderAvatar,
    required this.content,
    required this.type,
    this.isPinned = false,
    this.isDeleted = false,
    this.mediaUrl,
    this.audioDurationSec,
    required this.createdAt,
  });

  bool get isAdmin => senderRole == 'admin';
  bool get isVip => senderRole == 'vip' || senderRole == 'admin';

  factory MessageModel.fromSnapshot(DataSnapshot snap) {
    final d = Map<dynamic, dynamic>.from(snap.value as Map? ?? {});
    return MessageModel(
      id: snap.key ?? '',
      senderId: (d['senderId'] ?? '').toString(),
      senderName: (d['senderName'] ?? 'Player').toString(),
      senderRole: (d['senderRole'] ?? 'user').toString(),
      senderAvatar: d['senderAvatar']?.toString(),
      content: (d['content'] ?? '').toString(),
      type: MessageType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'text').toString(),
        orElse: () => MessageType.text,
      ),
      isPinned: d['isPinned'] ?? false,
      isDeleted: d['isDeleted'] ?? false,
      mediaUrl: d['mediaUrl']?.toString(),
      audioDurationSec: d['audioDurationSec'] as int?,
      createdAt: _tsToDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId, 'senderName': senderName,
    'senderRole': senderRole, 'senderAvatar': senderAvatar,
    'content': content, 'type': type.name,
    'isPinned': isPinned, 'isDeleted': isDeleted,
    'mediaUrl': mediaUrl, 'audioDurationSec': audioDurationSec,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}

// ── TransactionModel ───────────────────────────────────────────────────────────
class TransactionModel {
  final String id;
  final String userId;
  final String userName;
  final String type;
  final double amount;
  final String status;
  final String? transactionId;
  final String? screenshotUrl;
  final String? mobileWallet;
  final String? mobileNumber;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.amount,
    required this.status,
    this.transactionId,
    this.screenshotUrl,
    this.mobileWallet,
    this.mobileNumber,
    this.adminNote,
    required this.createdAt,
    this.processedAt,
  });

  bool get isDeposit    => type == 'deposit';
  bool get isWithdrawal => type == 'withdrawal';
  bool get isPending    => status == 'pending';
  bool get isApproved   => status == 'approved';
  bool get isRejected   => status == 'rejected';

  factory TransactionModel.fromSnapshot(DataSnapshot snap) {
    final d = Map<dynamic, dynamic>.from(snap.value as Map? ?? {});
    return TransactionModel(
      id: snap.key ?? '',
      userId: (d['userId'] ?? '').toString(),
      userName: (d['userName'] ?? '').toString(),
      type: (d['type'] ?? 'deposit').toString(),
      amount: (d['amount'] ?? 0).toDouble(),
      status: (d['status'] ?? 'pending').toString(),
      transactionId: d['transactionId']?.toString(),
      screenshotUrl: d['screenshotUrl']?.toString(),
      mobileWallet: d['mobileWallet']?.toString(),
      mobileNumber: d['mobileNumber']?.toString(),
      adminNote: d['adminNote']?.toString(),
      createdAt: _tsToDate(d['createdAt']),
      processedAt: _tsToDateNullable(d['processedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId, 'userName': userName,
    'type': type, 'amount': amount, 'status': status,
    'transactionId': transactionId, 'screenshotUrl': screenshotUrl,
    'mobileWallet': mobileWallet, 'mobileNumber': mobileNumber,
    'adminNote': adminNote,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'processedAt': processedAt?.millisecondsSinceEpoch,
  };
}

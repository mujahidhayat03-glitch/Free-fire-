// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String mobile;
  final String freeFireUid;
  final String displayName;
  final String role; // user | vip | admin
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
  bool get isVip   => role == 'vip' || role == 'admin';
  double get totalBalance => walletBalance + winningBalance;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      mobile: data['mobile'] ?? '',
      freeFireUid: data['freeFireUid'] ?? '',
      displayName: data['displayName'] ?? 'Player',
      role: data['role'] ?? 'user',
      walletBalance: (data['walletBalance'] ?? 0).toDouble(),
      winningBalance: (data['winningBalance'] ?? 0).toDouble(),
      avatarUrl: data['avatarUrl'],
      isOnline: data['isOnline'] ?? false,
      isBanned: data['isBanned'] ?? false,
      isMuted: data['isMuted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      joinedTournaments: List<String>.from(data['joinedTournaments'] ?? []),
      fcmToken: data['fcmToken'],
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
    'createdAt': Timestamp.fromDate(createdAt),
    'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    'joinedTournaments': joinedTournaments,
    'fcmToken': fcmToken,
  };

  UserModel copyWith({
    String? role, double? walletBalance, double? winningBalance,
    bool? isOnline, bool? isBanned, bool? isMuted,
    String? avatarUrl, String? fcmToken,
    List<String>? joinedTournaments,
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

// ── Tournament Model ───────────────────────────────────────────────────────────
class TournamentModel {
  final String id;
  final String title;
  final String map;
  final String mode;
  final double entryFee;
  final double prizePool;
  final int totalSlots;
  final int filledSlots;
  final String status; // upcoming | live | ended
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
      case 'Bermuda':   return '🏝️';
      case 'Purgatory': return '🏔️';
      case 'Kalahari':  return '🏜️';
      case 'Alpine':    return '❄️';
      case 'Neextarra': return '🌌';
      default: return '🗺️';
    }
  }

  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TournamentModel(
      id: doc.id,
      title: d['title'] ?? '',
      map: d['map'] ?? 'Bermuda',
      mode: d['mode'] ?? 'Squad',
      entryFee: (d['entryFee'] ?? 0).toDouble(),
      prizePool: (d['prizePool'] ?? 0).toDouble(),
      totalSlots: d['totalSlots'] ?? 100,
      filledSlots: d['filledSlots'] ?? 0,
      status: d['status'] ?? 'upcoming',
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bannerUrl: d['bannerUrl'],
      roomId: d['roomId'],
      roomPassword: d['roomPassword'],
      roomVisible: d['roomVisible'] ?? false,
      joinedUsers: List<String>.from(d['joinedUsers'] ?? []),
      prizeDistribution: Map<String, dynamic>.from(d['prizeDistribution'] ?? {}),
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title, 'map': map, 'mode': mode,
    'entryFee': entryFee, 'prizePool': prizePool,
    'totalSlots': totalSlots, 'filledSlots': filledSlots,
    'status': status,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    'bannerUrl': bannerUrl, 'roomId': roomId,
    'roomPassword': roomPassword, 'roomVisible': roomVisible,
    'joinedUsers': joinedUsers,
    'prizeDistribution': prizeDistribution,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ── Message Model ──────────────────────────────────────────────────────────────
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
  bool get isVip   => senderRole == 'vip' || senderRole == 'admin';

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      senderName: d['senderName'] ?? 'Player',
      senderRole: d['senderRole'] ?? 'user',
      senderAvatar: d['senderAvatar'],
      content: d['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      isPinned: d['isPinned'] ?? false,
      isDeleted: d['isDeleted'] ?? false,
      mediaUrl: d['mediaUrl'],
      audioDurationSec: d['audioDurationSec'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId, 'senderName': senderName,
    'senderRole': senderRole, 'senderAvatar': senderAvatar,
    'content': content, 'type': type.name,
    'isPinned': isPinned, 'isDeleted': isDeleted,
    'mediaUrl': mediaUrl, 'audioDurationSec': audioDurationSec,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ── Transaction Model ──────────────────────────────────────────────────────────
class TransactionModel {
  final String id;
  final String userId;
  final String userName;
  final String type; // deposit | withdrawal | winning | bonus | deduction
  final double amount;
  final String status; // pending | approved | rejected
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

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? '',
      type: d['type'] ?? 'deposit',
      amount: (d['amount'] ?? 0).toDouble(),
      status: d['status'] ?? 'pending',
      transactionId: d['transactionId'],
      screenshotUrl: d['screenshotUrl'],
      mobileWallet: d['mobileWallet'],
      mobileNumber: d['mobileNumber'],
      adminNote: d['adminNote'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (d['processedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId, 'userName': userName,
    'type': type, 'amount': amount, 'status': status,
    'transactionId': transactionId, 'screenshotUrl': screenshotUrl,
    'mobileWallet': mobileWallet, 'mobileNumber': mobileNumber,
    'adminNote': adminNote,
    'createdAt': Timestamp.fromDate(createdAt),
    'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
  };
}

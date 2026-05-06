// lib/providers/app_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/services.dart';

class AppProvider extends ChangeNotifier {
  final AuthService      _authService      = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool       _isLoading = false;
  String?    _error;

  UserModel?      get currentUser  => _currentUser;
  bool            get isLoading    => _isLoading;
  String?         get error        => _error;
  FirestoreService get db          => _firestoreService;
  AuthService     get auth         => _authService;
  bool            get isLoggedIn   => _currentUser != null;
  bool            get isAdmin      => _currentUser?.isAdmin ?? false;
  bool            get isVip        => _currentUser?.isVip ?? false;

  // ── Init ───────────────────────────────────────────────────────────────────
  void init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listenToUser(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  void _listenToUser(String uid) {
    _authService.userStream(uid).listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  Future<bool> register({
    required String mobile,
    required String password,
    required String freeFireUid,
    required String displayName,
  }) async {
    _setLoading(true);
    try {
      await _authService.register(
        mobile: mobile, password: password,
        freeFireUid: freeFireUid, displayName: displayName,
      );
      _clearError();
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String mobile, required String password}) async {
    _setLoading(true);
    try {
      await _authService.login(mobile: mobile, password: password);
      _clearError();
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      await _authService.logout(_currentUser!.uid);
    }
  }

  // ── Tournaments ────────────────────────────────────────────────────────────
  Future<bool> joinTournament(TournamentModel t) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      await _firestoreService.joinTournament(
        tournamentId: t.id,
        userId: _currentUser!.uid,
        entryFee: t.entryFee,
      );
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String e)  { _error = e; notifyListeners(); }
  void _clearError()         { _error = null; }

  String _parseError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use': return 'Mobile number already registered.';
        case 'wrong-password':       return 'Incorrect password.';
        case 'user-not-found':       return 'Account not found.';
        case 'weak-password':        return 'Password too weak (min 6 chars).';
        default: return e.message ?? 'Authentication error.';
      }
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}

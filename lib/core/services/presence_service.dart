import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Tracks whether the current user is online by writing a heartbeat
/// (`lastActive`) to Firestore every [heartbeatInterval] while the app
/// is in the foreground and a user is signed in.
///
/// A user is considered "online" if `lastActive` is within the last
/// [onlineThreshold]. This avoids needing Firebase Realtime Database's
/// onDisconnect() while still surviving app kills reasonably well,
/// since a stale timestamp will simply age out of the "online" window.
///
/// Usage: call `PresenceService().initialize();` once, right after
/// `Firebase.initializeApp()` in main().
class PresenceService with WidgetsBindingObserver {
  PresenceService._internal();
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;

  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration onlineThreshold = Duration(minutes: 2);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _heartbeatTimer;
  StreamSubscription<User?>? _authSubscription;
  bool _observerAttached = false;
  String? _uid;

  void initialize() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      if (user != null) {
        _uid = user.uid;
        _startHeartbeat(user.uid);
      } else {
        final previousUid = _uid;
        _uid = null;
        _stopHeartbeat(previousUid);
      }
    });
  }

  void _startHeartbeat(String uid) {
    if (!_observerAttached) {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    }
    _pingNow(uid);
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) => _pingNow(uid));
  }

  void _pingNow(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .update({'lastActive': FieldValue.serverTimestamp(), 'isOnline': true})
        .catchError((_) {});
  }

  Future<void> _stopHeartbeat(String? uid) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'isOnline': false})
          .catchError((_) {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_uid == null) return;
    if (state == AppLifecycleState.resumed) {
      _startHeartbeat(_uid!);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _heartbeatTimer?.cancel();
      _firestore
          .collection('users')
          .doc(_uid!)
          .update({'isOnline': false})
          .catchError((_) {});
    }
  }

  void dispose() {
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
    _authSubscription?.cancel();
    _heartbeatTimer?.cancel();
  }
}

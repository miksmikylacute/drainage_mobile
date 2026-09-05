import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._internal();

  ConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  bool _hasEverBeenOffline = false;
  bool _showRestoredBanner = false;
  bool get showRestoredBanner => _showRestoredBanner;

  Timer? _restoredTimer;

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    checkConnection();
  }

  Future<void> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateStatus(results);
    } catch (_) {}
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    final hasNoInterface = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);

    bool offline = hasNoInterface;

    // If interface is active, optionally verify host reachability on mobile
    if (!offline && !kIsWeb) {
      try {
        final lookup = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        if (lookup.isEmpty || lookup.first.rawAddress.isEmpty) {
          offline = true;
        }
      } catch (_) {
        offline = true;
      }
    }

    if (offline != _isOffline) {
      _isOffline = offline;

      if (_isOffline) {
        _hasEverBeenOffline = true;
        _showRestoredBanner = false;
        _restoredTimer?.cancel();
      } else if (_hasEverBeenOffline) {
        // Just restored!
        _showRestoredBanner = true;
        _restoredTimer?.cancel();
        _restoredTimer = Timer(const Duration(seconds: 3), () {
          _showRestoredBanner = false;
          notifyListeners();
        });
      }

      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _restoredTimer?.cancel();
    super.dispose();
  }
}

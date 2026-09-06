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
  Timer? _pollingTimer;
  final List<Timer> _retryTimers = [];

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChanged);
    checkConnection();
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    _cancelRetryTimers();
    _updateStatus(results);

    // If interface appears connected, schedule fast follow-up checks
    // to catch the connection as soon as mobile DNS/routing completes.
    final hasInterface = results.isNotEmpty &&
        !(results.length == 1 && results.first == ConnectivityResult.none);
    if (hasInterface) {
      _retryTimers.add(Timer(const Duration(milliseconds: 700), checkConnection));
      _retryTimers.add(Timer(const Duration(milliseconds: 1600), checkConnection));
      _retryTimers.add(Timer(const Duration(milliseconds: 2800), checkConnection));
    }
  }

  void _cancelRetryTimers() {
    for (final timer in _retryTimers) {
      timer.cancel();
    }
    _retryTimers.clear();
  }

  Future<void> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateStatus(results);
    } catch (_) {}
  }

  Future<bool> _verifyInternetAccess() async {
    if (kIsWeb) return true;

    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 1800));
      if (lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    // Fallback direct socket test to public DNS (bypasses DNS lookup delay)
    try {
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: const Duration(milliseconds: 1800),
      );
      socket.destroy();
      return true;
    } catch (_) {}

    return false;
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    final hasNoInterface = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);

    bool offline = hasNoInterface;

    if (!offline) {
      final hasInternet = await _verifyInternetAccess();
      offline = !hasInternet;
    }

    if (offline != _isOffline) {
      _isOffline = offline;

      if (_isOffline) {
        _hasEverBeenOffline = true;
        _showRestoredBanner = false;
        _restoredTimer?.cancel();
        _startPolling();
      } else {
        _stopPolling();
        _cancelRetryTimers();

        if (_hasEverBeenOffline) {
          _showRestoredBanner = true;
          _restoredTimer?.cancel();
          _restoredTimer = Timer(const Duration(seconds: 2), () {
            _showRestoredBanner = false;
            notifyListeners();
          });
        }
      }

      notifyListeners();
    } else if (!_isOffline) {
      // Already online, ensure polling is off
      _stopPolling();
    } else {
      // Still offline, ensure polling is running
      _startPolling();
    }
  }

  void _startPolling() {
    if (_pollingTimer?.isActive == true) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      checkConnection();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _restoredTimer?.cancel();
    _stopPolling();
    _cancelRetryTimers();
    super.dispose();
  }
}

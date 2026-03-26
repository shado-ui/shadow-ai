import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  bool _isSingleConnected(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
           result == ConnectivityResult.wifi ||
           result == ConnectivityResult.ethernet;
  }

  /// Returns true if device has an active internet connection
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _isSingleConnected(result);
  }

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_isSingleConnected);
  }
}


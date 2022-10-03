import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectionUtil {
  ConnectionUtil._() {
    _hasInternetInternetConnection();
    _connectivity.onConnectivityChanged.listen(_connectionChange);
  }
  static final ConnectionUtil _instance = ConnectionUtil._();

  static ConnectionUtil get instance {
    return _instance;
  }

  bool hasConnection = false;

  StreamController<bool> connectionChangeController = StreamController();

  final Connectivity _connectivity = Connectivity();

  Future<void> _connectionChange(ConnectivityResult result) async =>
      _hasInternetInternetConnection();

  Stream<bool> get connectionChange => connectionChangeController.stream;
  Future<bool> _hasInternetInternetConnection() async {
    /// wait for 2 seconds to check internet connection if there was not internet previously

    if (!hasConnection) {
      await Future.delayed(const Duration(seconds: 2));
    }

    hasConnection = await InternetConnectionChecker().hasConnection;
    if (Platform.isMacOS) {
      final List<String> addresses = [
        'example.com',
        'google.com',
        'bing.com',
        'yahoo.com'
      ];

      for (var address in addresses) {
        try {
          final result = await InternetAddress.lookup(address);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            hasConnection = true;
            break;
          }
        } on SocketException catch (_) {
          hasConnection = false;
        }
      }
    }
    connectionChangeController.add(hasConnection);

    return hasConnection;
  }

  void closeStream() {
    connectionChangeController.close();
  }
}

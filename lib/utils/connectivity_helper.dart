import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasNetworkConnection() async {
  final results = await Connectivity().checkConnectivity();
  if (results.isEmpty) return false;
  return !results.contains(ConnectivityResult.none);
}

import 'package:connection_status/src/connection_utill.dart';
import 'package:flutter/material.dart';

/// Callback to be called when the phone is in offline mode
typedef OfflineCallback = void Function();

/// Callback to be called when the phone is in online mode
typedef OnlineCallback = void Function();

/// Builder method with [isOnline] parameter to build widgets
/// in function of the connectivity status
typedef ConnectivityBuilder = Widget Function(
    BuildContext context, bool isOnline);

class ConnectionWidget extends StatefulWidget {
  final ConnectivityBuilder builder;

  final OnlineCallback? onlineCallback;
  final OfflineCallback? offlineCallback;
  final Widget? offlineBanner;
  final bool showOfflineBanner;
  final bool dismissOfflineBanner;

  const ConnectionWidget({
    Key? key,
    required this.builder,
    this.onlineCallback,
    this.offlineCallback,
    this.showOfflineBanner = true,
    this.dismissOfflineBanner = true,
    this.offlineBanner,
  }) : super(key: key);

  @override
  _ConnectionWidgetState createState() => _ConnectionWidgetState();
}

class _ConnectionWidgetState extends State<ConnectionWidget>
    with SingleTickerProviderStateMixin {
  bool? dontAnimate;

  late AnimationController animationController;

  @override
  void initState() {
    animationController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);

    if (dontAnimate == null && !(ConnectionUtil.instance.hasConnection)) {
      animationController.value = 1.0;
    }
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    ConnectionUtil.instance.closeStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: ConnectionUtil.instance.connectionChange,
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!) {
              animationController.reverse();
              if (widget.onlineCallback != null) widget.onlineCallback!();
            } else {
              animationController.forward();
              if (widget.offlineCallback != null) widget.offlineCallback!();
            }
          }
          return Stack(
            children: <Widget>[
              widget.builder(context, snapshot.data ?? true),
              if (widget.showOfflineBanner && !(snapshot.data ?? true))
                Align(
                  alignment: Alignment.bottomCenter,
                  child: widget.dismissOfflineBanner
                      ? SlideTransition(
                          position: animationController.drive(Tween<Offset>(
                            begin: const Offset(0.0, 1.0),
                            end: Offset.zero,
                          ).chain(CurveTween(
                            curve: Curves.fastOutSlowIn,
                          ))),
                          child: Material(
                              child: widget.offlineBanner ??
                                  _NoConnectivityBanner()))
                      : widget.offlineBanner ?? _NoConnectivityBanner(),
                )
            ],
          );
        });
  }
}

/// Default Banner for offline mode
class _NoConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          color: Colors.red,
          child: const Text(
            "No internet connection",
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          )),
    );
  }
}

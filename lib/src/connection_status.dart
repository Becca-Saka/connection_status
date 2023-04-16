import 'package:connection_status/src/connection_util.dart';
import 'package:flutter/material.dart';

/// Callback to be called when the phone is in offline mode
typedef OfflineCallback = void Function();

/// Callback to be called when the phone is in online mode
typedef OnlineCallback = void Function();

/// Builder method with [isOnline] parameter to build widgets
/// in function of the connectivity status
typedef ConnectivityBuilder = Widget Function(
    BuildContext context, bool isOnline);

/// This is an enum type called [OfflineBannerType]. It contains two
/// possible values: [overlay] and [docked], which can be used to represent the
/// display type of an offline banner. The overlay value represents an offline
/// banner that appears as an overlay, while the docked value represents an
/// offline banner that is docked to a specific position on the screen.
enum OfflineBannerType { overlay, docked }

/// This enum can be used to set the vertical position of the offline banner.
/// This is an enumeration of two positions, [top] and [bottom], for an offline
/// banner that can be displayed in a user interface.
enum OfflineBannerPosition { top, bottom }

class ConnectionWidget extends StatefulWidget {
  final ConnectivityBuilder builder;

  final OnlineCallback? onlineCallback;
  final OfflineCallback? offlineCallback;
  final Widget? offlineBanner;
  final bool showOfflineBanner;
  final bool dismissOfflineBanner;
  final OfflineBannerType bannerType;
  final OfflineBannerPosition bannerPosition;

  const ConnectionWidget({
    Key? key,
    required this.builder,
    this.onlineCallback,
    this.offlineCallback,
    this.showOfflineBanner = true,
    this.dismissOfflineBanner = true,
    this.offlineBanner,
    this.bannerType = OfflineBannerType.docked,
    this.bannerPosition = OfflineBannerPosition.top,
  }) : super(key: key);

  @override
  State<ConnectionWidget> createState() => _ConnectionWidgetState();
}

class _ConnectionWidgetState extends State<ConnectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> anim;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    anim = Tween<double>(begin: 0, end: 1).animate(animationController);
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
        return LayoutWidget(
          bannerType: widget.bannerType,
          bannerPosition: widget.bannerPosition,
          bannerWidget: SizeTransition(
            sizeFactor: anim,
            child: widget.offlineBanner ??
                _NoConnectivityBanner(
                  hasSafeArea:
                      widget.bannerPosition == OfflineBannerPosition.top,
                ),
          ),
          child: widget.builder(context, snapshot.data ?? true),
        );
      },
    );
  }
}

class LayoutWidget extends StatelessWidget {
  final OfflineBannerType bannerType;
  final OfflineBannerPosition bannerPosition;
  final Widget child;
  final Widget? bannerWidget;

  const LayoutWidget({
    Key? key,
    required this.bannerType,
    required this.bannerPosition,
    required this.child,
    this.bannerWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (bannerType) {
      // Will limit when there is no definite sized box
      case OfflineBannerType.overlay:
        return Stack(
          children: <Widget>[
            child,
            if (bannerWidget != null)
              Align(
                alignment: bannerPosition == OfflineBannerPosition.bottom
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: bannerWidget!,
              ),
          ],
        );
      case OfflineBannerType.docked:
        return Column(
          verticalDirection: bannerPosition == OfflineBannerPosition.bottom
              ? VerticalDirection.down
              : VerticalDirection.up,
          children: [
            Expanded(child: child),
            if (bannerWidget != null) bannerWidget!,
          ],
        );
    }
  }
}

/// Default Banner for offline mode
class _NoConnectivityBanner extends StatelessWidget {
  final bool hasSafeArea;
  const _NoConnectivityBanner({
    Key? key,
    required this.hasSafeArea,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: hasSafeArea,
      bottom: false,
      child: Material(
        child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          color: Colors.red,
          child: Text(
            "No internet connection",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

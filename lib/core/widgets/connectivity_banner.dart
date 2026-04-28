import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../providers/connectivity_provider.dart';

class ConnectivityBannerWrapper extends ConsumerWidget {
  final Widget child;

  const ConnectivityBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return Stack(
      children: [
        child,
        connectivityAsync.when(
          data: (results) {
            // In connectivity_plus 6.x, onConnectivityChanged returns a List<ConnectivityResult>
            final isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
            return _OfflineBanner(isVisible: isOffline);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final bool isVisible;

  const _OfflineBanner({required this.isVisible});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      top: isVisible ? 0 : -(topPadding + 50),
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        child: Container(
          padding: EdgeInsets.only(top: topPadding + 4, bottom: 8),
          color: const Color(0xFFE53935), // Professional Dark Red
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'No internet connection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

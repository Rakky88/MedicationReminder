import 'package:flutter/material.dart';

/// An app bar whose surface tint and shadow appear smoothly while the page
/// scrolls underneath it.
class GradualAppBar extends StatefulWidget implements PreferredSizeWidget {
  const GradualAppBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.titleSpacing,
  });

  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? titleSpacing;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  State<GradualAppBar> createState() => _GradualAppBarState();
}

class _GradualAppBarState extends State<GradualAppBar> {
  ScrollNotificationObserverState? _scrollNotificationObserver;
  double _scrollProgress = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  @override
  void dispose() {
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification ||
        notification.metrics.axis != Axis.vertical) {
      return;
    }
    final linearProgress = (notification.metrics.extentBefore / 80)
        .clamp(0.0, 1.0)
        .toDouble();
    final progress = Curves.easeInOutCubic.transform(linearProgress);
    if (mounted && (progress - _scrollProgress).abs() > 0.001) {
      setState(() => _scrollProgress = progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = ElevationOverlay.applySurfaceTint(
      theme.colorScheme.surface,
      theme.colorScheme.surfaceTint,
      3 * _scrollProgress,
    );
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0.8 * _scrollProgress,
      shadowColor: theme.shadowColor.withValues(alpha: 0.16 * _scrollProgress),
      title: widget.title,
      actions: widget.actions,
      bottom: widget.bottom,
      titleSpacing: widget.titleSpacing,
    );
  }
}

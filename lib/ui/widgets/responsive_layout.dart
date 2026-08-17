import 'package:flutter/material.dart';

/// Breakpoints for responsive design.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Responsive layout helper that adapts content to screen size.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Breakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= Breakpoints.mobile && w < Breakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

  /// Max width for content on large screens.
  static double contentMaxWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= Breakpoints.desktop) return 900;
    if (w >= Breakpoints.tablet) return 700;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= Breakpoints.tablet && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// A card that expands to fill available width on desktop but stays compact on mobile.
class AdaptiveCard extends StatelessWidget {
  const AdaptiveCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 6,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

/// A responsive dialog that shows as bottom sheet on mobile, dialog on desktop.
Future<T?> showResponsiveDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  String? title,
}) {
  final isMobile = ResponsiveLayout.isMobile(context);
  if (isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
              Flexible(child: builder(ctx)),
            ],
          ),
        ),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: builder,
  );
}

/// Centers content and constrains it to a comfortable max width on large
/// screens. Fills the available height (so children with [Expanded] work) while
/// keeping the column horizontally centered. Apply to screen bodies for a
/// consistent, professional layout.
class CenteredBody extends StatelessWidget {
  const CenteredBody({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.contentMaxWidth(context),
            minHeight: constraints.maxHeight,
          ),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
        ),
      ),
    );
  }
}

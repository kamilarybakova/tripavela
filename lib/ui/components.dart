import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../l10n/copy.dart';
import '../domain/models.dart';

class PageFrame extends StatelessWidget {
  final ScrollController? controller;
  final String? title;
  final Widget child;
  final Widget? footer;
  final List<Widget>? actions;
  final Widget? leading;
  final bool scroll;
  const PageFrame({
    super.key,
    this.title,
    this.controller,
    required this.child,
    this.footer,
    this.actions,
    this.leading,
    this.scroll = true,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: title == null
        ? null
        : AppBar(
            titleSpacing: leading == null ? 20 : 4,
            title: Text(
              title!,
              style: Theme.of(context).appBarTheme.titleTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: leading,
            actions: actions,
          ),
    body: SafeArea(
      top: title == null,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 640),
          child: scroll
              ? SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: child,
                )
              : child,
        ),
      ),
    ),
    bottomNavigationBar: footer == null
        ? null
        : Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: BottomAction(child: footer!),
          ),
  );
}

class BottomAction extends StatelessWidget {
  final Widget child;
  const BottomAction({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  const Panel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? Theme.of(context).colorScheme.surface,
    elevation: .6,
    shadowColor: const Color(0xFF7D5738).withValues(alpha: .13),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Theme.of(context).dividerColor.withValues(alpha: .25),
      ),
    ),
    child: Container(width: double.infinity, padding: padding, child: child),
  );
}

/// Secondary information stays available without competing with the main action.
class DetailsFold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  const DetailsFold(
    this.title, {
    super.key,
    required this.children,
    this.initiallyExpanded = false,
  });
  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: initiallyExpanded,
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 16),
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    shape: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    collapsedShape: Border(
      bottom: BorderSide(color: Theme.of(context).dividerColor),
    ),
    title: Text(title, style: Theme.of(context).textTheme.titleSmall),
    children: [
      SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ],
  );
}

class Section extends StatelessWidget {
  final String title;
  final Widget? action;
  const Section(this.title, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 28, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: EditorialText(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            italicLast: false,
          ),
        ),
        ?action,
      ],
    ),
  );
}

class Photo extends StatelessWidget {
  final String asset;
  final double height;
  final double radius;
  const Photo(this.asset, {super.key, this.height = 190, this.radius = 20});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: asset.isEmpty
        ? fallback(context)
        : Image.asset(
            asset,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => fallback(context),
          ),
  );
  Widget fallback(BuildContext context) => Container(
    height: height,
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Center(
      child: Icon(
        Icons.local_florist_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class Tag extends StatelessWidget {
  final String text;
  final bool gold;
  const Tag(this.text, {super.key, this.gold = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: gold
          ? Palette.gold
          : Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: .3,
        color: gold ? Palette.ink : Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoLine(this.icon, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19),
        SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class WalkCard extends StatelessWidget {
  final WalkRoute route;
  final bool favorite;
  final bool nearby;
  final VoidCallback onTap, onFavorite;
  final String? reason;
  const WalkCard({
    super.key,
    required this.route,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
    this.reason,
    this.nearby = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      shadowColor: const Color(0xFF7D5738).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Photo(route.image, height: 190, radius: 16),
                  Positioned(
                    left: 12,
                    top: 12,
                    right: 66,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Tag(route.theme),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      tooltip: favorite ? copy.message243 : copy.message244,
                      style: IconButton.styleFrom(
                        backgroundColor: Palette.surface,
                        foregroundColor: Palette.clay,
                      ),
                      onPressed: onFavorite,
                      icon: Icon(
                        favorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 15, 4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reason != null) ...[
                      Tag(
                        nearby ? copy.nearbyShortBadge : copy.message245,
                        gold: true,
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: EditorialText(
                            route.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            italicLast: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      route.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Divider(height: 26),
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        _RouteMeta(
                          Icons.schedule_outlined,
                          copy.message185(
                            route.minutes.toString(),
                            route.maxMinutes.toString(),
                          ),
                        ),
                        _RouteMeta(
                          Icons.directions_walk_outlined,
                          copy.message246(
                            (route.meters / 1000).toStringAsFixed(1),
                          ),
                        ),
                        _RouteMeta(
                          Icons.payments_outlined,
                          route.requiredMax == 0 && route.foodMax == 0
                              ? copy.message171
                              : '≈ ${((route.requiredMin + route.foodMin) / 100).round()}–${((route.requiredMax + route.foodMax) / 100).round()} ${route.data['currencySymbol'] ?? '₺'}',
                        ),
                        _RouteMeta(Icons.place_outlined, copy.message187),
                      ],
                    ),
                    if (reason != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        reason!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RouteMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RouteMeta(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 14,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}

/// Real serif/italic typography, with a single semantic label for the title.
class EditorialText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool italicLast;
  final Color? accent;
  const EditorialText(
    this.text, {
    super.key,
    this.style,
    this.italicLast = true,
    this.accent,
  });
  @override
  Widget build(BuildContext context) {
    final split = text.lastIndexOf(' ');
    final base = style ?? Theme.of(context).textTheme.headlineLarge;
    return Text.rich(
      TextSpan(
        children: [
          if (!italicLast || split < 0)
            TextSpan(text: text)
          else ...[
            TextSpan(text: text.substring(0, split + 1)),
            TextSpan(
              text: text.substring(split + 1),
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: accent ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      style: base,
      semanticsLabel: text,
    );
  }
}

class JournalHero extends StatelessWidget {
  final String title, subtitle, image;
  final Widget action;
  const JournalHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
    this.image = 'assets/images/city.jpg',
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final paper = dark ? const Color(0xFF292522) : Palette.paper;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D4B30).withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, .33, .67, 1],
                    colors: [
                      paper,
                      paper.withValues(alpha: .97),
                      paper.withValues(alpha: .48),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRIPAVELA',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.7,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  EditorialText(
                    title,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 38,
                      height: 1.02,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 270),
                    child: action,
                  ),
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String title, text, button;
  final VoidCallback onTap;
  final IconData icon;
  const EmptyView({
    super.key,
    required this.title,
    required this.text,
    required this.button,
    required this.onTap,
    this.icon = Icons.explore_outlined,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Container(
          padding: EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 42),
        ),
        SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        SizedBox(height: 24),
        FilledButton(onPressed: onTap, child: Text(button)),
      ],
    ),
  );
}

class RouteSketch extends StatelessWidget {
  final List<String> labels;
  const RouteSketch(this.labels, {super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.message247, style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 16),
        for (var i = 0; i < labels.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  if (i < labels.length - 1)
                    Container(width: 2, height: 30, color: Palette.gold),
                ],
              ),
              SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 6, bottom: 20),
                  child: Text(labels[i]),
                ),
              ),
            ],
          ),
        Text(copy.message248, style: TextStyle(fontSize: 12)),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  static const _items = <_NavItem>[
    _NavItem(label: 'Home', route: '/home', icon: _SvgIcons.home),
    _NavItem(label: 'Sabaq', route: '/sabaq', icon: _SvgIcons.book),
    _NavItem(label: 'Irshad', route: '/irshadat', icon: _SvgIcons.heart),
    _NavItem(label: 'Gallery', route: '/gallery', icon: _SvgIcons.grid),
    _NavItem(label: 'Profile', route: '/profile', icon: _SvgIcons.user),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.backgroundSurface,
        border: Border(
          top: BorderSide(color: c.borderDefault, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Row(
        children: List.generate(_items.length, (i) {
          final selected = i == currentIndex;
          final item = _items[i];
          final iconColor = selected ? c.accentGold : c.textFaint;

          return Expanded(
            child: InkWell(
              onTap: () {
                if (!selected) context.go(item.route);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? c.backgroundElevated
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? c.borderDefault
                            : Colors.transparent,
                        width: 0.5,
                      ),
                    ),
                    child: SvgPicture.string(
                      item.icon,
                      width: 18,
                      height: 18,
                      colorFilter:
                          ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: iconColor.o(selected ? 1.0 : 0.85),
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.route, required this.icon});

  final String label;
  final String route;
  final String icon;
}

class _SvgIcons {
  static const home =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M3 10.5L12 3l9 7.5v9.5a1 1 0 0 1-1 1h-5.5v-6.5h-5V21H4a1 1 0 0 1-1-1v-9.5z" fill="currentColor"/></svg>';
  static const book =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M6 4h11a2 2 0 0 1 2 2v14a1 1 0 0 1-1.4.92C16.2 20.3 14.2 20 12 20s-4.2.3-5.6.92A1 1 0 0 1 5 20V6a2 2 0 0 1 1-2z" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M8 7h8M8 10h8M8 13h6" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>';
  static const heart =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 21s-7-4.6-9.5-9.3C.3 7.9 2.7 4.5 6.3 4.2c2-.2 3.7.9 5 2.4 1.3-1.5 3-2.6 5-2.4 3.6.3 6 3.7 3.8 7.5C19 16.4 12 21 12 21z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>';
  static const grid =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M4 4h7v7H4V4zm9 0h7v7h-7V4zM4 13h7v7H4v-7zm9 0h7v7h-7v-7z" fill="currentColor"/></svg>';
  static const user =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 12a4.2 4.2 0 1 0-4.2-4.2A4.2 4.2 0 0 0 12 12z" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M4.2 20.2c1.6-3.7 4.4-5.2 7.8-5.2s6.2 1.5 7.8 5.2" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>';
}


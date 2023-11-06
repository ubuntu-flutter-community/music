import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

import '../../constants.dart';
import 'icons.dart';

class NavBackButton extends StatelessWidget {
  const NavBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Platform.isLinux
        ? const YaruBackButton(
            style: YaruBackButtonStyle.rounded,
          )
        : const BackButton();
  }
}

class SideBarProgress extends StatelessWidget {
  const SideBarProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return _yaruStyled
        ? const SizedBox(
            height: 18,
            width: 18,
            child: Progress(),
          )
        : SizedBox(
            height: iconSize(),
            width: iconSize(),
            child: const Progress(),
          );
  }
}

class Progress extends StatelessWidget {
  const Progress({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.valueColor,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeCap,
    this.strokeWidth = 3.0,
    this.padding,
  });

  final double? value;
  final Color? backgroundColor;
  final Color? color;
  final Animation<Color?>? valueColor;
  final double strokeWidth;
  final String? semanticsLabel;
  final String? semanticsValue;
  final StrokeCap? strokeCap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).primaryColor.withOpacity(0.5);
    return _yaruStyled
        ? YaruCircularProgressIndicator(
            strokeWidth: strokeWidth,
            value: value,
            valueColor: valueColor,
            semanticsLabel: semanticsLabel,
            semanticsValue: semanticsValue,
            trackColor: c,
          )
        : Padding(
            padding: padding ?? const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              value: value,
              valueColor: valueColor,
              semanticsLabel: semanticsLabel,
              semanticsValue: semanticsValue,
              backgroundColor: c,
            ),
          );
  }
}

class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.style = YaruTitleBarStyle.normal,
    this.titleSpacing,
    this.backgroundColor = Colors.transparent,
    this.foregroundColor,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final YaruTitleBarStyle style;
  final double? titleSpacing;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return _yaruStyled
        ? YaruWindowTitleBar(
            titleSpacing: titleSpacing,
            actions: actions,
            leading: leading,
            title: title,
            border: BorderSide.none,
            backgroundColor: backgroundColor,
            style: style,
          )
        : AppBar(
            leading: leading,
            title: title,
          );
  }

  @override
  Size get preferredSize => Size(
        0,
        _mobile
            ? (style == YaruTitleBarStyle.hidden ? 0 : kYaruTitleBarHeight)
            : kToolbarHeight,
      );
}

double? get avatarIconSize => _yaruStyled ? kYaruTitleBarItemHeight / 2 : null;

double? get snackBarWidth => _yaruStyled ? kSnackBarWidth : null;

double get searchBarWidth => _mobile ? kSearchBarWidth : 600;

bool get showSideBarFilter => _yaruStyled ? true : false;

FontWeight get smallTextFontWeight =>
    _yaruStyled ? FontWeight.w100 : FontWeight.w400;

FontWeight get mediumTextWeight =>
    _yaruStyled ? FontWeight.w200 : FontWeight.w500;

bool get _yaruStyled => Platform.isLinux;

bool get _mobile => Platform.isAndroid || Platform.isIOS || Platform.isFuchsia;

bool get shrinkTitleBarItems => _yaruStyled;

double get chipHeight => _yaruStyled ? kYaruTitleBarItemHeight : 40;

EdgeInsetsGeometry get gridPadding =>
    _yaruStyled ? kPodcastGridPadding : kMobilePodcastGridPadding;

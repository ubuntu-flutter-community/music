import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaru/yaru.dart';

import '../../app.dart';
import '../../build_context_x.dart';
import '../../constants.dart';
import '../../globals.dart';
import '../../theme.dart';
import 'icons.dart';

class NavBackButton extends StatelessWidget {
  const NavBackButton({super.key, this.onPressed});

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    void onTap() {
      if (onPressed == null) {
        navigatorKey.currentState?.maybePop(context);
      } else {
        onPressed?.call();
        navigatorKey.currentState?.maybePop(context);
      }
    }

    if (yaruStyled) {
      return const YaruBackButton(
        style: YaruBackButtonStyle.rounded,
      );
    } else {
      if (Platform.isMacOS) {
        return Padding(
          padding: const EdgeInsets.only(top: 16, left: 13),
          child: Center(
            child: SizedBox(
              height: 15,
              width: 15,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Icon(
                  Iconz().goBack,
                  size: 10,
                ),
              ),
            ),
          ),
        );
      } else {
        return Center(
          child: BackButton(
            onPressed: onTap,
          ),
        );
      }
    }
  }
}

class SideBarProgress extends StatelessWidget {
  const SideBarProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: yaruStyled ? 18 : iconSize,
      child: const Progress(
        strokeWidth: 2,
      ),
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
    return yaruStyled
        ? YaruCircularProgressIndicator(
            strokeWidth: strokeWidth,
            value: value,
            color: color,
            trackColor: backgroundColor,
          )
        : Padding(
            padding: padding ?? const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              value: value,
              color: color,
              backgroundColor: value == null
                  ? null
                  : (backgroundColor ??
                      context.t.colorScheme.primary.withOpacity(0.3)),
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
    return !isMobile
        ? YaruWindowTitleBar(
            titleSpacing: titleSpacing,
            actions: actions,
            leading: leading,
            title: title,
            border: BorderSide.none,
            backgroundColor: backgroundColor,
            style: style,
            foregroundColor: foregroundColor,
          )
        : AppBar(
            titleSpacing: titleSpacing,
            centerTitle: true,
            leading: leading,
            title: title,
            actions: actions,
            foregroundColor: foregroundColor,
          );
  }

  @override
  Size get preferredSize => Size(
        0,
        isMobile
            ? (style == YaruTitleBarStyle.hidden ? 0 : kYaruTitleBarHeight)
            : kToolbarHeight,
      );
}

class TabsBar extends StatelessWidget {
  const TabsBar({super.key, required this.tabs, this.onTap});

  final List<Widget> tabs;
  final void Function(int)? onTap;

  @override
  Widget build(BuildContext context) {
    return yaruStyled || appleStyled
        ? YaruTabBar(
            onTap: onTap,
            tabs: tabs,
          )
        : TabBar(
            onTap: onTap,
            tabs: tabs,
          );
  }
}

class SearchButton extends StatelessWidget {
  const SearchButton({super.key, this.onPressed, this.active});

  final void Function()? onPressed;
  final bool? active;

  @override
  Widget build(BuildContext context) {
    return yaruStyled
        ? YaruSearchButton(
            searchActive: active,
            onPressed: onPressed,
          )
        : IconButton(
            isSelected: active,
            onPressed: onPressed,
            selectedIcon: Icon(
              Iconz().search,
              color: context.t.colorScheme.primary,
            ),
            icon: Icon(Iconz().search),
          );
  }
}

class SearchingBar extends ConsumerWidget {
  const SearchingBar({
    super.key,
    this.text,
    this.onClear,
    this.onSubmitted,
    this.onChanged,
    this.hintText,
  });

  final String? text;
  final void Function()? onClear;
  final void Function(String?)? onSubmitted;
  final void Function(String)? onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appModel = ref.read(appModelProvider);
    void onChanged2(v) {
      appModel.setLockSpace(true);
      onChanged?.call(v);
    }

    void onSubmitted2(v) {
      appModel.setLockSpace(false);
      onSubmitted?.call(v);
    }

    return yaruStyled
        ? YaruSearchField(
            hintText: hintText,
            clearIcon: yaruStyled ? null : Icon(Iconz().clear),
            key: key,
            text: text,
            onClear: onClear,
            onSubmitted: onSubmitted2,
            onChanged: onChanged2,
          )
        : MaterialSearchBar(
            hintText: hintText,
            text: text,
            key: key,
            onSubmitted: onSubmitted2,
            onClear: onClear,
            onChanged: onChanged2,
          );
  }
}

class MaterialSearchBar extends StatefulWidget {
  const MaterialSearchBar({
    super.key,
    this.text,
    this.onClear,
    this.onSubmitted,
    this.onChanged,
    this.hintText,
  });
  final String? text;
  final void Function()? onClear;
  final void Function(String?)? onSubmitted;
  final void Function(String)? onChanged;
  final String? hintText;

  @override
  State<MaterialSearchBar> createState() => _NormalSearchBarState();
}

class _NormalSearchBarState extends State<MaterialSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        onTap: () {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.value.text.length,
          );
        },
        controller: _controller,
        key: widget.key,
        autofocus: true,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
          contentPadding:
              const EdgeInsets.only(top: 10, bottom: 8, left: 15, right: 15),
          filled: true,
          suffixIcon: IconButton(
            onPressed: () {
              widget.onClear?.call();
              _controller.clear();
            },
            icon: const Icon(Icons.clear),
          ),
        ),
      ),
    );
  }
}

class DropDownArrow extends StatelessWidget {
  const DropDownArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return yaruStyled
        ? const Icon(YaruIcons.pan_down)
        : const Icon(Icons.arrow_drop_down);
  }
}

double get podcastProgressSize => yaruStyled ? 34 : 45;

double get likeButtonWidth => yaruStyled ? 62 : 70;

double? get avatarIconSize => yaruStyled ? kYaruTitleBarItemHeight / 2 : null;

double get searchBarWidth => isMobile ? kSearchBarWidth : 600;

bool get showSideBarFilter => yaruStyled ? true : false;

FontWeight get smallTextFontWeight =>
    yaruStyled ? FontWeight.w100 : FontWeight.w400;

FontWeight get mediumTextWeight =>
    yaruStyled ? FontWeight.w400 : FontWeight.w400;

FontWeight get largeTextWeight =>
    yaruStyled ? FontWeight.w200 : FontWeight.w300;

bool get shrinkTitleBarItems => yaruStyled;

double get chipHeight => yaruStyled ? kYaruTitleBarItemHeight : 35;

EdgeInsetsGeometry get tabViewPadding =>
    isMobile ? const EdgeInsets.only(top: 15) : const EdgeInsets.only(top: 5);

EdgeInsetsGeometry get gridPadding =>
    isMobile ? kMobileGridPadding : kGridPadding;

SliverGridDelegate get audioCardGridDelegate =>
    isMobile ? kMobileAudioCardGridDelegate : kAudioCardGridDelegate;

EdgeInsetsGeometry get appBarActionSpacing => Platform.isMacOS
    ? const EdgeInsets.only(right: 5, left: 20)
    : const EdgeInsets.only(right: 10, left: 20);

class CommonSwitch extends StatelessWidget {
  const CommonSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return yaruStyled
        ? YaruSwitch(
            value: value,
            onChanged: onChanged,
          )
        : Switch(value: value, onChanged: onChanged);
  }
}

class CommonCheckBox extends StatelessWidget {
  const CommonCheckBox({super.key, required this.value, this.onChanged});

  final bool value;
  final void Function(bool?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return yaruStyled
        ? YaruCheckbox(
            value: value,
            onChanged: onChanged,
          )
        : Checkbox(value: value, onChanged: onChanged);
  }
}

class ImportantButton extends StatelessWidget {
  const ImportantButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final void Function()? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return yaruStyled
        ? ElevatedButton(
            onPressed: onPressed,
            child: child,
          )
        : FilledButton(onPressed: onPressed, child: child);
  }
}

TextStyle getControlPanelStyle(TextTheme textTheme) =>
    textTheme.headlineSmall?.copyWith(fontWeight: largeTextWeight) ??
    const TextStyle(fontSize: 25);

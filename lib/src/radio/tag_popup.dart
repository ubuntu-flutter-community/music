import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:radio_browser_api/radio_browser_api.dart' hide State;
import 'package:yaru/yaru.dart';
import 'package:yaru_widgets/constants.dart';

import '../../build_context_x.dart';
import '../../common.dart';
import '../../constants.dart';
import '../../theme.dart';
import '../../theme_data_x.dart';
import '../l10n/l10n.dart';

class TagPopup extends StatelessWidget {
  const TagPopup({
    super.key,
    this.onSelected,
    this.tags,
    required this.value,
    this.textStyle,
    required this.addFav,
    required this.removeFav,
    this.favs,
  });

  final void Function(Tag? tag)? onSelected;
  final List<Tag>? tags;
  final Set<String>? favs;
  final Tag? value;
  final TextStyle? textStyle;
  final void Function(Tag? tag) addFav;
  final void Function(Tag? tag) removeFav;

  @override
  Widget build(BuildContext context) {
    final theme = context.t;
    final fallBackTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
    );

    return SizedBox(
      height: yaruStyled ? kYaruTitleBarItemHeight : 38,
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Autocomplete<Tag>(
            key: ValueKey(value?.name),
            initialValue: TextEditingValue(
              text: value?.name ?? context.l10n.all,
            ),
            displayStringForOption: (option) => option.name,
            fieldViewBuilder: (
              context,
              textEditingController,
              focusNode,
              onFieldSubmitted,
            ) {
              return TextField(
                maxLines: 1,
                onTap: () {
                  textEditingController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: textEditingController.value.text.length,
                  );
                },
                style: yaruStyled ? theme.textTheme.bodyMedium : null,
                strutStyle: yaruStyled
                    ? const StrutStyle(
                        leading: 0.2,
                      )
                    : null,
                textAlignVertical: yaruStyled ? TextAlignVertical.center : null,
                cursorWidth: yaruStyled ? 1 : 2.0,
                decoration: yaruStyled
                    ? _createYaruDecoration(theme.isLight)
                    : _createDecoration(theme.colorScheme),
                controller: textEditingController,
                focusNode: focusNode,
                onSubmitted: (String value) {
                  onFieldSubmitted();
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: kSearchBarWidth,
                  height:
                      (options.length * 50) > 400 ? 400 : options.length * 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Material(
                      color: theme.isLight
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      elevation: 1,
                      child: ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          return Builder(
                            builder: (BuildContext context) {
                              final bool highlight =
                                  AutocompleteHighlightedOption.of(
                                        context,
                                      ) ==
                                      index;
                              if (highlight) {
                                SchedulerBinding.instance
                                    .addPostFrameCallback((Duration timeStamp) {
                                  Scrollable.ensureVisible(
                                    context,
                                    alignment: 0.5,
                                  );
                                });
                              }
                              final t = options.elementAt(index);
                              return _TagTile(
                                onSelected: (v) => onSelected(v),
                                fallBackTextStyle: fallBackTextStyle,
                                highlight: highlight,
                                theme: theme,
                                t: t,
                                favs: favs,
                                addFav: addFav,
                                removeFav: removeFav,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return tags ?? [];
              }
              return tags?.where(
                    (e) => e.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()),
                  ) ??
                  [];
            },
            onSelected: (option) => onSelected?.call(option),
          );
        },
      ),
    );
  }

  InputDecoration _createDecoration(ColorScheme colorScheme) {
    final outlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(width: 2, color: colorScheme.primary),
    );
    return InputDecoration(
      filled: true,
      contentPadding: const EdgeInsets.all(10),
      border: outlineInputBorder,
      errorBorder: outlineInputBorder,
      enabledBorder: outlineInputBorder,
      focusedBorder: outlineInputBorder,
      disabledBorder: outlineInputBorder,
      focusedErrorBorder: outlineInputBorder,
    );
  }

  InputDecoration _createYaruDecoration(bool isLight) {
    final radius = BorderRadius.circular(kYaruButtonRadius);

    final fill = isLight ? const Color(0xffdcdcdc) : const Color(0xff2f2f2f);

    const textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
    );

    return InputDecoration(
      filled: true,
      fillColor: fill,
      hoverColor: (fill).scale(lightness: 0.1),
      suffixIconConstraints:
          const BoxConstraints(maxWidth: kYaruTitleBarItemHeight),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: radius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: radius,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: radius,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.only(
        bottom: 10,
        top: 10,
        right: 15,
        left: 15,
      ),
      helperStyle: textStyle,
      hintStyle: textStyle,
      labelStyle: textStyle,
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({
    required this.fallBackTextStyle,
    required this.highlight,
    required this.theme,
    required this.t,
    required this.favs,
    required this.addFav,
    required this.removeFav,
    required this.onSelected,
  });

  final TextStyle? fallBackTextStyle;
  final bool highlight;
  final ThemeData theme;
  final Tag t;
  final Set<String>? favs;
  final void Function(Tag? tag) addFav;
  final void Function(Tag? tag) removeFav;
  final void Function(Tag tag) onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(
        left: 10,
        right: 5,
      ),
      titleTextStyle: fallBackTextStyle?.copyWith(
        fontWeight: FontWeight.normal,
      ),
      hoverColor: highlight ? theme.focusColor : null,
      tileColor: highlight ? theme.focusColor : null,
      onTap: () => onSelected(t),
      title: Text(t.name),
      trailing: IconButton(
        onPressed: () {
          favs?.contains(t.name) == false ? addFav(t) : removeFav(t);
        },
        icon: Icon(
          favs?.contains(t.name) == true ? Iconz().starFilled : Iconz().star,
        ),
      ),
    );
  }
}

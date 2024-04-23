import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:yaru/constants.dart';

import '../../build_context_x.dart';
import '../../common.dart';
import '../../constants.dart';
import '../../string_x.dart';
import '../../theme.dart';
import '../../theme_data_x.dart';
import '../l10n/l10n.dart';
import 'languages.dart';

class LanguageAutoComplete extends StatelessWidget {
  const LanguageAutoComplete({
    super.key,
    this.onSelected,
    required this.value,
    this.textStyle,
    required this.addFav,
    required this.removeFav,
    this.favs,
    this.width,
    this.height,
    this.style,
    this.isDense = false,
    this.filled = true,
    this.border,
    this.fillColor,
    this.contentPadding,
  });

  final void Function(SimpleLanguage? language)? onSelected;
  final Set<String>? favs;
  final SimpleLanguage? value;
  final TextStyle? textStyle;
  final void Function(SimpleLanguage? language) addFav;
  final void Function(SimpleLanguage? language) removeFav;
  final double? width;
  final double? height;
  final TextStyle? style;
  final bool isDense, filled;
  final OutlineInputBorder? border;
  final Color? fillColor;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = context.t;

    return SizedBox(
      height: height ?? (yaruStyled ? kYaruTitleBarItemHeight : 38),
      width: width,
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Autocomplete<SimpleLanguage>(
            key: ValueKey(value?.name),
            initialValue: TextEditingValue(
              text: value?.name ?? '',
            ),
            displayStringForOption: (option) => option.name,
            fieldViewBuilder: (
              context,
              textEditingController,
              focusNode,
              onFieldSubmitted,
            ) {
              final hintText =
                  '${context.l10n.search}: ${context.l10n.language}';
              return TextField(
                maxLines: 1,
                onTap: () {
                  textEditingController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: textEditingController.value.text.length,
                  );
                },
                style:
                    style ?? (yaruStyled ? theme.textTheme.bodyMedium : null),
                strutStyle: yaruStyled
                    ? const StrutStyle(
                        leading: 0.2,
                      )
                    : null,
                textAlignVertical: yaruStyled ? TextAlignVertical.center : null,
                cursorWidth: yaruStyled ? 1 : 2.0,
                decoration: yaruStyled
                    ? createYaruDecoration(
                        theme: theme,
                        style: style,
                        fillColor: fillColor,
                        contentPadding: contentPadding,
                        hintText: hintText,
                        border: border,
                      )
                    : createMaterialDecoration(
                        colorScheme: theme.colorScheme,
                        style: style,
                        isDense: isDense,
                        border: border,
                        filled: filled,
                        fillColor: fillColor,
                        contentPadding: contentPadding,
                        hintText: hintText,
                      ),
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
                  width: width ?? kSearchBarWidth,
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
                              return _LanguageTile(
                                onSelected: (v) => onSelected(v),
                                fallBackTextStyle: style,
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
              final langs = [
                ...Languages.defaultLanguages.where(
                  (e) => favs?.contains(e.isoCode) == true,
                ),
                ...Languages.defaultLanguages.where(
                  (e) => favs?.contains(e.isoCode) == false,
                ),
              ];
              if (textEditingValue.text.isEmpty) {
                return langs;
              }
              return langs.where(
                (e) => e.name
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()),
              );
            },
            onSelected: (option) => onSelected?.call(option),
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
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
  final SimpleLanguage t;
  final Set<String>? favs;
  final void Function(SimpleLanguage? language) addFav;
  final void Function(SimpleLanguage? language) removeFav;
  final void Function(SimpleLanguage language) onSelected;

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
      title: Text(t.name.capitalized),
      trailing: IconButton(
        onPressed: () {
          favs?.contains(t.isoCode) == false ? addFav(t) : removeFav(t);
        },
        icon: Icon(
          favs?.contains(t.isoCode) == true ? Iconz().starFilled : Iconz().star,
        ),
      ),
    );
  }
}

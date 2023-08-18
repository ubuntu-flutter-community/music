import 'package:flutter/material.dart';
import 'package:musicpod/string_x.dart';
import 'package:podcast_search/podcast_search.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class CountryPopup extends StatelessWidget {
  const CountryPopup({
    super.key,
    this.onSelected,
    this.countries,
    required this.value,
    this.textStyle,
  });

  final void Function(Country country)? onSelected;
  final List<Country>? countries;
  final Country? value;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = TextButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    );
    final fallBackTextStyle =
        theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);
    return YaruPopupMenuButton<Country>(
      style: buttonStyle,
      onSelected: onSelected,
      initialValue: value,
      child: Text(
        value?.name.capitalize().camelToSentence() ?? '',
        style: textStyle ?? fallBackTextStyle,
      ),
      itemBuilder: (context) {
        return [
          for (final c
              in countries ?? Country.values.where((c) => c != Country.none))
            PopupMenuItem(
              value: c,
              child: Text(c.name.capitalize().camelToSentence()),
            ),
        ];
      },
    );
  }
}

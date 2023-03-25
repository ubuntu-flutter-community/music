import 'package:flutter/material.dart';
import 'package:musicpod/app/local_audio/local_audio_model.dart';
import 'package:musicpod/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class LocalAudioSearchField extends StatefulWidget {
  const LocalAudioSearchField({
    super.key,
    this.text,
  });

  final String? text;

  @override
  State<LocalAudioSearchField> createState() => _LocalAudioSearchFieldState();
}

class _LocalAudioSearchFieldState extends State<LocalAudioSearchField> {
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
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final model = context.watch<LocalAudioModel>();

    return SizedBox(
      height: 35,
      width: 400,
      child: TextField(
        autofocus: true,
        style: theme.textTheme.bodyMedium,
        strutStyle: const StrutStyle(
          leading: 0.2,
        ),
        textAlignVertical: TextAlignVertical.center,
        cursorWidth: 1,
        onSubmitted: (value) {
          model.setSearchQuery(value);
          model.search();
        },
        controller: _controller,
        decoration: InputDecoration(
          hintText: context.l10n.search,
          contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          prefixIcon: const Icon(
            YaruIcons.search,
            size: 16,
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 34, minHeight: 30),
          suffixIconConstraints:
              const BoxConstraints(maxHeight: 35, maxWidth: 35),
          suffixIcon: _controller.text.isEmpty
              ? null
              : YaruIconButton(
                  onPressed: () {
                    _controller.clear();
                    model.setSearchQuery('');
                  },
                  icon: const Icon(
                    YaruIcons.edit_clear,
                  ),
                ),
          fillColor: light ? Colors.white : Theme.of(context).dividerColor,
        ),
      ),
    );
  }
}

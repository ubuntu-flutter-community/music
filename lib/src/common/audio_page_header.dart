import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

import '../../build_context_x.dart';
import '../../theme.dart';
import '../l10n/l10n.dart';

class AudioPageHeader extends StatelessWidget {
  const AudioPageHeader({
    super.key,
    required this.title,
    this.description,
    this.image,
    this.label,
    this.subTitle,
    this.height,
  });

  final String title;
  final String? description;
  final Widget? image;
  final String? label;
  final String? subTitle;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = context.t;
    final size = context.m.size;
    final smallWindow = size.width < 600.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            smallWindow ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (image != null)
            Padding(
              padding: EdgeInsets.only(right: smallWindow ? 0 : 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: image!,
              ),
            ),
          if (!smallWindow)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (height != 0)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label ?? context.l10n.album,
                              style: theme.textTheme.labelSmall,
                              maxLines: 1,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text('·'),
                          ),
                          Flexible(
                            child: Text(
                              subTitle ?? '',
                              style: theme.textTheme.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Flexible(
                    fit: FlexFit.tight,
                    child: Text(
                      title,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        fontSize: 30,
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (description != null)
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(kYaruButtonRadius),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => _DescriptionDialog(
                            title: title,
                            description: description!,
                          ),
                        ),
                        child: SizedBox(
                          height: 100,
                          child: Html(
                            data: description,
                            onAnchorTap: (url, attributes, element) {
                              if (url == null) return;
                              launchUrl(Uri.parse(url));
                            },
                            style: {
                              'img': Style(display: Display.none),
                              'html': Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                textAlign: TextAlign.start,
                                maxLines: 20,
                                textOverflow: TextOverflow.fade,
                              ),
                              'body': Style(
                                margin: Margins.zero,
                                textOverflow: TextOverflow.fade,
                                maxLines: 20,
                                textAlign: TextAlign.start,
                              ),
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DescriptionDialog extends StatelessWidget {
  const _DescriptionDialog({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: yaruStyled
          ? YaruDialogTitleBar(
              title: Text(title),
              backgroundColor: Colors.transparent,
              border: BorderSide.none,
            )
          : Text(title),
      titlePadding: yaruStyled ? EdgeInsets.zero : null,
      contentPadding: const EdgeInsets.only(
        top: 10,
        left: kYaruPagePadding,
        right: kYaruPagePadding,
        bottom: kYaruPagePadding,
      ),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Html(
          onAnchorTap: (url, attributes, element) {
            if (url == null) return;
            launchUrl(Uri.parse(url));
          },
          data: description,
          style: {
            'html': Style(
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
            'body': Style(
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
          },
        ),
      ),
      scrollable: true,
    );
  }
}

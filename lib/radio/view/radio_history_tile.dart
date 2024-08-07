import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';
import 'package:yaru/constants.dart';

import '../../common/data/audio.dart';
import '../../common/data/mpv_meta_data.dart';
import '../../common/view/icons.dart';
import '../../common/view/icy_image.dart';
import '../../common/view/mpv_metadata_dialog.dart';
import '../../common/view/tapable_text.dart';
import '../../common/view/theme.dart';
import '../../extensions/build_context_x.dart';
import '../../extensions/theme_data_x.dart';
import '../../l10n/l10n.dart';
import '../../library/library_model.dart';
import '../../online_album_art_utils.dart';
import '../../player/player_mixin.dart';
import '../../search/search_model.dart';
import 'station_page.dart';

class RadioHistoryTile extends StatelessWidget with PlayerMixin {
  const RadioHistoryTile({
    super.key,
    required this.entry,
    required this.selected,
  });

  final MapEntry<String, MpvMetaData> entry;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(entry.value.icyTitle),
      selected: selected,
      selectedColor: context.t.contrastyPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: kYaruPagePadding),
      leading: IcyImage(
        height: yaruStyled ? 34 : 40,
        width: yaruStyled ? 34 : 40,
        mpvMetaData: entry.value,
      ),
      trailing: IconButton(
        tooltip: context.l10n.metadata,
        onPressed: () => showDialog(
          context: context,
          builder: (context) {
            final image = UrlStore().get(entry.value.icyTitle);
            return MpvMetadataDialog(
              mpvMetaData: entry.value,
              image: image,
            );
          },
        ),
        icon: Icon(
          Iconz().info,
        ),
      ),
      title: TapAbleText(
        overflow: TextOverflow.visible,
        maxLines: 10,
        text: entry.value.icyTitle,
        onTap: () => onTitleTap(
          text: entry.value.icyTitle,
          context: context,
        ),
      ),
      subtitle: TapAbleText(
        text: entry.value.icyName,
        onTap: () {
          final libraryModel = di<LibraryModel>();
          if (libraryModel.selectedPageId == entry.value.icyUrl) return;

          di<SearchModel>().radioNameSearch(entry.value.icyName).then((v) {
            if (v?.firstOrNull?.urlResolved != null) {
              libraryModel.push(
                builder: (_) =>
                    StationPage(station: Audio.fromStation(v.first)),
                pageId: v!.first.urlResolved!,
              );
            }
          });
        },
      ),
    );
  }
}

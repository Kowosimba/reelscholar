import 'package:video_player/video_player.dart';
import 'video_preview_controller_factory_stub.dart'
    if (dart.library.io) 'video_preview_controller_factory_io.dart'
    if (dart.library.html) 'video_preview_controller_factory_web.dart'
    as p_factory;

VideoPlayerController createVideoPreviewController(String path) {
  return p_factory.createVideoPreviewController(path);
}

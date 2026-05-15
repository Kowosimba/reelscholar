import 'package:video_player/video_player.dart';

VideoPlayerController createVideoPreviewController(String path) {
  return VideoPlayerController.networkUrl(Uri.parse(path));
}

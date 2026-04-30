import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeFrame extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  
  const YoutubeFrame({
    super.key, 
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<YoutubeFrame> createState() => _YoutubeFrameState();
}

class _YoutubeFrameState extends State<YoutubeFrame> {
  late YoutubePlayerController _controller;

  @override
  void didUpdateWidget(covariant YoutubeFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
      if (videoId != null) {
        _controller.load(videoId);
        _controller.pause();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(() {
      if (mounted) {
        if (_controller.value.playerState == PlayerState.ended) {
          _controller.pause();
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primaryTeal,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.primaryTeal,
          handleColor: AppColors.primaryTeal,
        ),
        onEnded: (metaData) {
          _controller.seekTo(Duration.zero);
          _controller.pause();
          if (mounted) setState(() {});
        },
      ),
      builder: (context, player) {
        return AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: player,
        );
      },
    );
  }
}

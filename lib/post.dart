import 'package:flutter/material.dart';
import 'package:imgur/homepage.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:visibility_detector/visibility_detector.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key, required this.url}) : super(key: key);

  final String url;

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.setLooping(true);
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VisibilityDetector(
                key: ObjectKey(_controller),
                onVisibilityChanged: (visibility) => {
                  if (visibility.visibleFraction * 100 < 70) {
                    _controller.pause()
                  } else {
                    _controller.play()
                  }
                },
                child: VideoPlayer(_controller)
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }
    );
  }
}

class PostThumb extends StatelessWidget {
  const PostThumb({
    Key? key,
    required this.post,
  }) : super(key: key);

  final Post post;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostFull(post: post)
          )
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      post.title ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16)
                    )
                  )
                )
              ]
            ),
            Stack(
              children: [
                SizedBox(
                  height: (post.cover?.height ?? 0) * (MediaQuery.of(context).size.width/(post.cover?.width ?? 0)),
                  child: post.cover?.type == 'video' ? VideoScreen(url: post.cover?.url ?? '') : Image.network(post.cover?.url ?? '')
                ),
                post.imageCount! > 1 ? Positioned(
                  top: (post.cover?.height ?? 0) * (MediaQuery.of(context).size.width/(post.cover?.width ?? 0)) - 50,
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color.fromRGBO(0, 0, 0, 1),
                        ],
                      )
                    ),
                    child: Center(child: Text('${post.imageCount} more', style: const TextStyle(color: Colors.white)))
                  )
                ) : post.cover?.type == 'video' ? VideoScreen(url: post.cover?.url ?? '') : Image.network(post.cover?.url ?? '')
              ]
            )
          ]
        )
      )
    );
  }
}

Future<Post> getPost(String postId) async {
  final response = await http.get(Uri.parse('https://imgur.com/gallery/$postId'), headers: {"content-type": "charset=utf-8"});
  if (response.statusCode == 200) {
    RegExpMatch? match = RegExp(r'window\.postDataJSON="(.*)"<').firstMatch(utf8.decode(response.bodyBytes));

    return Post.fromJson(jsonDecode(match![1]?.replaceAll(RegExp(r'\\"'), "\"").replaceAll(RegExp(r'\\\\"'), "\\\"").replaceAll(RegExp(r"\\'"), "'") ?? '{}'));
  } else {
    throw Exception('Failed to load post');
  }
}

class PostFull extends StatelessWidget {
  const PostFull({Key? key, required this.post}) : super(key: key);

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(46, 48, 53, 1),
      appBar: AppBar(
        title: Text(post.title ?? '')
      ),
      body: FutureBuilder<Post>(
        future: getPost(post.id ?? ''),
        builder: (context, post) {
          if (post.hasData) {
            return ListView.builder(
              itemCount: post.data?.media?.length,
              itemBuilder: (context, index) {
                return Column(children: [
                  GestureDetector(
                    onLongPress: () => Clipboard.setData(ClipboardData(text: post.data?.media?[index].url ?? '')),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: SizedBox(
                        height: (post.data?.media?[index].height ?? 0) * (MediaQuery.of(context).size.width/(post.data?.media?[index].width ?? 0)),
                        child: post.data?.media?[index].type == 'video' ? VideoScreen(url: post.data?.media?[index].url ?? '') : Image.network(post.data?.media?[index].url ?? '')
                      )
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(post.data?.media?[index].metadata?.description?.replaceAll('\\n', '\n') ?? '', style: const TextStyle(color: Colors.white))
                  )
                ]);
              }
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        }
      )
    );
  }
}
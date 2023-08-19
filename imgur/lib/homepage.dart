import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'post.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Post {
  String? id;
  String? title;
  String? description;
  int? viewCount;
  int? upvoteCount;
  int? downvoteCount;
  int? pointCount;
  int? imageCount;
  String? url;
  bool? favorite;
  bool? isAd;
  bool? includeAlbumAds;
  bool? sharedWithCommunity;
  bool? isPending;
  String? platform;
  Cover? cover;
  List<Media>? media;

  Post({
    this.id,
    this.title,
    this.description,
    this.viewCount,
    this.upvoteCount,
    this.downvoteCount,
    this.pointCount,
    this.imageCount,
    this.url,
    this.favorite,
    this.isAd,
    this.includeAlbumAds,
    this.sharedWithCommunity,
    this.isPending,
    this.platform,
    this.cover,
    this.media
  });

  Post.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    viewCount = json['view_count'];
    upvoteCount = json['upvote_count'];
    downvoteCount = json['downvote_count'];
    pointCount = json['point_count'];
    imageCount = json['image_count'];
    url = json['url'];
    favorite = json['favorite'];
    isAd = json['is_ad'];
    includeAlbumAds = json['include_album_ads'];
    sharedWithCommunity = json['shared_with_community'];
    isPending = json['is_pending'];
    platform = json['platform'];
    cover = json['cover'] != null ? Cover.fromJson(json['cover']) : null;
    if (json['media'] != null) {
      media = <Media>[];
      json['media'].forEach((v) {
        media?.add(Media.fromJson(v));
      });
    }
  }
}

class Cover {
  String? id;
  int? accountId;
  String? mimeType;
  String? type;
  String? name;
  String? basename;
  String? url;
  String? ext;
  int? width;
  int? height;
  int? size;
  String? createdAt;
  String? updatedAt;

  Cover({
    this.id,
    this.accountId,
    this.mimeType,
    this.type,
    this.name,
    this.basename,
    this.url,
    this.ext,
    this.width,
    this.height,
    this.size,
    this.createdAt,
    this.updatedAt
  });

  Cover.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accountId = json['account_id'];
    mimeType = json['mime_type'];
    type = json['type'];
    name = json['name'];
    basename = json['basename'];
    url = json['url'];
    ext = json['ext'];
    width = json['width'];
    height = json['height'];
    size = json['size'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
}

class Meta {
  String? description;

  Meta({
    this.description
  });

  Meta.fromJson(Map<String, dynamic> json) {
    description = json['description'];
  }
}

class Media {
  String? id;
  String? type;
  String? name;
  String? url;
  int? width;
  int? height;
  Meta? metadata;

  Media({
    this.id,
    this.type,
    this.name,
    this.url,
    this.width,
    this.height,
    this.metadata
  });

  Media.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    name = json['name'];
    url = json['url'];
    width = json['width'];
    height = json['height'];
    metadata = json['metadata'] != null ? Meta.fromJson(json['metadata']) : null;
  }
}

Future<List<Post>> getPosts(page, type) async {
  final response = await http.get(Uri.parse('https://api.imgur.com/post/v1/posts?client_id=546c25a59c58ad7&filter[section]=eq:$type&include=cover&location=desktophome&page=$page&sort=-time'),
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json; charset=UTF-8'
    }
  );

  if (response.statusCode == 200) {
    final parsed = jsonDecode(utf8.decode(response.bodyBytes));
    final List<Post> posts = [];
    for (int i = 0; i < parsed.length; i++) {
      posts.add(Post.fromJson(parsed[i]));
    }
    return posts;
  } else {
    throw Exception('Failed to load images');
  }
}

class Gallery extends StatefulWidget {
  const Gallery({Key? key, required this.type}) : super(key: key);
  final String type;

  @override
  createState() => _GalleryViewState();
}

class _GalleryViewState extends State<Gallery> {
  static const _pageSize = 39;
  final PagingController<int, Post> _pagingController =
    PagingController(firstPageKey: 1);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await getPosts(pageKey, widget.type);
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey++;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) => PagedListView<int, Post>(
    pagingController: _pagingController,
    builderDelegate: PagedChildBuilderDelegate<Post>(
      itemBuilder: (context, item, index) => PostThumb(
        post: item,
      ),
    )
  );
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color.fromRGBO(46, 48, 53, 1),
          secondary: const Color.fromRGBO(46, 48, 53, 1),
        )
      ),
      home: const Scaffold(
        backgroundColor: Color.fromRGBO(46, 48, 53, 1),
        body: Gallery(type: 'hot')
      )
    );
  }
}


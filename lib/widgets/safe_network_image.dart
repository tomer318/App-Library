import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

class SafeNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  @override
  void didUpdateWidget(covariant SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _registerView();
    }
  }

  void _registerView() {
    if (!kIsWeb || widget.imageUrl.trim().isEmpty) return;

    _viewId = 'img-${widget.imageUrl.hashCode}';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final img = web.HTMLImageElement()
        ..src = widget.imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = widget.fit == BoxFit.cover ? 'cover' : 'contain'
        ..style.display = 'block'
        ..style.border = 'none';

      return img;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.trim().isEmpty) {
      return _buildFallback();
    }

    if (kIsWeb) {
      // Bọc IgnorePointer ở tầng Flutter để không kích hoạt lỗi MouseTracker
      Widget element = IgnorePointer(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: HtmlElementView(viewType: _viewId),
        ),
      );

      if (widget.borderRadius != null) {
        element = ClipRRect(
          borderRadius: widget.borderRadius!,
          child: element,
        );
      }
      return element;
    }

    Widget img = Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => _buildFallback(),
    );

    if (widget.borderRadius != null) {
      img = ClipRRect(borderRadius: widget.borderRadius!, child: img);
    }
    return img;
  }

  Widget _buildFallback() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: widget.borderRadius,
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 36, color: Colors.grey),
          SizedBox(height: 4),
          Text('Lỗi ảnh', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
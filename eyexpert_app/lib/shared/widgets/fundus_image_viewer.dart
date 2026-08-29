import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FundusImageViewer extends StatefulWidget {
  final String originalImagePath;
  final String? gradcamImagePath;
  final double overlayOpacity;
  final bool showOverlay;
  final String? eyeTag;
  final String? imageId;

  const FundusImageViewer({
    super.key,
    required this.originalImagePath,
    this.gradcamImagePath,
    this.overlayOpacity = 0.5,
    this.showOverlay = false,
    this.eyeTag,
    this.imageId,
  });

  @override
  State<FundusImageViewer> createState() => _FundusImageViewerState();
}

class _FundusImageViewerState extends State<FundusImageViewer> {
  final TransformationController _transformationController = TransformationController();

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.8,
            maxScale: 4.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildImage(widget.originalImagePath),
                if (widget.showOverlay && widget.gradcamImagePath != null && widget.gradcamImagePath!.isNotEmpty)
                  Opacity(
                    opacity: widget.overlayOpacity,
                    child: _buildImage(widget.gradcamImagePath!),
                  ),
              ],
            ),
          ),

          // Top Info Badges (Eye and Image ID)
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                if (widget.eyeTag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      widget.eyeTag!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (widget.imageId != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      widget.imageId!,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Reset Zoom Action Button
          Positioned(
            bottom: 12,
            right: 12,
            child: IconButton(
              onPressed: _resetZoom,
              tooltip: 'Reset Zoom',
              icon: const Icon(Icons.fit_screen_rounded, color: Colors.white70),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return _errorPlaceholder();
    }

    // 1. Base64 Encoded Image Data URI or Raw Base64
    if (path.startsWith('data:image') || (path.length > 50 && !path.contains('/') && !path.contains('\\') && !path.startsWith('http'))) {
      try {
        final commaIdx = path.indexOf(',');
        final base64Str = commaIdx != -1 ? path.substring(commaIdx + 1) : path;
        final cleanBase64 = base64Str.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _errorPlaceholder(),
        );
      } catch (_) {
        return _errorPlaceholder();
      }
    }

    // 2. Bundled Asset
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }

    // 3. Network or Web Blob URL
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }

    // 4. Local File System on Device/Desktop
    if (!kIsWeb) {
      try {
        final file = io.File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _errorPlaceholder(),
          );
        }
      } catch (_) {}
    } else {
      // On Flutter Web, local picked paths are blob URLs
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }

    // Fallback if file not found
    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() {
    return Container(
      width: double.infinity,
      height: 260,
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, color: Colors.white38, size: 40),
            SizedBox(height: 8),
            Text(
              'Retinal image preview',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

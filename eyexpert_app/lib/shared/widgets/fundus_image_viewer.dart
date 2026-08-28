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
                      color: Colors.black.withOpacity(0.7),
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
                      color: Colors.black.withOpacity(0.7),
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
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    } else if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    } else {
      return Image.asset(
        'assets/sample_fundus/sample_good_npdr_moderate.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }
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

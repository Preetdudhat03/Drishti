import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum FundusViewerMode {
  original,
  compare, // Before (Original) ↔ After (CLAHE Enhanced)
  xai, // Grad-CAM Heatmap
  overlay, // Fundus + Grad-CAM Fused
  clinician, // Tele-ophthalmology Workstation Dual View
}

class FundusImageViewer extends StatefulWidget {
  final String originalImagePath;
  final String? enhancedImagePath;
  final String? gradcamImagePath;
  final FundusViewerMode mode;
  final double overlayOpacity;
  final ValueChanged<double>? onOpacityChanged;
  final ValueChanged<FundusViewerMode>? onModeChanged;
  final String? eyeTag;
  final String? imageId;
  final bool showControls;
  final bool showReticle;
  final double? height;
  final String? qualityLabel;

  const FundusImageViewer({
    super.key,
    required this.originalImagePath,
    this.enhancedImagePath,
    this.gradcamImagePath,
    this.mode = FundusViewerMode.original,
    this.overlayOpacity = 0.65,
    this.onOpacityChanged,
    this.onModeChanged,
    this.eyeTag,
    this.imageId,
    this.showControls = true,
    this.showReticle = false,
    this.height,
    this.qualityLabel,
  });

  @override
  State<FundusImageViewer> createState() => _FundusImageViewerState();
}

class _FundusImageViewerState extends State<FundusImageViewer> {
  final TransformationController _transformationController = TransformationController();
  late FundusViewerMode _currentMode;
  late double _opacity;
  double _splitRatio = 0.50; // For comparison slider (0.0 to 1.0)
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
    _opacity = widget.overlayOpacity;
  }

  @override
  void didUpdateWidget(FundusImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _currentMode = widget.mode;
    }
    if (oldWidget.overlayOpacity != widget.overlayOpacity) {
      _opacity = widget.overlayOpacity;
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final hasGradcam = widget.gradcamImagePath != null && widget.gradcamImagePath!.isNotEmpty;
    final hasEnhanced = widget.enhancedImagePath != null && widget.enhancedImagePath!.isNotEmpty;

    final viewerBody = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.obsidian,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Interactive Medical Image Canvas
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.8,
            maxScale: 5.0,
            child: _buildCanvasContent(hasGradcam, hasEnhanced),
          ),

          // 2. HUD Optical Reticle Framing Guide (if enabled)
          if (widget.showReticle)
            IgnorePointer(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: _RetinalReticlePainter(),
              ),
            ),

          // 3. Top HUD Meta Strip (Eye Tag, Image ID, Quality State)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.eyeTag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.deepSpace.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.hudCyan.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          widget.eyeTag!,
                          style: const TextStyle(
                            color: AppColors.hudCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (widget.imageId != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.deepSpace.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Text(
                          widget.imageId!,
                          style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.qualityLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.deepSpace.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.statusGood.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.statusGood, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          widget.qualityLabel!,
                          style: const TextStyle(
                            color: AppColors.statusGood,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 4. Mode Selection Bar (Floating Workstation Toolbar)
          if (widget.showControls && (hasGradcam || hasEnhanced))
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.deepSpace.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeButton('Original', FundusViewerMode.original),
                    if (hasEnhanced) _modeButton('CLAHE Compare', FundusViewerMode.compare),
                    if (hasGradcam) _modeButton('Grad-CAM', FundusViewerMode.xai),
                    if (hasGradcam) _modeButton('Overlay', FundusViewerMode.overlay),
                  ],
                ),
              ),
            ),

          // 5. Workstation Actions (Reset Zoom, Opacity Slider, Fullscreen)
          Positioned(
            bottom: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentMode == FundusViewerMode.overlay && widget.showControls)
                  Container(
                    width: 110,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.deepSpace.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.opacity, color: AppColors.aiViolet, size: 14),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                              trackHeight: 2,
                              activeTrackColor: AppColors.aiViolet,
                              inactiveTrackColor: AppColors.borderDark,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: _opacity,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) {
                                setState(() => _opacity = val);
                                widget.onOpacityChanged?.call(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _iconButton(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'Reset Zoom (100%)',
                  onTap: _resetZoom,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return viewerBody;
  }

  Widget _buildCanvasContent(bool hasGradcam, bool hasEnhanced) {
    switch (_currentMode) {
      case FundusViewerMode.original:
        return _buildImage(widget.originalImagePath);

      case FundusViewerMode.xai:
        if (hasGradcam) {
          return _buildImage(widget.gradcamImagePath!);
        }
        return _buildImage(widget.originalImagePath);

      case FundusViewerMode.overlay:
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildImage(widget.originalImagePath),
            if (hasGradcam)
              Opacity(
                opacity: _opacity,
                child: _buildImage(widget.gradcamImagePath!),
              ),
          ],
        );

      case FundusViewerMode.compare:
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _splitRatio = (_splitRatio + details.delta.dx / w).clamp(0.05, 0.95);
                });
              },
              child: Stack(
                children: [
                  // Before (Original)
                  _buildImage(widget.originalImagePath),
                  // After (Enhanced) clipped to right side
                  ClipRect(
                    clipper: _HorizontalSplitClipper(splitRatio: _splitRatio),
                    child: _buildImage(
                      widget.enhancedImagePath ?? widget.originalImagePath,
                    ),
                  ),
                  // Splitter Line
                  Positioned(
                    left: w * _splitRatio - 1.5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: AppColors.hudCyan,
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.deepSpace,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.hudCyan, width: 2),
                            ),
                          ),
                          child: const Icon(
                            Icons.compare_arrows_rounded,
                            size: 14,
                            color: AppColors.hudCyan,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Labels
                  Positioned(
                    top: 40,
                    left: 12,
                    child: _tagBadge('RAW FUNDUS'),
                  ),
                  Positioned(
                    top: 40,
                    right: 12,
                    child: _tagBadge('CLAHE ENHANCED'),
                  ),
                ],
              ),
            );
          },
        );

      case FundusViewerMode.clinician:
        return Row(
          children: [
            Expanded(child: _buildImage(widget.originalImagePath)),
            Container(width: 1, color: AppColors.borderDark),
            Expanded(
              child: hasGradcam
                  ? _buildImage(widget.gradcamImagePath!)
                  : _buildImage(widget.originalImagePath),
            ),
          ],
        );
    }
  }

  Widget _modeButton(String label, FundusViewerMode mode) {
    final isSelected = _currentMode == mode;
    return InkWell(
      onTap: () {
        setState(() => _currentMode = mode);
        widget.onModeChanged?.call(mode);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkTextSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.deepSpace.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon, color: AppColors.darkTextPrimary),
      ),
    );
  }

  Widget _tagBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return const Center(
        child: Text('No Image Loaded', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
      );
    }

    if (path.startsWith('data:image') || (path.length > 500 && !path.contains('/') && !path.contains('\\'))) {
      try {
        final cleanBase64 = path.contains(',') ? path.split(',').last : path;
        final bytes = base64Decode(cleanBase64.replaceAll('\n', '').replaceAll('\r', ''));
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {}
    }

    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.contain);
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: AppColors.hudCyan, strokeWidth: 2));
        },
    if (!kIsWeb) {
      try {
        final file = io.File(path);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.contain);
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

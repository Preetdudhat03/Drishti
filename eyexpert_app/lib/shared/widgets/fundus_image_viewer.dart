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

    return Container(
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
                Flexible(
                  child: Row(
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
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.deepSpace.withValues(alpha: 0.80),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.imageId!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.qualityLabel != null)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.deepSpace.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      widget.qualityLabel!,
                      style: const TextStyle(
                        color: AppColors.electricBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 4. Floating HUD Mode Switcher & Opacity Slider Pill
          if (widget.showControls)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: _buildFloatingHudControls(hasGradcam, hasEnhanced),
            ),
        ],
      ),
    );
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
          fit: StackFit.expand,
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
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _splitRatio = (_splitRatio + details.delta.dx / w).clamp(0.05, 0.95);
                });
              },
              child: Stack(
                fit: StackFit.expand,
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(widget.originalImagePath),
                  Positioned(top: 40, left: 10, child: _tagBadge('OPTICAL VIEW')),
                ],
              ),
            ),
            Container(width: 1.5, color: AppColors.borderDark),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasGradcam)
                    _buildImage(widget.gradcamImagePath!)
                  else
                    _buildImage(widget.originalImagePath),
                  Positioned(top: 40, left: 10, child: _tagBadge('GRAD-CAM XAI')),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildFloatingHudControls(bool hasGradcam, bool hasEnhanced) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.deepSpace.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Switcher Buttons
            _modeBtn(FundusViewerMode.original, 'RAW', Icons.image_outlined),
            if (hasEnhanced) ...[
              const SizedBox(width: 4),
              _modeBtn(FundusViewerMode.compare, 'CLAHE', Icons.compare_rounded),
            ],
            if (hasGradcam) ...[
              const SizedBox(width: 4),
              _modeBtn(FundusViewerMode.overlay, 'OVERLAY', Icons.layers_outlined),
              const SizedBox(width: 4),
              _modeBtn(FundusViewerMode.xai, 'XAI MAP', Icons.grain_rounded),
            ],

            // Opacity Slider (only when Overlay mode is active)
            if (_currentMode == FundusViewerMode.overlay && hasGradcam) ...[
              const SizedBox(width: 6),
              Container(height: 18, width: 1, color: AppColors.borderDark),
              const SizedBox(width: 6),
              const Text(
                'BLEND',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkTextMuted,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(
                width: 75,
                height: 24,
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 2,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 8),
                    activeTrackColor: AppColors.hudCyan,
                    inactiveTrackColor: AppColors.elevatedSurface,
                    thumbColor: AppColors.hudCyan,
                  ),
                  child: Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() => _opacity = val);
                      widget.onOpacityChanged?.call(val);
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(width: 6),
            Container(height: 18, width: 1, color: AppColors.borderDark),
            const SizedBox(width: 2),

            // Reset Zoom
            _iconAction(Icons.restart_alt_rounded, 'Reset Zoom', _resetZoom),
          ],
        ),
      ),
    );
  }

  Widget _modeBtn(FundusViewerMode mode, String label, IconData icon) {
    final isActive = _currentMode == mode;
    return InkWell(
      onTap: () {
        setState(() => _currentMode = mode);
        widget.onModeChanged?.call(mode);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.hudCyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? AppColors.hudCyan : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? AppColors.hudCyan : AppColors.darkTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? AppColors.hudCyan : AppColors.darkTextSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
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
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }

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

class _HorizontalSplitClipper extends CustomClipper<Rect> {
  final double splitRatio;
  _HorizontalSplitClipper({required this.splitRatio});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(size.width * splitRatio, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(_HorizontalSplitClipper oldClipper) => oldClipper.splitRatio != splitRatio;
}

class _RetinalReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;

    final paint = Paint()
      ..color = AppColors.hudCyan.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final accentPaint = Paint()
      ..color = AppColors.hudCyan.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Outer alignment circle
    canvas.drawCircle(center, radius, paint);

    // Inner macular target
    canvas.drawCircle(center, radius * 0.28, paint);

    // Corner brackets
    const bracketLen = 14.0;
    // Top-left
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx - radius + bracketLen, center.dy), accentPaint);
    // Right
    canvas.drawLine(Offset(center.dx + radius, center.dy), Offset(center.dx + radius - bracketLen, center.dy), accentPaint);
    // Top
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy - radius + bracketLen), accentPaint);
    // Bottom
    canvas.drawLine(Offset(center.dx, center.dy + radius), Offset(center.dx, center.dy + radius - bracketLen), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

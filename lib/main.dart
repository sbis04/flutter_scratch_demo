import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:web_haptics/web_haptics.dart';

import 'web_audio_player.dart';

void main() {
  runApp(const MyApp());
}

const _cardColors = [
  Color(0xFF00E5FF), // neon cyan
  Color(0xFF76FF03), // neon green
  Color(0xFFFF4081), // neon pink
  Color(0xFFFFD740), // neon amber
  Color(0xFFE040FB), // neon purple
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scratch Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: const ScratchCardPage(),
    );
  }
}

class ScratchCardPage extends StatefulWidget {
  const ScratchCardPage({super.key});

  @override
  State<ScratchCardPage> createState() => _ScratchCardPageState();
}

class _ScratchCardPageState extends State<ScratchCardPage> {
  late final PageController _pageController;
  late final WebHaptics _haptics;
  late final WebAudioPlayer _scratchAudio;
  int _currentPage = 0;
  int _resetGeneration = 0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _haptics = WebHaptics();
    _scratchAudio = WebAudioPlayer()..load('assets/scratch.mp3');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _haptics.destroy();
    _scratchAudio.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _cardColors.length) return;
    _haptics.trigger('rigid');
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Story-style segment indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStorySegments(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor:
                          Colors.black.withValues(alpha: 0.45),
                      fixedSize: const Size(40, 40),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _resetGeneration++),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Colors.black.withValues(alpha: 0.45),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    child: const Text('RESET ALL'),
                  ),
                ],
              ),
            ),
            // Card area with arrows overlaid
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cardColors.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      return Center(
                        child: ScratchCard(
                          key: ValueKey('$index-$_resetGeneration'),
                          color: _cardColors[index],
                          haptics: _haptics,
                          audio: _scratchAudio,
                          isMuted: _isMuted,
                          onScratchActiveChanged: (_) {},
                        ),
                      );
                    },
                  ),
                  // Left arrow
                  Positioned(
                    left: 8,
                    bottom: 24,
                    child: _buildNavArrow(
                      Icons.chevron_left,
                      _currentPage > 0
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                    ),
                  ),
                  // Right arrow
                  Positioned(
                    right: 8,
                    bottom: 24,
                    child: _buildNavArrow(
                      Icons.chevron_right,
                      _currentPage < _cardColors.length - 1
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStorySegments() {
    return Row(
      children: List.generate(_cardColors.length, (i) {
        final isActive = i == _currentPage;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? _cardColors[i]
                  : Colors.black.withValues(alpha: 0.1),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _cardColors[i].withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        iconSize: 24,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(
            alpha: enabled ? 0.06 : 0.02,
          ),
          foregroundColor: Colors.black.withValues(alpha: enabled ? 0.5 : 0.15),
          shape: const CircleBorder(),
          fixedSize: const Size(40, 40),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Self-contained scratch card widget
// ---------------------------------------------------------------------------

class ScratchCard extends StatefulWidget {
  const ScratchCard({
    super.key,
    required this.color,
    required this.haptics,
    required this.audio,
    required this.isMuted,
    required this.onScratchActiveChanged,
  });

  final Color color;
  final WebHaptics haptics;
  final WebAudioPlayer audio;
  final bool isMuted;
  final ValueChanged<bool> onScratchActiveChanged;

  @override
  State<ScratchCard> createState() => _ScratchCardState();
}

// Scratch haptic presets — velocity-mapped string presets.
// Using string presets ensures the proven code path through
// _normalizeInput (avoids potential `is HapticPreset` issues on web).
// Ordered from lightest to heaviest for velocity-based selection.
const _scratchPresets = ['selection', 'light', 'soft', 'medium', 'heavy'];

class _ScratchCardState extends State<ScratchCard>
    with SingleTickerProviderStateMixin {
  final List<List<Offset>> _scratchPaths = [];
  List<Offset> _currentPath = [];
  Offset? _pointerPosition;
  bool _isScratching = false;
  bool _isRevealed = false;

  double _rotateX = 0;
  double _rotateY = 0;

  final Set<int> _scratchedCells = {};
  static const int _gridSize = 20;

  static const double _cardWidth = 320;
  static const double _cardHeight = 440;
  static const double _scratchRadius = 28;

  final GlobalKey _cardKey = GlobalKey();

  late final AnimationController _revealController;
  late final Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  RenderBox? get _cardBox =>
      _cardKey.currentContext?.findRenderObject() as RenderBox?;

  void _onPointerDown(PointerDownEvent event) {
    if (_isRevealed) return;
    final box = _cardBox;
    if (box == null) return;
    final local = box.globalToLocal(event.position);
    setState(() {
      _isScratching = true;
      _currentPath = [local];
      _pointerPosition = local;
      _updateTilt(local);
      _markScratched(local);
    });
    widget.onScratchActiveChanged(true);
    // Initial contact — crisp tap
    widget.haptics.trigger('medium');
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isScratching || _isRevealed) return;
    final box = _cardBox;
    if (box == null) return;
    final local = box.globalToLocal(event.position);
    final wasPlaying = _currentPath.length > 1;
    setState(() {
      _currentPath.add(local);
      _pointerPosition = local;
      _updateTilt(local);
      _markScratched(local);
    });
    if (!wasPlaying && !widget.isMuted) widget.audio.play();

    // Scratch haptics — pick preset based on pointer speed
    if (_currentPath.length % 2 == 0) {
      final speed = _currentPath.length >= 2
          ? (local - _currentPath[_currentPath.length - 2]).distance
          : 0.0;
      // Map speed to a preset index: slow → 'selection', fast → 'heavy'
      final idx =
          (speed / 10).clamp(0, _scratchPresets.length - 1).floor();
      widget.haptics.trigger(_scratchPresets[idx]);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_currentPath.isNotEmpty) {
      _scratchPaths.add(List.from(_currentPath));
    }
    setState(() {
      _isScratching = false;
      _currentPath = [];
      _pointerPosition = null;
      _rotateX = 0;
      _rotateY = 0;
    });
    widget.onScratchActiveChanged(false);
    widget.audio.stop();
    _checkReveal();
  }

  void _updateTilt(Offset local) {
    final dx = (local.dx - _cardWidth / 2) / (_cardWidth / 2);
    final dy = (local.dy - _cardHeight / 2) / (_cardHeight / 2);
    _rotateY = dx.clamp(-1.0, 1.0) * 10;
    _rotateX = -dy.clamp(-1.0, 1.0) * 10;
  }

  void _markScratched(Offset pos) {
    final cw = _cardWidth / _gridSize;
    final ch = _cardHeight / _gridSize;
    for (int i = -2; i <= 2; i++) {
      for (int j = -2; j <= 2; j++) {
        final px = pos.dx + i * _scratchRadius * 0.4;
        final py = pos.dy + j * _scratchRadius * 0.4;
        final x = (px / cw).floor();
        final y = (py / ch).floor();
        if (x >= 0 && x < _gridSize && y >= 0 && y < _gridSize) {
          _scratchedCells.add(y * _gridSize + x);
        }
      }
    }
  }

  void _checkReveal() {
    final pct = _scratchedCells.length / (_gridSize * _gridSize);
    if (pct > 0.4 && !_isRevealed) {
      setState(() => _isRevealed = true);
      widget.audio.stop();
      _revealController.forward();
      // Celebratory reveal — ascending double-tap
      widget.haptics.trigger('success');
      // Follow up with a heavier thud after a beat
      Future.delayed(
        const Duration(milliseconds: 200),
        () => widget.haptics.trigger('heavy'),
      );
    }
  }

  void _reset() {
    _revealController.reset();
    setState(() {
      _scratchPaths.clear();
      _currentPath.clear();
      _scratchedCells.clear();
      _pointerPosition = null;
      _isScratching = false;
      _isRevealed = false;
      _rotateX = 0;
      _rotateY = 0;
    });
    widget.haptics.trigger('soft');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: _isScratching
              ? SystemMouseCursors.none
              : (_isRevealed
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click),
          child: AnimatedContainer(
            duration: Duration(milliseconds: _isScratching ? 0 : 400),
            curve: Curves.easeOutBack,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_rotateX * pi / 180)
              ..rotateY(_rotateY * pi / 180),
            transformAlignment: Alignment.center,
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              child: Container(
                key: _cardKey,
                width: _cardWidth,
                height: _cardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRevealed ? widget.color : Colors.black)
                          .withValues(alpha: 0.12),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      _buildRevealContent(),
                      if (!_isRevealed)
                        RepaintBoundary(
                          child: CustomPaint(
                            size: const Size(_cardWidth, _cardHeight),
                            painter: _ScratchOverlayPainter(
                              paths: _scratchPaths,
                              currentPath: _currentPath,
                              scratchRadius: _scratchRadius,
                            ),
                          ),
                        ),
                      if (_pointerPosition != null &&
                          _isScratching &&
                          !_isRevealed)
                        Positioned(
                          left: _pointerPosition!.dx - 20,
                          top: _pointerPosition!.dy - 20,
                          child: IgnorePointer(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildBottomAction(),
      ],
    );
  }

  Widget _buildRevealContent() {
    return AnimatedBuilder(
      animation: _revealAnimation,
      builder: (context, child) {
        return Container(
          width: _cardWidth,
          height: _cardHeight,
          decoration: BoxDecoration(
            color: widget.color,
            border: _isRevealed
                ? Border.all(
                    color: widget.color.withValues(alpha: 0.6),
                    width: 2,
                  )
                : null,
          ),
          child: Center(
            child: Icon(
              Icons.flutter_dash,
              size: 200,
              color: Colors.black.withValues(alpha: 0.85),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction() {
    if (_isRevealed) {
      return InkWell(
        onTap: _reset,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.card_giftcard,
                color: Colors.black.withValues(alpha: 0.5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'SCRATCH AGAIN',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontSize: 13,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 43,
      child: Text(
        'SCRATCH TO REVEAL',
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.35),
          fontSize: 13,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter for the silver scratch overlay
// ---------------------------------------------------------------------------

class _ScratchOverlayPainter extends CustomPainter {
  final List<List<Offset>> paths;
  final List<Offset> currentPath;
  final double scratchRadius;

  _ScratchOverlayPainter({
    required this.paths,
    required this.currentPath,
    required this.scratchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    final overlayPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [
          Color(0xFFE8E8E8),
          Color(0xFFD0D0D0),
          Color(0xFFE2E2E2),
          Color(0xFFC8C8C8),
        ],
        [0.0, 0.35, 0.65, 1.0],
      );
    canvas.drawRect(Offset.zero & size, overlayPaint);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'SCRATCH',
        style: TextStyle(
          color: Color(0xFF999999),
          fontSize: 14,
          letterSpacing: 4,
          fontWeight: FontWeight.w300,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );

    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = scratchRadius * 2;

    for (final pts in [...paths, currentPath]) {
      if (pts.isEmpty) continue;
      if (pts.length == 1) {
        canvas.drawCircle(
          pts.first,
          scratchRadius,
          Paint()..blendMode = BlendMode.clear,
        );
        continue;
      }
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, clearPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScratchOverlayPainter old) => true;
}

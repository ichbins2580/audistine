import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// 마음 쉼터 - 모닥불 (장작 불멍 & 직접 장작 쓰기)
class ZenCampfire extends StatefulWidget {
  final bool isActive;
  const ZenCampfire({super.key, this.isActive = true});

  @override
  State<ZenCampfire> createState() => _ZenCampfireState();
}

class _FlameParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;
  double life;
  double maxLife;
  Color baseColor;

  _FlameParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.life,
    required this.maxLife,
    required this.baseColor,
  });
}

class _CampfireSpark {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;
  double wobbleOffset;
  Color color;

  _CampfireSpark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.wobbleOffset,
    required this.color,
  });
}

class _ThoughtLog {
  final String label;
  final bool isCustom;
  bool isBurned = false;

  _ThoughtLog({required this.label, this.isCustom = false});
}

class _ZenCampfireState extends State<ZenCampfire> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _random = Random();
  final TextEditingController _customInputController = TextEditingController();

  final List<_FlameParticle> _flames = [];
  final List<_CampfireSpark> _sparks = [];

  double _viewWidth = 360.0;
  final double _viewHeight = 280.0;

  int _frameCounter = 0;
  int _burnedCount = 0;
  bool _isPaused = false;
  String _message = '타오르는 불꽃과 불씨를 가만히 바라보며 마음의 온기를 느껴보세요 🔥';

  final List<String> _initialLogWords = [
    '불안', '조급함', '자책', '타인의 시선',
    '미래 걱정', '피로감', '완벽주의', '무기력',
  ];
  late List<_ThoughtLog> _logs;
  final List<({String label, bool isCustom})> _lastThoughts = [];

  @override
  void initState() {
    super.initState();
    _lastThoughts.addAll(_initialLogWords.map((w) => (label: w, isCustom: false)));
    _logs = _lastThoughts.map((t) => _ThoughtLog(label: t.label, isCustom: t.isCustom)).toList();

    _ticker = AnimationController(vsync: this, duration: const Duration(days: 999))
      ..addListener(_onTick);

    if (widget.isActive) {
      _ticker.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ZenCampfire oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (!_isPaused && !_ticker.isAnimating) _ticker.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      if (_ticker.isAnimating) _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _customInputController.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted || _isPaused) return;

    _frameCounter++;

    final centerX = _viewWidth / 2;
    final baseY = _viewHeight - 40;
    final flameColors = [
      const Color(0xFFE54B2E),
      const Color(0xFFF28E2B),
      const Color(0xFFF8C646),
    ];

    // 1. 불꽃 파티클 생성
    for (int i = 0; i < 4; i++) {
      final ox = (_random.nextDouble() - 0.5) * 24.0;
      final maxL = 26.0 + _random.nextDouble() * 20.0;
      _flames.add(_FlameParticle(
        x: centerX + ox,
        y: baseY,
        vx: (_random.nextDouble() - 0.5) * 0.9,
        vy: -(2.0 + _random.nextDouble() * 2.2),
        size: 14.0 + _random.nextDouble() * 14.0,
        alpha: 0.85,
        life: 0,
        maxLife: maxL,
        baseColor: flameColors[_random.nextInt(flameColors.length)],
      ));
    }

    // 2. 불티 생성
    if (_frameCounter % 4 == 0) {
      _sparks.add(_CampfireSpark(
        x: centerX + (_random.nextDouble() - 0.5) * 28,
        y: baseY - 20,
        vx: (_random.nextDouble() - 0.5) * 1.4,
        vy: -(1.6 + _random.nextDouble() * 2.4),
        size: 1.5 + _random.nextDouble() * 2.5,
        alpha: 1.0,
        wobbleOffset: _random.nextDouble() * 10,
        color: const Color(0xFFFFD15C),
      ));
    }

    // 3. 불꽃 수명 업데이트
    for (int i = _flames.length - 1; i >= 0; i--) {
      final f = _flames[i];
      f.life += 1.0;
      f.x += f.vx;
      f.y += f.vy;
      f.size = max(1.5, f.size * 0.95);
      f.alpha = (1.0 - (f.life / f.maxLife)).clamp(0.0, 1.0);

      if (f.life >= f.maxLife || f.alpha <= 0) {
        _flames.removeAt(i);
      }
    }

    // 4. 스파크 업데이트
    for (int i = _sparks.length - 1; i >= 0; i--) {
      final s = _sparks[i];
      s.x += s.vx + sin((_frameCounter + s.wobbleOffset) * 0.1) * 0.4;
      s.y += s.vy;
      s.alpha -= 0.012;

      if (s.alpha <= 0 || s.y < 15) {
        _sparks.removeAt(i);
      }
    }

    setState(() {});
  }

  void _burnThoughtLog(_ThoughtLog log) {
    if (log.isBurned) return;

    HapticFeedback.mediumImpact();
    SoundService.playChime();

    setState(() {
      log.isBurned = true;
      _burnedCount++;
      _message = '[${log.label}] 마음이 불꽃 속에서 온전히 타올라 재와 온기로 흩어졌습니다 🍃';
    });

    final centerX = _viewWidth / 2;
    final baseY = _viewHeight - 40;

    // 장작 투입 시 화려한 황금 불티 폭발
    for (int i = 0; i < 40; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * 1.8;
      final speed = 2.2 + _random.nextDouble() * 4.5;
      _sparks.add(_CampfireSpark(
        x: centerX + (_random.nextDouble() - 0.5) * 30,
        y: baseY - 15,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 2.0 + _random.nextDouble() * 3.5,
        alpha: 1.0,
        wobbleOffset: _random.nextDouble() * 10,
        color: const Color(0xFFFFECC0),
      ));
    }
  }

  void _showAddCustomLogDialog() {
    _customInputController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgPanel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('🪵', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '비우고 싶은 마음 적기',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '지금 머릿속을 어지럽히는 생각이나 스트레스를 적어 화로에 올려보세요. 불꽃에 닿으면 깨끗이 사라집니다.',
                style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _customInputController,
                maxLength: 20,
                autofocus: true,
                style: GoogleFonts.gowunDodum(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '예: 오늘 회의 실수, 지나간 말실수, 시험 걱정...',
                  hintStyle: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.textDim),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: AppColors.bgPanel2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.inkLine),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accentVermilion, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('취소', style: GoogleFonts.gowunDodum(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _customInputController.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          _logs.insert(0, _ThoughtLog(label: text, isCustom: true));
                          _lastThoughts.insert(0, (label: text, isCustom: true));
                          _message = '새로운 장작 [$text](이)가 준비되었습니다. 터치하여 불에 올려보세요 🪵';
                        });
                        HapticFeedback.lightImpact();
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentVermilion,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('장작으로 올리기 🪵', style: GoogleFonts.gowunDodum(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetLogs() {
    HapticFeedback.lightImpact();
    setState(() {
      _lastThoughts
        ..clear()
        ..addAll(_initialLogWords.map((w) => (label: w, isCustom: false)));
      _logs = _lastThoughts.map((t) => _ThoughtLog(label: t.label, isCustom: t.isCustom)).toList();
      _message = '기본 장작들이 다시 채워졌습니다. 비우고 싶은 마음을 불에 올려보세요 🪵';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 타이틀 & 모닥불 상태
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '모닥불 (장작 불멍)',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentVermilion,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentVermilion.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '비운 잡념: $_burnedCount개',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentVermilion,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 모닥불 캔버스 뷰
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewWidth = constraints.maxWidth;

                return GestureDetector(
                  onTap: () {
                    // 화면 터치 시 화사한 불티 생성
                    final centerX = _viewWidth / 2;
                    final baseY = _viewHeight - 40;
                    for (int i = 0; i < 15; i++) {
                      _sparks.add(_CampfireSpark(
                        x: centerX + (_random.nextDouble() - 0.5) * 30,
                        y: baseY - 15,
                        vx: (_random.nextDouble() - 0.5) * 2.0,
                        vy: -(2.0 + _random.nextDouble() * 2.5),
                        size: 2.0 + _random.nextDouble() * 2.0,
                        alpha: 1.0,
                        wobbleOffset: _random.nextDouble() * 10,
                        color: const Color(0xFFFFD15C),
                      ));
                    }
                  },
                  child: Container(
                    width: _viewWidth,
                    height: _viewHeight,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, 0.5),
                        radius: 1.1,
                        colors: [Color(0xFF38190B), Color(0xFF180A04), Color(0xFF0A0402)], // 모닥불의 아늑한 붉은빛
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 불꽃 & 베이스 장작 렌더러
                        CustomPaint(
                          size: Size(_viewWidth, _viewHeight),
                          painter: _CampfirePainter(
                            flames: _flames,
                            sparks: _sparks,
                            viewWidth: _viewWidth,
                            viewHeight: _viewHeight,
                          ),
                        ),

                        // 우측 상단 일시정지 버튼
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isPaused = !_isPaused;
                                if (_isPaused) {
                                  _ticker.stop();
                                } else {
                                  _ticker.repeat();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPaused ? Icons.play_arrow : Icons.pause,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),

                        // 좌측 상단 안내 캡션
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Text(
                            '🔥 장작 모닥불 : 타오르는 불꽃과 흩날리는 힐링 불티',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 10.5,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 잡념 장작 헤더 & [✍️ 직접 적기], [기본 채우기], [반복] 버튼
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text(
                '🪵 태울 장작 터치하기',
                style: GoogleFonts.gowunDodum(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  // 1. 직접 쓰기 버튼
                  InkWell(
                    onTap: _showAddCustomLogDialog,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.accentVermilion.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accentVermilion.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 12, color: AppColors.accentVermilion),
                          const SizedBox(width: 3),
                          Text(
                            '직접 적기',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentVermilion,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 2. 장작 다시 채우기 버튼
                  InkWell(
                    onTap: _resetLogs,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.bgPanel2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.inkLine),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text('기본 채우기', style: GoogleFonts.gowunDodum(fontSize: 10.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 장작 칩 목록 (직접 적은 장작은 황금빛으로 강조 표시)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _logs.map((log) {
              return InkWell(
                onTap: log.isBurned ? null : () => _burnThoughtLog(log),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: log.isBurned
                        ? AppColors.bgDeep
                        : (log.isCustom
                            ? const Color(0xFFFFECC0)
                            : const Color(0xFF6B4226).withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: log.isBurned
                          ? AppColors.inkLineLight
                          : (log.isCustom ? AppColors.accentBrass : const Color(0xFF9E6238)),
                      width: log.isCustom && !log.isBurned ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        log.isBurned ? '💨' : (log.isCustom ? '✍️' : '🪵'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.label,
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11.5,
                          fontWeight: log.isBurned ? FontWeight.normal : FontWeight.bold,
                          color: log.isBurned
                              ? AppColors.textDim
                              : (log.isCustom ? const Color(0xFF633A0C) : const Color(0xFF5A3114)),
                          decoration: log.isBurned ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // 안내 텍스트
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgCardWarm,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: Text(
              _message,
              style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampfirePainter extends CustomPainter {
  final List<_FlameParticle> flames;
  final List<_CampfireSpark> sparks;
  final double viewWidth;
  final double viewHeight;

  _CampfirePainter({
    required this.flames,
    required this.sparks,
    required this.viewWidth,
    required this.viewHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = viewWidth / 2;
    final baseY = viewHeight - 35;

    // 1. 하단 붉은 숯불 온기 글로우
    final glowPaint = Paint()
      ..color = const Color(0xFFE54B2E).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, baseY), width: 140, height: 45),
      glowPaint,
    );

    // 2. 교차된 장작 통나무
    final logPaint = Paint()
      ..color = const Color(0xFF381F12)
      ..style = PaintingStyle.fill;
    final logHighlight = Paint()
      ..color = const Color(0xFF54311D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 좌측 대각선 장작
    canvas.save();
    canvas.translate(centerX - 18, baseY + 6);
    canvas.rotate(-0.25);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 68, height: 14), const Radius.circular(4)), logPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 68, height: 14), const Radius.circular(4)), logHighlight);
    canvas.restore();

    // 우측 대각선 장작
    canvas.save();
    canvas.translate(centerX + 18, baseY + 6);
    canvas.rotate(0.25);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 68, height: 14), const Radius.circular(4)), logPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 68, height: 14), const Radius.circular(4)), logHighlight);
    canvas.restore();

    // 중앙 가로 작은 장작
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, baseY + 12), width: 50, height: 10), const Radius.circular(3)),
      logPaint,
    );

    // 3. 타오르는 불꽃 파티클
    for (final f in flames) {
      final fPaint = Paint()
        ..color = f.baseColor.withValues(alpha: f.alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(f.x, f.y), f.size, fPaint);
    }

    // 4. 밤하늘로 피어오르는 불티(스파크)
    for (final s in sparks) {
      final sPaint = Paint()
        ..color = s.color.withValues(alpha: s.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(s.x, s.y), s.size, sPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CampfirePainter oldDelegate) => true;
}

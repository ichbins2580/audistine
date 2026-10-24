import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// 마음 쉼터 - 단비 (비 내리는 연못, 빗방울 물멍 & 생각 잎 씻어내기)
class ZenRainPond extends StatefulWidget {
  final bool isActive;
  const ZenRainPond({super.key, this.isActive = true});

  @override
  State<ZenRainPond> createState() => _ZenRainPondState();
}

class _WaterRipple {
  Offset center;
  double radius;
  double maxRadius;
  double alpha;
  Color color;
  int ringCount;

  _WaterRipple({
    required this.center,
    required this.maxRadius,
    required this.color,
    this.ringCount = 2,
  })  : radius = 2.0,
        alpha = 1.0;
}

class _ThoughtLeaf {
  final String label;
  final bool isCustom;
  bool isCleared = false;
  Offset position;
  Offset velocity;
  double alpha;
  bool isDissolving;
  double dissolveProgress;

  _ThoughtLeaf({
    required this.label,
    required this.position,
    required this.velocity,
    this.isCustom = false,
  })  : alpha = 1.0,
        isDissolving = false,
        dissolveProgress = 0.0;
}

class _WaterParticle {
  Offset position;
  Offset velocity;
  double alpha;
  double size;
  Color color;

  _WaterParticle({
    required this.position,
    required this.velocity,
    required this.alpha,
    required this.size,
    required this.color,
  });
}

class _ZenRainPondState extends State<ZenRainPond> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _random = Random();
  final TextEditingController _customInputController = TextEditingController();

  final List<_WaterRipple> _ripples = [];
  final List<_ThoughtLeaf> _leaves = [];
  final List<_WaterParticle> _particles = [];

  double _viewWidth = 360.0;
  final double _viewHeight = 280.0;

  int _frameCounter = 0;
  int _clearedCount = 0;
  bool _isPaused = false;
  String _message = '잔잔한 물결과 빗방울을 바라보며 마음을 씻어내보세요 💧';

  final List<String> _initialLeafWords = [
    '불안', '잡념', '피로', '과거 후회', '조급함',
    '타인의 시선', '긴장', '복잡한 생각', '자책', '미래 걱정',
  ];

  final List<({String label, bool isCustom})> _lastThoughts = [];
  bool _isInfiniteLoop = false;
  Timer? _infiniteRespawnTimer;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 999))
      ..addListener(_onTick);

    if (widget.isActive) {
      _ticker.repeat();
    }

    _initThoughtLeaves();
  }

  @override
  void didUpdateWidget(covariant ZenRainPond oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (!_isPaused && !_ticker.isAnimating) _ticker.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      if (_ticker.isAnimating) _ticker.stop();
    }
  }

  @override
  void dispose() {
    _infiniteRespawnTimer?.cancel();
    _ticker.dispose();
    _customInputController.dispose();
    super.dispose();
  }

  void _initThoughtLeaves([List<({String label, bool isCustom})>? customList]) {
    _leaves.clear();
    final targetList = customList ?? _initialLeafWords.map((w) => (label: w, isCustom: false)).toList();
    _lastThoughts
      ..clear()
      ..addAll(targetList);

    for (final item in targetList) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 0.15 + _random.nextDouble() * 0.25;
      _leaves.add(_ThoughtLeaf(
        label: item.label,
        isCustom: item.isCustom,
        position: Offset(
          40 + _random.nextDouble() * (_viewWidth > 80 ? _viewWidth - 80 : 280),
          40 + _random.nextDouble() * 200,
        ),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
      ));
    }
  }

  void _resetLeaves() {
    HapticFeedback.lightImpact();
    setState(() {
      _initThoughtLeaves();
      _message = '기본 생각 잎들이 다시 채워졌습니다. 비우고 싶은 마음을 물에 띄워보세요 🍃';
    });
  }

  void _repeatLeaves() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_lastThoughts.isEmpty) {
        _initThoughtLeaves();
      } else {
        final currentCopy = List<({String label, bool isCustom})>.from(_lastThoughts);
        _initThoughtLeaves(currentCopy);
      }
      _message = '생각 잎 ${_leaves.length}개를 물에 띄웠습니다. 마음을 비우는 과정을 편안하게 이어가세요 🍃';
    });
  }

  void _toggleInfiniteLoop() {
    HapticFeedback.lightImpact();
    setState(() {
      _isInfiniteLoop = !_isInfiniteLoop;
      if (_isInfiniteLoop) {
        _message = '무한 반복이 설정되었습니다. 모든 잎이 씻겨나가면 자동으로 다시 띄웁니다 ♾️';
        if (_leaves.isEmpty || _leaves.every((l) => l.isCleared)) {
          _repeatLeaves();
        }
      } else {
        _infiniteRespawnTimer?.cancel();
        _message = '무한 반복이 해제되었습니다 🍃';
      }
    });
  }

  void _onTick() {
    if (!mounted || _isPaused) return;

    _frameCounter++;

    // 1. 단비 빗방울 자동 생성 (부드러운 주기)
    if (_frameCounter % 14 == 0) {
      _spawnRandomRainDrop();
    }

    // 2. 파문 업데이트
    for (int i = _ripples.length - 1; i >= 0; i--) {
      final r = _ripples[i];
      r.radius += 1.4;
      r.alpha -= 0.015;

      // 파문과 떠다니는 생각 충돌 검사
      for (final leaf in _leaves) {
        if (!leaf.isCleared && !leaf.isDissolving) {
          final dist = (r.center - leaf.position).distance;
          if ((dist - r.radius).abs() < 18) {
            _dissolveLeaf(leaf);
          }
        }
      }

      if (r.alpha <= 0 || r.radius >= r.maxRadius) {
        _ripples.removeAt(i);
      }
    }

    // 3. 떠다니는 생각(잎) 업데이트
    for (final leaf in _leaves) {
      if (leaf.isDissolving) {
        leaf.dissolveProgress += 0.04;
        leaf.alpha -= 0.04;
        if (leaf.alpha <= 0) {
          leaf.alpha = 0;
        }
      } else if (!leaf.isCleared) {
        leaf.position += leaf.velocity;
        // 가장자리 튕김
        if (leaf.position.dx < 30 || leaf.position.dx > _viewWidth - 30) {
          leaf.velocity = Offset(-leaf.velocity.dx, leaf.velocity.dy);
        }
        if (leaf.position.dy < 30 || leaf.position.dy > _viewHeight - 30) {
          leaf.velocity = Offset(leaf.velocity.dx, -leaf.velocity.dy);
        }
      }
    }

    // 4. 물방울 파티클 업데이트
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.position += p.velocity;
      p.velocity += const Offset(0, 0.05); // 미세 중력
      p.alpha -= 0.02;
      if (p.alpha <= 0) {
        _particles.removeAt(i);
      }
    }

    setState(() {});
  }

  void _spawnRandomRainDrop() {
    final x = 20 + _random.nextDouble() * (_viewWidth - 40);
    final y = 20 + _random.nextDouble() * (_viewHeight - 40);
    final colors = [
      const Color(0xFF68B0AB),
      const Color(0xFF8FC1B5),
      const Color(0xFFD4B996),
      Colors.white.withValues(alpha: 0.8),
    ];

    _ripples.add(_WaterRipple(
      center: Offset(x, y),
      maxRadius: 45 + _random.nextDouble() * 35,
      color: colors[_random.nextInt(colors.length)],
      ringCount: _random.nextInt(2) + 2,
    ));
  }

  void _addTouchRipple(Offset pos) {
    HapticFeedback.selectionClick();
    _ripples.add(_WaterRipple(
      center: pos,
      maxRadius: 65 + _random.nextDouble() * 25,
      color: const Color(0xFF98D7C2),
      ringCount: 3,
    ));

    // 터치한 곳 근처의 잡념도 부드럽게 정화
    for (final leaf in _leaves) {
      if (!leaf.isCleared && !leaf.isDissolving && (leaf.position - pos).distance < 45) {
        _dissolveLeaf(leaf);
      }
    }
  }

  void _dissolveLeaf(_ThoughtLeaf leaf) {
    if (leaf.isCleared) return;

    leaf.isCleared = true;
    leaf.isDissolving = true;
    _clearedCount++;
    HapticFeedback.lightImpact();
    SoundService.playChime();

    setState(() {
      _message = '[${leaf.label}] 생각이 맑은 물결에 녹아 깨끗이 비워졌습니다 🍃';
    });

    // 파문 및 영롱한 물방울 파티클 방출
    _ripples.add(_WaterRipple(
      center: leaf.position,
      maxRadius: 55 + _random.nextDouble() * 20,
      color: const Color(0xFF8FC1B5),
      ringCount: 3,
    ));

    for (int i = 0; i < 18; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 0.8 + _random.nextDouble() * 2.5;
      _particles.add(_WaterParticle(
        position: leaf.position,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        alpha: 1.0,
        size: 2.0 + _random.nextDouble() * 2.5,
        color: const Color(0xFF8FC1B5),
      ));
    }

    // 무한 반복 모드인 경우: 남은 잎이 모두 정화되었을 때 자동으로 재생성
    if (_isInfiniteLoop) {
      final willAllBeCleared = _leaves.every((l) => l.isCleared || l == leaf);
      if (willAllBeCleared) {
        _infiniteRespawnTimer?.cancel();
        _infiniteRespawnTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted && _isInfiniteLoop) {
            _repeatLeaves();
          }
        });
      }
    }
  }

  void _showAddCustomLeafDialog() {
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
                  const Text('🍃', style: TextStyle(fontSize: 20)),
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
                '지금 머릿속을 어지럽히는 생각이나 스트레스를 적어 잎에 띄워보세요. 빗방울과 물결에 닿으면 맑게 씻겨 나갑니다.',
                style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _customInputController,
                maxLength: 20,
                autofocus: true,
                style: GoogleFonts.gowunDodum(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '예: 불안한 마음, 지나간 후회, 사람 관계 걱정...',
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
                    borderSide: const BorderSide(color: AppColors.accentJade, width: 1.5),
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
                          final angle = _random.nextDouble() * 2 * pi;
                          final speed = 0.15 + _random.nextDouble() * 0.2;
                          _leaves.insert(
                            0,
                            _ThoughtLeaf(
                              label: text,
                              position: Offset(
                                _viewWidth / 2 + (_random.nextDouble() - 0.5) * 60,
                                _viewHeight / 2 + (_random.nextDouble() - 0.5) * 60,
                              ),
                              velocity: Offset(cos(angle) * speed, sin(angle) * speed),
                              isCustom: true,
                            ),
                          );
                          _lastThoughts.insert(0, (label: text, isCustom: true));
                          _message = '새로운 생각 잎 [$text](이)가 준비되었습니다. 터치하여 물결에 씻어내보세요 🍃';
                        });
                        HapticFeedback.lightImpact();
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentJade,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('잎으로 띄우기 🍃', style: GoogleFonts.gowunDodum(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
          // 상단 타이틀 & 물멍 상태 (비운 잡념 수: 수면 오른쪽 위)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌧️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '단비 (빗방울 물멍)',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentJade,
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
                  color: AppColors.accentJade.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '비운 잡념: $_clearedCount개',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentJade,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 연못 수면 캔버스 (물멍 뷰)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewWidth = constraints.maxWidth;

                return GestureDetector(
                  onTapDown: (details) => _addTouchRipple(details.localPosition),
                  onPanUpdate: (details) {
                    if (_frameCounter % 4 == 0) {
                      _addTouchRipple(details.localPosition);
                    }
                  },
                  child: Container(
                    width: _viewWidth,
                    height: _viewHeight,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.2),
                        radius: 1.1,
                        colors: [
                          Color(0xFF1E3A3A), // 달빛 비치는 연못 중심
                          Color(0xFF0F1F1F), // 깊은 밤 수면
                          Color(0xFF081212),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 물결 파문 & 파티클 렌더링
                        CustomPaint(
                          size: Size(_viewWidth, _viewHeight),
                          painter: _RainPondPainter(
                            ripples: _ripples,
                            particles: _particles,
                          ),
                        ),

                        // 수면 위에 떠다니는 생각 잎들 (터치 가능)
                        ..._leaves.where((l) => !l.isCleared || l.alpha > 0).map((leaf) => _buildFloatingLeafWidget(leaf)),

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
                            '🌧️ 단비 : 연못에 떨어지는 빗방울과 생각 정화',
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

          // 수면 아래: 씻어버릴 생각 헤더 & [✍️ 직접 적기], [기본 채우기], [반복] 버튼
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text(
                '🍃 씻어버릴 생각 터치하기',
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
                  // 1. 직접 적기 버튼
                  InkWell(
                    onTap: _showAddCustomLeafDialog,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.accentJade.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accentJade.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 12, color: AppColors.accentJade),
                          const SizedBox(width: 3),
                          Text(
                            '직접 적기',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentJade,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 2. 기본 잎 다시 띄우기 버튼
                  InkWell(
                    onTap: _resetLeaves,
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
                  // 3. 무한 반복 토글 버튼
                  InkWell(
                    onTap: _toggleInfiniteLoop,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: _isInfiniteLoop
                            ? AppColors.accentBrass.withValues(alpha: 0.22)
                            : AppColors.bgPanel2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isInfiniteLoop ? AppColors.accentBrass : AppColors.inkLine,
                          width: _isInfiniteLoop ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            size: 13,
                            color: _isInfiniteLoop ? AppColors.accentBrass : AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _isInfiniteLoop ? '무한 반복 ON' : '무한 반복',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 10.5,
                              fontWeight: _isInfiniteLoop ? FontWeight.bold : FontWeight.normal,
                              color: _isInfiniteLoop ? AppColors.accentBrass : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 생각 잎 칩 목록 (직접 적은 잎은 황금빛으로 강조 표시)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _leaves.map((leaf) {
              return InkWell(
                onTap: leaf.isCleared ? null : () => _dissolveLeaf(leaf),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: leaf.isCleared
                        ? AppColors.bgDeep
                        : (leaf.isCustom
                            ? const Color(0xFF1B4D3E).withValues(alpha: 0.25)
                            : const Color(0xFF264E48).withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: leaf.isCleared
                          ? AppColors.inkLineLight
                          : (leaf.isCustom ? AppColors.accentBrass : const Color(0xFF68B0AB)),
                      width: leaf.isCustom && !leaf.isCleared ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        leaf.isCleared ? '💨' : (leaf.isCustom ? '✍️' : '🍃'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        leaf.label,
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11.5,
                          fontWeight: leaf.isCleared ? FontWeight.normal : FontWeight.bold,
                          color: leaf.isCleared
                              ? AppColors.textDim
                              : (leaf.isCustom ? const Color(0xFF1B4D3E) : const Color(0xFF224B43)),
                          decoration: leaf.isCleared ? TextDecoration.lineThrough : null,
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

  Widget _buildFloatingLeafWidget(_ThoughtLeaf leaf) {
    return Positioned(
      left: leaf.position.dx - 32,
      top: leaf.position.dy - 14,
      child: AnimatedOpacity(
        opacity: leaf.alpha.clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 100),
        child: GestureDetector(
          onTap: () => _dissolveLeaf(leaf),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: leaf.isCustom
                  ? const Color(0xFF1B4D3E).withValues(alpha: 0.9)
                  : const Color(0xFF264E48).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: leaf.isCustom ? AppColors.accentBrass : const Color(0xFF8FC1B5).withValues(alpha: 0.6),
                width: leaf.isCustom ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: leaf.isCustom
                      ? AppColors.accentBrass.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  leaf.isCustom ? '✍️' : '🍃',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 3),
                Text(
                  leaf.label,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: leaf.isCustom ? const Color(0xFFFFF9E6) : const Color(0xFFE2F3F0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RainPondPainter extends CustomPainter {
  final List<_WaterRipple> ripples;
  final List<_WaterParticle> particles;

  _RainPondPainter({required this.ripples, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 물결 파문 그리기
    for (final r in ripples) {
      for (int i = 0; i < r.ringCount; i++) {
        final ringRadius = r.radius - (i * 12.0);
        if (ringRadius <= 0) continue;

        final ringAlpha = (r.alpha * (1.0 - (i * 0.25))).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = r.color.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(0.8, 1.8 - (i * 0.4));

        canvas.drawCircle(r.center, ringRadius, paint);
      }

      // 파문 중심 작은 빗방울 빛
      if (r.radius < 15) {
        final dotPaint = Paint()
          ..color = r.color.withValues(alpha: r.alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(r.center, 2.0, dotPaint);
      }
    }

    // 2. 물방울 파티클 그리기
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.size, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPondPainter oldDelegate) => true;
}

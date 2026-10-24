import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'zen_rain_pond.dart';
import 'zen_campfire.dart';

/// 마음 쉼터의 비움 놀이터 (잡념벽돌, 멍때리기 [단비 / 모닥불], 모양 맞추기)
class ZenRestGame extends StatefulWidget {
  final bool isActive;
  const ZenRestGame({super.key, this.isActive = true});

  @override
  State<ZenRestGame> createState() => _ZenRestGameState();
}

class _ZenRestGameState extends State<ZenRestGame> {
  int _gameMode = 0; // 0: 잡념벽돌, 1: 단비 (물멍), 2: 모닥불 (불멍), 3: 모양 맞추기

  final List<({int id, String label, IconData icon})> _gameTabs = const [
    (id: 0, label: '🧱 잡념벽돌', icon: Icons.grid_view_rounded),
    (id: 1, label: '🌧️ 단비 (물멍)', icon: Icons.water_drop_outlined),
    (id: 2, label: '🔥 모닥불 (불멍)', icon: Icons.local_fire_department_outlined),
    (id: 3, label: '🌸 모양 맞추기', icon: Icons.auto_awesome),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 상단 4대 비움/멍때리기 선택 탭 바
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bgPanel2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.inkLine),
          ),
          child: Row(
            children: _gameTabs.map((tab) {
              final isSelected = (_gameMode == tab.id);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => setState(() => _gameMode = tab.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentJade.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentJade.withValues(alpha: 0.40)
                              : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tab.label,
                          style: GoogleFonts.gowunDodum(
                            fontSize: 12.0,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.accentJade : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 1. 잡념벽돌
        if (_gameMode == 0)
          _ZenBrickBreaker(isActive: widget.isActive)
        // 2. 단비 (물멍)
        else if (_gameMode == 1)
          ZenRainPond(isActive: widget.isActive)
        // 3. 모닥불 (불멍)
        else if (_gameMode == 2)
          ZenCampfire(isActive: widget.isActive)
        // 4. 모양 맞추기
        else
          _ZenShapeMatch(isActive: widget.isActive),
      ],
    );
  }
}

// -------------------------------------------------------------
// [게임 1] 스트레스 없는 젠 벽돌깨기 (Zen Brick Dissolve)
// -------------------------------------------------------------
class _ZenBrickBreaker extends StatefulWidget {
  final bool isActive;
  const _ZenBrickBreaker({this.isActive = true});

  @override
  State<_ZenBrickBreaker> createState() => _ZenBrickBreakerState();
}

class _BrickItem {
  final String label;
  final Color color;
  bool isDestroyed;
  Rect rect;

  _BrickItem({
    required this.label,
    required this.color,
    this.rect = Rect.zero,
  }) : isDestroyed = false;
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double alpha;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.alpha,
    required this.color,
  });
}

class _ZenBrickBreakerState extends State<_ZenBrickBreaker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final List<_BrickItem> _bricks = [];
  final List<_Particle> _particles = [];

  double _paddleX = 0.5;
  final double _paddleWidth = 84.0;
  final double _paddleHeight = 12.0;

  double _ballX = 150;
  double _ballY = 240;
  double _ballVx = 3.2;
  double _ballVy = -3.8;
  final double _ballRadius = 9.0;

  double _viewWidth = 360.0;
  double _viewHeight = 360.0;

  int _clearedCount = 0;
  String _encouragementText = '마음을 비우며 편안히 공을 튕겨보세요 🍃';
  final Random _random = Random();
  bool _isInitialized = false;
  bool _isPaused = false;

  static const List<String> _thoughtWords = [
    '걱정', '조급함', '피로', '후회', '불안', '압박',
    '자책', '긴장', '욕심', '과부하', '미련', '혼란',
  ];

  static const List<Color> _brickColors = [
    Color(0xFFE57373), Color(0xFFFFB74D), Color(0xFF81C784),
    Color(0xFF64B5F6), Color(0xFFBA68C8), Color(0xFF4DB6AC),
    Color(0xFFFF8A65), Color(0xFFAED581), Color(0xFF90CAF9),
    Color(0xFFCE93D8), Color(0xFF80CBC4), Color(0xFFFFCC80),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
  }

  @override
  void didUpdateWidget(covariant _ZenBrickBreaker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_ticker.isAnimating) {
        _ticker.stop();
        setState(() {
          _isPaused = true;
        });
      }
    }
  }

  void _initGame(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _viewWidth = size.width;
    _viewHeight = size.height;

    _isInitialized = true;
    _isPaused = false;
    _bricks.clear();
    const rows = 3;
    const cols = 4;
    final brickWidth = (size.width - 32 - (cols - 1) * 8) / cols;
    const brickHeight = 32.0;

    int wordIdx = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final left = 16.0 + c * (brickWidth + 8);
        final top = 20.0 + r * (brickHeight + 8);
        _bricks.add(
          _BrickItem(
            label: _thoughtWords[wordIdx % _thoughtWords.length],
            color: _brickColors[wordIdx % _brickColors.length],
            rect: Rect.fromLTWH(left, top, brickWidth, brickHeight),
          ),
        );
        wordIdx++;
      }
    }

    _ballX = size.width / 2;
    _ballY = size.height - 70;
    _ballVx = 3.0;
    _ballVy = -3.8;
    _paddleX = size.width / 2;

    _ticker.repeat();
  }

  void _togglePause() {
    if (!_isInitialized) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _ticker.stop();
        _encouragementText = '잠시 멈추었습니다 🍃 (화면이나 재생 버튼을 탭하여 계속하기)';
      } else {
        _ticker.repeat();
        _encouragementText = '마음을 비우며 편안히 공을 튕겨보세요 🍃';
      }
    });
  }

  void _resetGame() {
    _isInitialized = false;
    _isPaused = false;
    _clearedCount = 0;
    _particles.clear();
    _encouragementText = '맑은 마음으로 다시 비워냅니다 🌿';
    setState(() {});
  }

  void _gameLoop() {
    if (!mounted || _isPaused) return;

    setState(() {
      // 1. 공 이동
      _ballX += _ballVx;
      _ballY += _ballVy;

      // 좌우 벽 충돌 (화면 끝까지 정확하게 이동)
      if (_ballX - _ballRadius <= 0) {
        _ballX = _ballRadius;
        _ballVx = _ballVx.abs();
      } else if (_ballX + _ballRadius >= _viewWidth) {
        _ballX = _viewWidth - _ballRadius;
        _ballVx = -_ballVx.abs();
      }

      // 상단 벽 충돌
      if (_ballY - _ballRadius <= 0) {
        _ballY = _ballRadius;
        _ballVy = _ballVy.abs();
      }

      // 패들 충돌
      final paddleTop = _viewHeight - 35;
      final paddleLeft = _paddleX - _paddleWidth / 2;
      final paddleRight = _paddleX + _paddleWidth / 2;

      if (_ballY + _ballRadius >= paddleTop &&
          _ballY - _ballRadius <= paddleTop + _paddleHeight &&
          _ballX >= paddleLeft - 6 &&
          _ballX <= paddleRight + 6 &&
          _ballVy > 0) {
        _ballVy = -_ballVy.abs();
        final hitOffset = (_ballX - _paddleX) / (_paddleWidth / 2);
        _ballVx = (hitOffset * 4.0).clamp(-4.5, 4.5);
        if (_ballVx.abs() < 1.0) {
          _ballVx = _ballVx >= 0 ? 1.5 : -1.5;
        }
      }

      // 바닥으로 떨어졌을 때 (패널티 없음! 스트레스 프리 재부양)
      if (_ballY > _viewHeight + 20) {
        _ballX = _paddleX.clamp(_paddleWidth / 2, _viewWidth - _paddleWidth / 2);
        _ballY = paddleTop - 30;
        _ballVx = (_random.nextDouble() - 0.5) * 4.0;
        _ballVy = -3.5;
        _encouragementText = '괜찮아요, 마음을 편안하게 두고 천천히 이어가세요 🍵';
      }

      // 2. 벽돌 충돌 체크
      final ballRect = Rect.fromCircle(
        center: Offset(_ballX, _ballY),
        radius: _ballRadius,
      );

      for (final brick in _bricks) {
        if (!brick.isDestroyed && brick.rect.overlaps(ballRect)) {
          brick.isDestroyed = true;
          _clearedCount++;
          _ballVy = -_ballVy;

          // 파티클 생성
          for (int i = 0; i < 8; i++) {
            _particles.add(
              _Particle(
                x: brick.rect.center.dx,
                y: brick.rect.center.dy,
                vx: (_random.nextDouble() - 0.5) * 5,
                vy: (_random.nextDouble() - 0.5) * 5,
                alpha: 1.0,
                color: brick.color,
              ),
            );
          }

          SoundService.playChime();
          _encouragementText = '\'${brick.label}\' 생각이 맑게 흩어졌습니다 ✨';
          break;
        }
      }

      // 모든 벽돌을 비웠을 때 축하 파티클 버스트 & 자동 재생성
      if (_bricks.isNotEmpty && _bricks.every((b) => b.isDestroyed)) {
        for (int i = 0; i < 20; i++) {
          _particles.add(
            _Particle(
              x: _viewWidth / 2 + (_random.nextDouble() - 0.5) * 160,
              y: _viewHeight / 2 + (_random.nextDouble() - 0.5) * 100,
              vx: (_random.nextDouble() - 0.5) * 6,
              vy: (_random.nextDouble() - 0.5) * 6,
              alpha: 1.0,
              color: _brickColors[_random.nextInt(_brickColors.length)],
            ),
          );
        }
        for (final b in _bricks) {
          b.isDestroyed = false;
        }
        SoundService.playChime();
        _encouragementText = '모든 잡념을 깨끗이 비워냈습니다! 참 잘하셨어요 🌸';
      }

      // 3. 파티클 수명 감소
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.alpha -= 0.05;
      }
      _particles.removeWhere((p) => p.alpha <= 0);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentJade.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // 상단 상태 & 컨트롤 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.accentJade.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '비워낸 잡념: $_clearedCount개',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentJade,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 22,
                      color: _isPaused ? AppColors.accentJade : AppColors.accentBrass,
                    ),
                    tooltip: _isPaused ? '계속하기 (재개)' : '일시정지 (멈춤)',
                    onPressed: _togglePause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textMuted),
                    tooltip: '처음부터 다시 비우기',
                    onPressed: _resetGame,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 온화한 메시지
          Text(
            _encouragementText,
            style: GoogleFonts.gowunDodum(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // 캔버스 영역
          Container(
            height: 360,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                if (!_isInitialized ||
                    (_viewWidth - constraints.maxWidth).abs() > 2) {
                  _initGame(Size(constraints.maxWidth, constraints.maxHeight));
                }

                return Stack(
                  children: [
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        if (_isPaused) return;
                        setState(() {
                          _paddleX = details.localPosition.dx
                              .clamp(_paddleWidth / 2, constraints.maxWidth - _paddleWidth / 2);
                        });
                      },
                      onTapDown: (details) {
                        if (_isPaused) {
                          _togglePause();
                          return;
                        }
                        setState(() {
                          _paddleX = details.localPosition.dx
                              .clamp(_paddleWidth / 2, constraints.maxWidth - _paddleWidth / 2);
                        });
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _ZenBreakerPainter(
                          bricks: _bricks,
                          particles: _particles,
                          ballX: _ballX,
                          ballY: _ballY,
                          ballRadius: _ballRadius,
                          paddleX: _paddleX,
                          paddleWidth: _paddleWidth,
                          paddleHeight: _paddleHeight,
                        ),
                      ),
                    ),
                    if (_isPaused)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _togglePause,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgDeep.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgPanel,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.accentJade.withValues(alpha: 0.3)),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 32,
                                      color: AppColors.accentJade,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '잠시 멈춤 중',
                                    style: GoogleFonts.gowunDodum(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '화면을 탭하여 계속 마음을 비워보세요 🍃',
                                    style: GoogleFonts.gowunDodum(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isPaused
                ? '화면 또는 상단 재생(▶) 버튼을 누르면 이어집니다 🍵'
                : '패들을 좌우로 부드럽게 터치하여 움직여보세요 🍃',
            style: GoogleFonts.gowunDodum(fontSize: 11, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _ZenBreakerPainter extends CustomPainter {
  final List<_BrickItem> bricks;
  final List<_Particle> particles;
  final double ballX;
  final double ballY;
  final double ballRadius;
  final double paddleX;
  final double paddleWidth;
  final double paddleHeight;

  _ZenBreakerPainter({
    required this.bricks,
    required this.particles,
    required this.ballX,
    required this.ballY,
    required this.ballRadius,
    required this.paddleX,
    required this.paddleWidth,
    required this.paddleHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 벽돌 그리기
    for (final brick in bricks) {
      if (brick.isDestroyed) continue;

      final rrect = RRect.fromRectAndRadius(brick.rect, const Radius.circular(6));
      final fillPaint = Paint()
        ..color = brick.color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = brick.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, borderPaint);

      // 단어 라벨 (가독성을 위해 진한 먹빛 텍스트 및 가독성 최적화)
      final textSpan = TextSpan(
        text: brick.label,
        style: GoogleFonts.gowunDodum(
          fontSize: 12,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 2,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: brick.rect.width);

      textPainter.paint(
        canvas,
        Offset(
          brick.rect.center.dx - textPainter.width / 2,
          brick.rect.center.dy - textPainter.height / 2,
        ),
      );
    }

    // 2. 파티클 그리기
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), 3.0 * p.alpha, pPaint);
    }

    // 3. 패들 그리기
    final paddleTop = size.height - 35;
    final paddleRect = Rect.fromLTWH(
      paddleX - paddleWidth / 2,
      paddleTop,
      paddleWidth,
      paddleHeight,
    );
    final paddleRRect = RRect.fromRectAndRadius(paddleRect, const Radius.circular(6));
    final paddlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accentJade, AppColors.accentBrass],
      ).createShader(paddleRect);

    canvas.drawRRect(paddleRRect, paddlePaint);

    // 4. 젠 볼 (빛나는 구슬) 그리기
    final ballCenter = Offset(ballX, ballY);
    // 외부 글로우
    final glowPaint = Paint()
      ..color = AppColors.accentBrass.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(ballCenter, ballRadius + 3, glowPaint);

    // 내부 구체
    final ballPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballCenter, ballRadius, ballPaint);
  }

  @override
  bool shouldRepaint(covariant _ZenBreakerPainter oldDelegate) => true;
}

// -------------------------------------------------------------
// [게임 2] 모양 & 물결 짝맞추기 (Zen Shape & Flow)
// -------------------------------------------------------------
class _ZenShapeMatch extends StatefulWidget {
  final bool isActive;
  const _ZenShapeMatch({this.isActive = true});

  @override
  State<_ZenShapeMatch> createState() => _ZenShapeMatchState();
}

class _ShapeCard {
  final int id;
  final String symbol;
  final String name;
  final Color color;
  bool isFlipped;
  bool isMatched;

  _ShapeCard({
    required this.id,
    required this.symbol,
    required this.name,
    required this.color,
  })  : isFlipped = false,
        isMatched = false;
}

class _FireworkParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;
  double rotation;
  double rotationSpeed;
  Color color;
  int shapeType; // 0: 원형 글로우, 1: 별빛 스파클, 2: 콘페티 리본

  _FireworkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.shapeType,
  });
}

class _ZenShapeMatchState extends State<_ZenShapeMatch>
    with SingleTickerProviderStateMixin {
  late AnimationController _fireworkTicker;
  final List<_FireworkParticle> _fireworkParticles = [];
  final List<_ShapeCard> _cards = [];
  final Random _random = Random();

  int? _firstFlippedIndex;
  bool _isProcessing = false;
  int _matchedPairs = 0;
  bool _isCompleted = false;
  String _message = '두 개의 같은 마음 문양을 골라보세요 🌸';

  double _boardWidth = 360.0;
  final double _boardHeight = 480.0;

  static const List<({String symbol, String name, Color color})> _shapePresets = [
    (symbol: '🌿', name: '녹음', color: AppColors.accentJade),
    (symbol: '🌸', name: '연꽃', color: Color(0xFFF48FB1)),
    (symbol: '🌙', name: '달빛', color: AppColors.accentBrass),
    (symbol: '🪨', name: '조약돌', color: Color(0xFF90A4AE)),
    (symbol: '🍵', name: '온기', color: Color(0xFFFFB74D)),
    (symbol: '🌊', name: '물결', color: Color(0xFF64B5F6)),
  ];

  @override
  void initState() {
    super.initState();
    _fireworkTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateFireworks);
    _initCards();
  }

  @override
  void didUpdateWidget(covariant _ZenShapeMatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_fireworkTicker.isAnimating) {
        _fireworkTicker.stop();
      }
    }
  }

  @override
  void dispose() {
    _fireworkTicker.dispose();
    super.dispose();
  }

  void _initCards() {
    _cards.clear();
    _firstFlippedIndex = null;
    _isProcessing = false;
    _matchedPairs = 0;
    _isCompleted = false;
    _fireworkParticles.clear();
    if (_fireworkTicker.isAnimating) {
      _fireworkTicker.stop();
    }
    _message = '마음을 비우고 편안하게 같은 문양을 맞춰보세요 🌸';

    final List<_ShapeCard> deck = [];
    int cardId = 0;
    for (final p in _shapePresets) {
      deck.add(_ShapeCard(id: cardId++, symbol: p.symbol, name: p.name, color: p.color));
      deck.add(_ShapeCard(id: cardId++, symbol: p.symbol, name: p.name, color: p.color));
    }
    deck.shuffle(Random());
    _cards.addAll(deck);
    setState(() {});
  }

  void _launchFireworks() {
    _fireworkParticles.clear();

    final w = _boardWidth.clamp(280.0, 600.0);
    final h = _boardHeight.clamp(350.0, 700.0);

    // 5개의 폭죽 폭발 진원지 (상단 좌/우, 중앙, 하단 좌/우)
    final origins = [
      Offset(w * 0.22, h * 0.22),
      Offset(w * 0.78, h * 0.22),
      Offset(w * 0.50, h * 0.38),
      Offset(w * 0.32, h * 0.58),
      Offset(w * 0.68, h * 0.58),
    ];

    const colors = [
      Color(0xFFFFD54F), // 골드 옐로우
      Color(0xFF81C784), // 맑은 옥색
      Color(0xFFF48FB1), // 은은한 벚꽃 핑크
      Color(0xFF64B5F6), // 청량한 물결 블루
      Color(0xFFFF8A65), // 따뜻한 산호 코랄
      Color(0xFFCE93D8), // 부드러운 라벤더
      Color(0xFFFFF59D), // 별빛 옐로우
      Colors.white,
    ];

    for (int b = 0; b < origins.length; b++) {
      final origin = origins[b];
      final count = 20 + _random.nextInt(6);
      for (int i = 0; i < count; i++) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 2.2 + _random.nextDouble() * 4.8;
        _fireworkParticles.add(
          _FireworkParticle(
            x: origin.dx,
            y: origin.dy,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 1.8,
            size: 3.2 + _random.nextDouble() * 4.0,
            alpha: 1.0,
            rotation: _random.nextDouble() * 2 * pi,
            rotationSpeed: (_random.nextDouble() - 0.5) * 0.22,
            color: colors[_random.nextInt(colors.length)],
            shapeType: _random.nextInt(3),
          ),
        );
      }
    }

    _fireworkTicker.repeat();
  }

  void _updateFireworks() {
    if (!mounted || _fireworkParticles.isEmpty) {
      if (_fireworkTicker.isAnimating && _fireworkParticles.isEmpty) {
        _fireworkTicker.stop();
      }
      return;
    }

    setState(() {
      for (final p in _fireworkParticles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.12; // 중력 효과 (자연스러운 포물선 낙하)
        p.vx *= 0.98; // 공기 저항
        p.rotation += p.rotationSpeed;
        p.alpha -= 0.016; // 부드러운 페이드아웃
      }
      _fireworkParticles.removeWhere(
          (p) => p.alpha <= 0 || p.y > _boardHeight + 60);
      if (_fireworkParticles.isEmpty && _fireworkTicker.isAnimating) {
        _fireworkTicker.stop();
      }
    });
  }

  void _onCardTap(int index) async {
    if (_isProcessing) return;
    if (_cards[index].isFlipped || _cards[index].isMatched) return;

    setState(() {
      _cards[index].isFlipped = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      final first = _cards[_firstFlippedIndex!];
      final second = _cards[index];

      if (first.name == second.name) {
        // 일치!
        _isProcessing = true;
        SoundService.playChime();
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        final isAllDone = (_matchedPairs + 1) == _shapePresets.length;

        setState(() {
          first.isMatched = true;
          second.isMatched = true;
          _matchedPairs++;
          _firstFlippedIndex = null;
          _isProcessing = false;

          if (isAllDone) {
            _isCompleted = true;
            _message = '모든 문양의 조화를 찾았습니다! 온전한 평온이 함께합니다 🌸';
          } else {
            _message = '\'${first.name}\'의 평온이 마음에 머뭅니다 ✨';
          }
        });

        if (isAllDone) {
          // 🎉 폭죽 발사!
          _launchFireworks();

          // 축하 시그널 2차 징 소리
          await Future.delayed(const Duration(milliseconds: 280));
          if (mounted) {
            SoundService.playChime();
          }
        }
      } else {
        // 불일치 -> 잠시 후 뒤집기
        _isProcessing = true;
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;

        setState(() {
          first.isFlipped = false;
          second.isFlipped = false;
          _firstFlippedIndex = null;
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        _boardWidth = constraints.maxWidth;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgPanel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isCompleted
                      ? AppColors.accentBrass.withValues(alpha: 0.8)
                      : AppColors.accentBrass.withValues(alpha: 0.4),
                  width: _isCompleted ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isCompleted
                              ? AppColors.accentBrass.withValues(alpha: 0.22)
                              : AppColors.accentBrass.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: _isCompleted
                              ? Border.all(
                                  color: AppColors.accentBrass
                                      .withValues(alpha: 0.5))
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isCompleted) ...[
                              const Text('🎉 ', style: TextStyle(fontSize: 12)),
                            ],
                            Text(
                              _isCompleted
                                  ? '축하합니다! 조화 완성 (6/6)'
                                  : '완성된 조화: $_matchedPairs / ${_shapePresets.length}',
                              style: GoogleFonts.gowunDodum(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentBrass,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            size: 20, color: AppColors.textMuted),
                        tooltip: '다시 섞기',
                        onPressed: _initCards,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _message,
                    style: GoogleFonts.gowunDodum(
                      fontSize: 12.5,
                      color: _isCompleted
                          ? AppColors.accentBrass
                          : AppColors.textSecondary,
                      fontWeight:
                          _isCompleted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3x4 그리드
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cards.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (ctx, index) {
                      final card = _cards[index];
                      final isRevealed = card.isFlipped || card.isMatched;

                      return GestureDetector(
                        onTap: () => _onCardTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: isRevealed
                                ? card.color.withValues(alpha: 0.15)
                                : AppColors.bgDeep,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRevealed
                                  ? card.color
                                  : AppColors.inkLine,
                              width: isRevealed ? 1.5 : 1.0,
                            ),
                            boxShadow: isRevealed
                                ? [
                                    BoxShadow(
                                      color: card.color.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isRevealed
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(card.symbol,
                                          style: const TextStyle(fontSize: 24)),
                                      const SizedBox(height: 2),
                                      Text(
                                        card.name,
                                        style: GoogleFonts.gowunDodum(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: card.color,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Icon(
                                    Icons.spa_outlined,
                                    size: 20,
                                    color: AppColors.textDim,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 축하 시그널 배너 (모두 맞췄을 때 등장)
                  if (_isCompleted) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _launchFireworks,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accentBrass.withValues(alpha: 0.18),
                              AppColors.accentJade.withValues(alpha: 0.18),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accentBrass.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accentBrass.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('✨ 🎆 ',
                                    style: TextStyle(fontSize: 16)),
                                Text(
                                  '축하합니다! 온전한 조화 완성',
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentBrass,
                                  ),
                                ),
                                const Text(' 🎆 ✨',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '흩어졌던 생각들이 편안하게 모이고 맑은 고요가 깃들었습니다.\n지금의 평온한 숨결을 마음에 담아보세요 ☕',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.gowunDodum(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _initCards,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(
                                '다시 맞추며 머리 비우기 🌸',
                                style: GoogleFonts.gowunDodum(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentJade,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      '순서에 구애받지 않고 마음이 이끄는 카드를 편안히 열어보세요 🍵',
                      style: GoogleFonts.gowunDodum(
                          fontSize: 11, color: AppColors.textDim),
                    ),
                  ],
                ],
              ),
            ),

            // 🎆 축하 폭죽 오버레이 캔버스
            if (_fireworkParticles.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FireworkPainter(particles: _fireworkParticles),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 폭죽 및 콘페티 파티클 렌더러
class _FireworkPainter extends CustomPainter {
  final List<_FireworkParticle> particles;

  _FireworkPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.shapeType == 0) {
        // 1. 원형 글로우 파티클
        final glowPaint = Paint()
          ..color = p.color.withValues(alpha: (p.alpha * 0.45).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
        canvas.drawCircle(Offset.zero, p.size + 2.5, glowPaint);
        canvas.drawCircle(Offset.zero, p.size, paint);
      } else if (p.shapeType == 1) {
        // 2. 별빛 스파클 (✨)
        final s = p.size * 1.5;
        final path = Path()
          ..moveTo(0, -s)
          ..quadraticBezierTo(0, 0, s, 0)
          ..quadraticBezierTo(0, 0, 0, s)
          ..quadraticBezierTo(0, 0, -s, 0)
          ..quadraticBezierTo(0, 0, 0, -s);
        canvas.drawPath(path, paint);
      } else {
        // 3. 콘페티 리본 / 다이아몬드
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 1.8,
          height: p.size * 0.9,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FireworkPainter oldDelegate) => true;
}

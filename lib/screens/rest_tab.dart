import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../models/imagery_model.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../widgets/zen_rest_game.dart';
import '../widgets/header_date_time.dart';

enum RestMode { breathing, imagery, meditation, zenGame }

class RestTab extends StatefulWidget {
  final RestMode? initialMode;
  final int refreshKey;
  final bool isActive;

  const RestTab({
    super.key,
    this.initialMode,
    this.refreshKey = 0,
    this.isActive = true,
  });

  @override
  State<RestTab> createState() => _RestTabState();
}

class _RestTabState extends State<RestTab> with SingleTickerProviderStateMixin {
  static final RegExp _whitespaceRegex = RegExp(r'\s+');
  RestMode _mode = RestMode.zenGame;

  // --- 복식호흡 관련 상태 ---
  bool _isBreathingActive = false;
  int _breathingPhase = 0; // 0: 들숨, 1: 멈춤, 2: 날숨, 3: 멈춤
  int _breathingSecondsLeft = 4;
  int _completedCycles = 0;
  Timer? _breathingTimer;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  // --- 심상화(Imagery) 관련 상태 ---
  List<ImagerySlot> _imagerySlots = ImagerySlot.defaultSlots();
  int _selectedSlotIndex = 0;
  int _imageryTargetMinutes = 3;
  int _imagerySecondsRemaining = 180;
  bool _isImageryRunning = false;
  Timer? _imageryTimer;
  final ValueNotifier<int> _imagerySecondsNotifier = ValueNotifier<int>(180);
  final ValueNotifier<bool> _imageryRunningNotifier = ValueNotifier<bool>(false);
  final ImagePicker _imagePicker = ImagePicker();

  // --- 명상 타이머 관련 상태 ---
  int _meditationTargetMinutes = 3;
  int _meditationSecondsRemaining = 180;
  bool _isMeditationRunning = false;
  Timer? _meditationTimer;

  final List<({String label, int seconds, String desc})> _breathingPhases = const [
    (label: '들숨 (들이마시기)', seconds: 4, desc: '코로 깊고 천천히 숨을 들이마십니다'),
    (label: '멈춤 (숨 머금기)', seconds: 4, desc: '가슴과 아랫배를 편안히 유지합니다'),
    (label: '날숨 (내쉬기)', seconds: 4, desc: '입이나 코로 온몸의 긴장을 풀며 내쉽니다'),
    (label: '멈춤 (비움 유지)', seconds: 4, desc: '비워진 상태의 고요함을 가만히 느껴봅니다'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      _mode = widget.initialMode!;
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
    _loadImagerySlots();
  }

  @override
  void didUpdateWidget(covariant RestTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _stopAllActivities();
    }
    if (widget.refreshKey != oldWidget.refreshKey || widget.initialMode != oldWidget.initialMode) {
      if (widget.initialMode != null) {
        setState(() {
          _mode = widget.initialMode!;
        });
      }
    }
  }

  void _stopAllActivities() {
    _stopBreathing();
    _stopImagery();
    _stopMeditation();
  }

  Future<void> _loadImagerySlots() async {
    final slots = await StorageService.loadImagerySlots();
    if (!mounted) return;
    setState(() {
      _imagerySlots = slots;
    });
  }

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _imageryTimer?.cancel();
    _meditationTimer?.cancel();
    _animController.dispose();
    _imagerySecondsNotifier.dispose();
    _imageryRunningNotifier.dispose();
    super.dispose();
  }

  // --- 복식호흡 로직 ---
  void _toggleBreathing() {
    if (_isBreathingActive) {
      _stopBreathing();
    } else {
      _startBreathing();
    }
  }

  void _startBreathing() {
    setState(() {
      _isBreathingActive = true;
      _breathingPhase = 0;
      _breathingSecondsLeft = _breathingPhases[0].seconds;
    });

    _animController.duration = Duration(seconds: _breathingPhases[0].seconds);
    _animController.forward(from: 0.0);

    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_breathingSecondsLeft > 1) {
          _breathingSecondsLeft--;
        } else {
          _breathingPhase = (_breathingPhase + 1) % 4;
          _breathingSecondsLeft = _breathingPhases[_breathingPhase].seconds;
          SoundService.playChime(); // 4-4-4-4 페이즈(들숨/멈춤/날숨/멈춤) 전환 0초 도달 시 종소리 1회

          if (_breathingPhase == 0) {
            _completedCycles++;
            _animController.duration = Duration(seconds: _breathingPhases[0].seconds);
            _animController.forward(from: 0.0);
          } else if (_breathingPhase == 1) {
            // 멈춤
          } else if (_breathingPhase == 2) {
            _animController.duration = Duration(seconds: _breathingPhases[2].seconds);
            _animController.reverse(from: 1.0);
          } else if (_breathingPhase == 3) {
            // 멈춤
          }
        }
      });
    });
  }

  void _stopBreathing() {
    _breathingTimer?.cancel();
    _animController.stop();
    setState(() {
      _isBreathingActive = false;
      _breathingPhase = 0;
      _breathingSecondsLeft = 4;
    });
  }

  // --- 평온의 심상화 로직 ---
  void _selectImageryMinutes(int minutes) {
    if (_isImageryRunning) return;
    setState(() {
      _imageryTargetMinutes = minutes;
      _imagerySecondsRemaining = minutes * 60;
      _imagerySecondsNotifier.value = _imagerySecondsRemaining;
    });
  }

  void _toggleImagery() {
    if (_isImageryRunning) {
      _stopImagery();
    } else {
      _startImagery();
    }
  }

  void _startImagery() {
    setState(() {
      _isImageryRunning = true;
      _imageryRunningNotifier.value = true;
      if (_imagerySecondsRemaining <= 0) {
        _imagerySecondsRemaining = _imageryTargetMinutes * 60;
      }
      _imagerySecondsNotifier.value = _imagerySecondsRemaining;
    });

    _imageryTimer?.cancel();
    _imageryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_imagerySecondsRemaining > 1) {
          _imagerySecondsRemaining--;
          _imagerySecondsNotifier.value = _imagerySecondsRemaining;
        } else {
          _imagerySecondsRemaining = 0;
          _imagerySecondsNotifier.value = 0;
          _isImageryRunning = false;
          _imageryRunningNotifier.value = false;
          timer.cancel();
          SoundService.playChime(); // 설정한 심상화 시간이 0이 되면 종소리 1회
          _showImageryFinishDialog();
        }
      });
    });
  }

  void _stopImagery() {
    _imageryTimer?.cancel();
    setState(() {
      _isImageryRunning = false;
      _imageryRunningNotifier.value = false;
    });
  }

  void _resetImagery() {
    _stopImagery();
    setState(() {
      _imagerySecondsRemaining = _imageryTargetMinutes * 60;
      _imagerySecondsNotifier.value = _imagerySecondsRemaining;
    });
  }

  void _openImageryFullScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _ImageryFullScreenViewer(
              slots: _imagerySlots,
              initialIndex: _selectedSlotIndex,
              secondsNotifier: _imagerySecondsNotifier,
              runningNotifier: _imageryRunningNotifier,
              onTogglePlay: _toggleImagery,
              onReset: _resetImagery,
              onIndexChanged: (newIdx) {
                setState(() => _selectedSlotIndex = newIdx);
              },
              buildImageWidget: (url) => _buildImageryImage(url, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }

  void _showImageryFinishDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgPanel,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    '심상화 명상 완료',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '마음속 평온의 공간에 편안하게 머물렀습니다.\n그곳의 고요함과 따스함을 가슴에 담고 편안한 하루를 이어가세요.',
                style: GoogleFonts.gowunDodum(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBrass,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('확인', style: GoogleFonts.gowunDodum(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PC 웹 및 모바일에서 어떤 대용량 사진이 들어와도 600px 초경량(~50KB)으로 변환하는 리사이저
  Future<Uint8List> _resizeImageBytes(Uint8List rawBytes, {int targetWidth = 600}) async {
    try {
      final codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: targetWidth,
      );
      final frameInfo = await codec.getNextFrame();
      final byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('이미지 리사이징 오류: $e');
    }
    return rawBytes;
  }

  void _editImagerySlot(int index) {
    final slot = _imagerySlots[index];
    String currentImageUrl = slot.imageUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppColors.bgPanel,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '평온의 사진 ${index + 1} 등록',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 1. 현재 사진 미리보기 & 삭제 버튼
                if (currentImageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 170,
                      color: AppColors.bgPanel2,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImageryImage(currentImageUrl),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✓ 사진 등록됨',
                                style: GoogleFonts.gowunDodum(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => setDialogState(() => currentImageUrl = ''),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 2. [📷 내 사진첩 / 갤러리에서 사진 올리기] 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final XFile? picked = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          final rawBytes = await picked.readAsBytes();
                          final resizedBytes = await _resizeImageBytes(rawBytes, targetWidth: 480);
                          final base64Data = base64Encode(resizedBytes);
                          final base64Str = 'data:image/png;base64,$base64Data';
                          setDialogState(() {
                            currentImageUrl = base64Str;
                          });
                        }
                      } catch (e) {
                        debugPrint('사진 가져오기 실패: $e');
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 17),
                    label: Text(
                      currentImageUrl.isNotEmpty ? '다른 사진으로 바꾸기' : '내 사진첩 / 갤러리에서 사진 올리기',
                      style: GoogleFonts.gowunDodum(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentJade,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '사진을 등록하지 않고 비워두면 상상만으로 명상합니다.',
                  style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.textDim),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: Text('취소', style: GoogleFonts.gowunDodum(fontSize: 13, color: AppColors.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final updatedSlot = ImagerySlot(
                          id: index + 1,
                          title: '사진 ${index + 1}',
                          imageUrl: currentImageUrl.trim(),
                          description: '',
                        );
                        Navigator.pop(ctx);
                        setState(() {
                          _imagerySlots[index] = updatedSlot;
                          _selectedSlotIndex = index;
                        });
                        await StorageService.saveImagerySlot(index, updatedSlot);
                        if (!mounted) return;
                        _loadImagerySlots();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '사진이 평온의 공간 ${index + 1}번에 저장되었습니다 🌿',
                              style: GoogleFonts.gowunDodum(color: Colors.white, fontSize: 13),
                            ),
                            backgroundColor: AppColors.accentJade,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBrass,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('저장', style: GoogleFonts.gowunDodum(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 명상 타이머 로직 ---
  void _selectMeditationMinutes(int minutes) {
    if (_isMeditationRunning) return;
    setState(() {
      _meditationTargetMinutes = minutes;
      _meditationSecondsRemaining = minutes * 60;
    });
  }

  void _toggleMeditation() {
    if (_isMeditationRunning) {
      _stopMeditation();
    } else {
      _startMeditation();
    }
  }

  void _startMeditation() {
    setState(() {
      _isMeditationRunning = true;
      if (_meditationSecondsRemaining <= 0) {
        _meditationSecondsRemaining = _meditationTargetMinutes * 60;
      }
    });

    _meditationTimer?.cancel();
    _meditationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_meditationSecondsRemaining > 1) {
          _meditationSecondsRemaining--;
        } else {
          _meditationSecondsRemaining = 0;
          _isMeditationRunning = false;
          timer.cancel();
          SoundService.playChime(); // 설정한 명상 시간이 0이 되면 종소리 1회
          _showMeditationFinishDialog();
        }
      });
    });
  }

  void _stopMeditation() {
    _meditationTimer?.cancel();
    setState(() {
      _isMeditationRunning = false;
    });
  }

  void _resetMeditation() {
    _stopMeditation();
    setState(() {
      _meditationSecondsRemaining = _meditationTargetMinutes * 60;
    });
  }

  void _showMeditationFinishDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgPanel,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '명상 완료',
                style: GoogleFonts.gowunDodum(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_meditationTargetMinutes분간의 명상을 마쳤습니다.\n지금 이 순간의 맑은 알아차림을 하루 동안 간직하세요.',
                style: GoogleFonts.gowunDodum(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBrass,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('확인', style: GoogleFonts.gowunDodum(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSeconds(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  final Map<String, Uint8List> _base64Cache = {};

  Uint8List? _getCachedBase64(String cleanUrl) {
    if (_base64Cache.containsKey(cleanUrl)) {
      return _base64Cache[cleanUrl];
    }
    try {
      final commaIdx = cleanUrl.indexOf(',');
      final base64Data = (commaIdx != -1 ? cleanUrl.substring(commaIdx + 1) : cleanUrl)
          .replaceAll(_whitespaceRegex, '');
      final bytes = base64Decode(base64Data);
      _base64Cache[cleanUrl] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// 웹 이미지 URL 및 Base64 이미지 지원 렌더러
  Widget _buildImageryImage(String imageUrl, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty) {
      return const Center(child: Icon(Icons.self_improvement, size: 40, color: AppColors.accentBrass));
    }
    if (cleanUrl.startsWith('data:image')) {
      final bytes = _getCachedBase64(cleanUrl);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.image_not_supported_outlined, size: 20, color: AppColors.textDim),
          ),
        );
      }
      return const Center(child: Icon(Icons.broken_image_outlined, size: 20, color: AppColors.textDim));
    }
    return Image.network(
      cleanUrl,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 20, color: AppColors.textDim),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : (constraints.maxWidth < 360 ? 12 : 20),
                vertical: isDesktop ? 24 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 860 : 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildModeToggle(),
                      const SizedBox(height: 20),
                      if (_mode == RestMode.breathing)
                        _buildBreathingView()
                      else if (_mode == RestMode.imagery)
                        _buildImageryView()
                      else if (_mode == RestMode.meditation)
                        _buildMeditationView()
                      else
                        ZenRestGame(isActive: widget.isActive),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inkLine, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 마음 쉼터 제목 (중앙 정렬)
          Center(
            child: Text(
              '마음 쉼터',
              style: GoogleFonts.gowunDodum(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accentJade,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. 첫 화면과 동일한 위치에 날짜, 시각 표시
          const HeaderDateTime(),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPanel2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Row(
        children: [
          _buildToggleOption(
            label: '복식 호흡',
            icon: Icons.air,
            isSelected: _mode == RestMode.breathing,
            onTap: () {
              if (_mode != RestMode.breathing) {
                _stopMeditation();
                _stopImagery();
                setState(() => _mode = RestMode.breathing);
              }
            },
          ),
          _buildToggleOption(
            label: '심상화',
            icon: Icons.image_outlined,
            isSelected: _mode == RestMode.imagery,
            onTap: () {
              if (_mode != RestMode.imagery) {
                _stopBreathing();
                _stopMeditation();
                setState(() => _mode = RestMode.imagery);
              }
            },
          ),
          _buildToggleOption(
            label: '명상',
            icon: Icons.timer_outlined,
            isSelected: _mode == RestMode.meditation,
            onTap: () {
              if (_mode != RestMode.meditation) {
                _stopBreathing();
                _stopImagery();
                setState(() => _mode = RestMode.meditation);
              }
            },
          ),
          _buildToggleOption(
            label: '비움 놀이',
            icon: Icons.sports_esports_outlined,
            isSelected: _mode == RestMode.zenGame,
            onTap: () {
              if (_mode != RestMode.zenGame) {
                _stopBreathing();
                _stopImagery();
                _stopMeditation();
                setState(() => _mode = RestMode.zenGame);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentBrass.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentBrass.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.accentBrass : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.gowunDodum(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.accentBrass : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 1. 복식호흡 뷰
  // -------------------------------------------------------------------------
  Widget _buildBreathingView() {
    final currentPhase = _breathingPhases[_breathingPhase];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.bgPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inkLineLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _isBreathingActive ? currentPhase.label : '4-4-4-4 박스 호흡법',
                style: GoogleFonts.gowunDodum(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isBreathingActive ? AppColors.accentJade : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isBreathingActive ? currentPhase.desc : '중앙의 원을 탭하면 호흡 가이드가 시작됩니다',
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunDodum(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),

              // 애니메이션 원 (탭하여 시작 / 정지)
              InkWell(
                onTap: _toggleBreathing,
                borderRadius: BorderRadius.circular(115),
                splashColor: AppColors.accentJade.withValues(alpha: 0.2),
                highlightColor: Colors.transparent,
                child: SizedBox(
                  height: 230,
                  width: 230,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentJade.withValues(alpha: 0.04),
                          border: Border.all(
                            color: _isBreathingActive
                                ? AppColors.accentJade.withValues(alpha: 0.4)
                                : AppColors.accentJade.withValues(alpha: 0.15),
                            width: _isBreathingActive ? 2 : 1,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (ctx, child) {
                          return Transform.scale(
                            scale: _isBreathingActive ? _scaleAnimation.value : 1.0,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.accentJade.withValues(alpha: 0.35),
                                    AppColors.accentJade.withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(color: AppColors.accentJade.withValues(alpha: 0.6), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentJade.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isBreathingActive ? '$_breathingSecondsLeft' : '4',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentJade,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isBreathingActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                size: 13,
                                color: AppColors.accentJade,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isBreathingActive ? '${currentPhase.label.split(' ')[0]} (탭하여 멈춤)' : '초 (탭하여 시작)',
                                style: GoogleFonts.gowunDodum(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_completedCycles > 0) ...[
                Text(
                  '완료한 호흡 사이클: $_completedCycles회',
                  style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.accentJade, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 2. 평온의 심상화(Imagery) 뷰
  // -------------------------------------------------------------------------
  Widget _buildImageryView() {
    final currentSlot = _imagerySlots.isNotEmpty && _selectedSlotIndex < _imagerySlots.length
        ? _imagerySlots[_selectedSlotIndex]
        : _imagerySlots.first;

    return Column(
      children: [
        // 3개의 사진 슬롯 선택기
        RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '생각만 해도 평온해지는 사진',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.gowunDodum(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '터치하여 선택 / 편집',
                      style: GoogleFonts.gowunDodum(fontSize: 10.5, color: AppColors.textDim),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(3, (idx) {
                    final slot = idx < _imagerySlots.length ? _imagerySlots[idx] : ImagerySlot(id: idx + 1, title: '사진 ${idx + 1}', imageUrl: '');
                    final isSelected = _selectedSlotIndex == idx;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () {
                            if (!_isImageryRunning) {
                              setState(() => _selectedSlotIndex = idx);
                            }
                          },
                          onLongPress: () => _editImagerySlot(idx),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 76,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accentBrass.withValues(alpha: 0.12) : AppColors.bgPanel2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.accentBrass : AppColors.inkLineLight,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: AppColors.accentBrass.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    spreadRadius: 0.5,
                                  ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildImageryImage(slot.imageUrl),
                                  if (isSelected)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: const BoxDecoration(
                                          color: AppColors.accentBrass,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                                      ),
                                    ),
                                  Positioned(
                                    top: 3,
                                    right: 3,
                                    child: InkWell(
                                      onTap: () => _editImagerySlot(idx),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit, size: 11, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 심상화 메인 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inkLineLight),
          ),
          child: Column(
            children: [
              // 1. 심상화 사진 뷰 (선명하게 표시, 클릭 시 전체화면 몰입 모드 지원)
              RepaintBoundary(
                child: GestureDetector(
                  onTap: _openImageryFullScreen,
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppColors.bgPanel2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isImageryRunning
                            ? AppColors.accentBrass
                            : AppColors.inkLineLight,
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (_isImageryRunning)
                          BoxShadow(
                            color: AppColors.accentBrass.withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImageryImage(
                            currentSlot.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          // 우측 하단 전체화면 안내 버튼
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white24, width: 0.6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fullscreen, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '탭하여 전체화면',
                                    style: GoogleFonts.gowunDodum(
                                      fontSize: 10.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. 타이머 분 선택
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [1, 3, 5, 10].map((p) {
                  final isSelected = _imageryTargetMinutes == p;
                  return ChoiceChip(
                    label: Text('$p분'),
                    selected: isSelected,
                    onSelected: _isImageryRunning ? null : (_) => _selectImageryMinutes(p),
                    selectedColor: AppColors.accentBrass.withValues(alpha: 0.2),
                    backgroundColor: AppColors.bgPanel2,
                    labelStyle: GoogleFonts.gowunDodum(
                      fontSize: 11.5,
                      color: isSelected ? AppColors.accentBrass : AppColors.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 3. 이미지 아래로 내려온 시계 및 '시계를 탭하여 시작' 토글 버튼
              InkWell(
                onTap: _toggleImagery,
                borderRadius: BorderRadius.circular(12),
                splashColor: AppColors.accentBrass.withValues(alpha: 0.15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.bgPanel2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isImageryRunning
                          ? AppColors.accentBrass
                          : AppColors.inkLineLight,
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (_isImageryRunning)
                        BoxShadow(
                          color: AppColors.accentBrass.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 시계 숫자 (Tabular figures & SizedBox로 떨림 현상 원천 방지)
                      SizedBox(
                        height: 44,
                        child: Center(
                          child: Text(
                            _formatSeconds(_imagerySecondsRemaining),
                            style: GoogleFonts.gowunDodum(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: _isImageryRunning ? AppColors.accentBrass : AppColors.textPrimary,
                              letterSpacing: 2,
                            ).copyWith(
                              fontFeatures: const [ui.FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // '시계를 탭하여 시작' / '탭하여 일시정지' 토글 버튼
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isImageryRunning
                              ? AppColors.accentBrass.withValues(alpha: 0.2)
                              : AppColors.inkLineLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isImageryRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              size: 16,
                              color: _isImageryRunning ? AppColors.accentBrass : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isImageryRunning ? '탭하여 일시정지' : '시계를 탭하여 시작',
                              style: GoogleFonts.gowunDodum(
                                fontSize: 12,
                                color: _isImageryRunning ? AppColors.accentBrass : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                _isImageryRunning
                    ? '눈을 감고 상상하거나, 화면을 편안히 바라보며 그곳의 평온을 느껴보세요 🌿'
                    : '시간 선택 후 시계 영역을 탭하면 심상화가 시작됩니다.',
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
              ),

              if (_imagerySecondsRemaining < _imageryTargetMinutes * 60) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resetImagery,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: Text('타이머 초기화', style: GoogleFonts.gowunDodum(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.inkLine),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 3. 명상 타이머 뷰
  // -------------------------------------------------------------------------
  Widget _buildMeditationView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.bgPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inkLineLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '마음 챙김 명상',
                style: GoogleFonts.gowunDodum(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentBrass,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '조용히 자리에 앉아 숨이 들어오고 나가는 감각에만 주의를 기울입니다',
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunDodum(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // 시간 프리셋 칩
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [1, 3, 5, 10, 15].map((p) {
                  final isSelected = _meditationTargetMinutes == p;
                  return ChoiceChip(
                    label: Text('$p분'),
                    selected: isSelected,
                    onSelected: _isMeditationRunning ? null : (_) => _selectMeditationMinutes(p),
                    selectedColor: AppColors.accentBrass.withValues(alpha: 0.2),
                    backgroundColor: AppColors.bgPanel2,
                    labelStyle: GoogleFonts.gowunDodum(
                      fontSize: 11.5,
                      color: isSelected ? AppColors.accentBrass : AppColors.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 타이머 표시 원 (시계 클릭 시 시작/정지)
              InkWell(
                onTap: _toggleMeditation,
                borderRadius: BorderRadius.circular(85),
                splashColor: AppColors.accentBrass.withValues(alpha: 0.2),
                highlightColor: Colors.transparent,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgPanel2,
                    border: Border.all(
                      color: _isMeditationRunning
                          ? AppColors.accentBrass
                          : AppColors.accentBrass.withValues(alpha: 0.3),
                      width: _isMeditationRunning ? 2.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBrass.withValues(alpha: _isMeditationRunning ? 0.18 : 0.08),
                        blurRadius: 20,
                        spreadRadius: _isMeditationRunning ? 4 : 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatSeconds(_meditationSecondsRemaining),
                        style: GoogleFonts.gowunDodum(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBrass,
                          letterSpacing: 2,
                        ).copyWith(
                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isMeditationRunning ? Icons.pause_circle_outline : Icons.play_circle_outline,
                            size: 13,
                            color: AppColors.accentBrass,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isMeditationRunning ? '탭하여 정지' : '탭하여 시작',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentBrass,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _isMeditationRunning
                    ? '숨이 들어오고 나가는 호흡의 감각에 편안하게 머뭅니다'
                    : '시간 선택 후 중앙의 원(시계)을 탭하여 명상을 시작하세요',
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.textMuted),
              ),

              if (_meditationSecondsRemaining < _meditationTargetMinutes * 60) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resetMeditation,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: Text('타이머 초기화', style: GoogleFonts.gowunDodum(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.inkLine),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. 평온의 심상화 전체화면 몰입 뷰어 (스와이프 탐색, 줌, 미니멀 플로팅 타이머)
// ---------------------------------------------------------------------------
class _ImageryFullScreenViewer extends StatefulWidget {
  final List<ImagerySlot> slots;
  final int initialIndex;
  final ValueNotifier<int> secondsNotifier;
  final ValueNotifier<bool> runningNotifier;
  final VoidCallback onTogglePlay;
  final VoidCallback onReset;
  final ValueChanged<int> onIndexChanged;
  final Widget Function(String url) buildImageWidget;

  const _ImageryFullScreenViewer({
    required this.slots,
    required this.initialIndex,
    required this.secondsNotifier,
    required this.runningNotifier,
    required this.onTogglePlay,
    required this.onReset,
    required this.onIndexChanged,
    required this.buildImageWidget,
  });

  @override
  State<_ImageryFullScreenViewer> createState() => _ImageryFullScreenViewerState();
}

class _ImageryFullScreenViewerState extends State<_ImageryFullScreenViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatSeconds(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 좌우 스와이프 가능한 전체화면 이미지 PageView
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.slots.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                widget.onIndexChanged(index);
              },
              itemBuilder: (context, index) {
                final slot = widget.slots[index];
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: widget.buildImageWidget(slot.imageUrl),
                  ),
                );
              },
            ),
          ),

          // 2. 상단 플로팅 컨트롤 (타이머 & 닫기 버튼)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showControls ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 미니멀 플로팅 타이머 위젯
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24, width: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.runningNotifier,
                            builder: (context, isRunning, _) {
                              return ValueListenableBuilder<int>(
                                valueListenable: widget.secondsNotifier,
                                builder: (context, secondsRemaining, _) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: widget.onTogglePlay,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: Icon(
                                            isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                            size: 20,
                                            color: AppColors.accentBrass,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatSeconds(secondsRemaining),
                                        style: GoogleFonts.gowunDodum(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isRunning ? AppColors.accentBrass : Colors.white,
                                          letterSpacing: 1.2,
                                        ).copyWith(
                                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: widget.onReset,
                                        borderRadius: BorderRadius.circular(16),
                                        child: const Padding(
                                          padding: EdgeInsets.all(2),
                                          child: Icon(
                                            Icons.refresh,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // 닫기 (X) 버튼
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            tooltip: '전체화면 닫기',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. 하단 페이지 인디케이터 및 안내
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showControls ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 인디케이터 점 3개
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.slots.length, (idx) {
                            final isSelected = idx == _currentIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isSelected ? 22 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.accentBrass : Colors.white38,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '좌우로 밀어 사진 넘김 · 두 손가락으로 확대 · 화면 탭시 UI 숨김',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


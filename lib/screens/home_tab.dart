import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../models/quote.dart';
import '../models/weather_data.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

import 'package:flutter/services.dart';

import 'diary_tab.dart';
import '../widgets/header_date_time.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onDiarySaved;
  final bool hideHeader;

  const HomeTab({super.key, this.onDiarySaved, this.hideHeader = false});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

enum _ActiveSection { none, originalAndReading, english, translation }

class _HomeTabState extends State<HomeTab>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Quote? _quote;
  WeatherData _weather = WeatherData.defaultWeather();

  // 타이핑 애니메이션 상태
  List<String> _origSegments = [];
  List<String> _readSegments = [];
  List<String> _displayedOrigSegments = [];
  List<String> _displayedReadSegments = [];
  int _activeSegmentIndex = -1;
  bool _isTypingReadingInSegment = false;

  String _english = '';
  String _translation = '';
  String _sourceLine = '';
  bool _commentaryIn = false;
  _ActiveSection _activeSection = _ActiveSection.none;
  Timer? _weatherTimer;
  String? _initError;
  TimeOfDay _notifyTime = const TimeOfDay(hour: 9, minute: 0);
  int _animationGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 15분마다 기상청 실시간 날씨 자동 갱신
    _weatherTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _refreshWeatherSilently();
    });
    _init();
  }

  @override
  void dispose() {
    _animationGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _weatherTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshWeatherSilently();
    }
  }

  Future<void> _init() async {
    try {
      final quotes = await QuoteRepository.loadQuotes();
      final prefs = await SharedPreferences.getInstance();
      final deviceSeed = await QuoteRepository.getOrCreateDeviceSeed(prefs);
      final notifyTime = await StorageService.loadNotificationTime();
      final isDailyEnabled = await StorageService.isDailyNotificationEnabled();

      final initialQuote = QuoteRepository.getDailyQuote(
        quotes,
        DateTime.now(),
        deviceSeed,
      );

      if (isDailyEnabled) {
        try {
          await NotificationService.scheduleDailyNotification(
            notifyTime,
            previewText: 'audistine 오늘의 명언을 확인해 보세요.',
          );
        } catch (e) {
          debugPrint('알림 예약 에러: $e');
        }
      }

      // 1. 캐시된 날씨 즉시(0초) 표시
      final fastWeather = await WeatherService.getFastWeather();

      if (!mounted) return;
      setState(() {
        _quote = initialQuote;
        _notifyTime = notifyTime;
        _weather = fastWeather;
      });

      // 2. 최신 날씨는 백그라운드에서 조용히 갱신 (명언 타이핑에 방해되지 않음)
      _refreshWeatherSilently();
      await _playSequence(initialQuote);
    } catch (e, stack) {
      if (!mounted) return;
      debugPrint('HomeTab 초기화 실패: $e\n$stack');
      setState(() => _initError = e.toString());
    }
  }

  Future<void> _refreshWeatherSilently() async {
    final fresh = await WeatherService.fetchFreshWeather(force: true);
    if (!mounted) return;
    setState(() => _weather = fresh);
  }

  Future<void> _loadWeather() async {
    final data = await WeatherService.fetchFreshWeather(force: true);
    if (!mounted) return;
    setState(() {
      _weather = data;
    });
  }

  Future<void> _playSequence(Quote q) async {
    final currentGen = ++_animationGeneration;
    if (!mounted) return;

    final origParts = q.original.split(' ').where((s) => s.isNotEmpty).toList();
    final readParts = q.reading.split(' ').where((s) => s.isNotEmpty).toList();

    if (!mounted || currentGen != _animationGeneration) return;
    setState(() {
      _origSegments = origParts;
      _readSegments = readParts;
      _displayedOrigSegments = List.filled(origParts.length, '');
      _displayedReadSegments = List.filled(readParts.length, '');
      _activeSegmentIndex = -1;
      _isTypingReadingInSegment = false;
      _english = '';
      _translation = '';
      _sourceLine = '';
      _commentaryIn = false;
      _activeSection = origParts.isNotEmpty
          ? _ActiveSection.originalAndReading
          : _ActiveSection.none;
    });

    if (origParts.isNotEmpty) {
      for (int i = 0; i < origParts.length; i++) {
        if (!mounted || currentGen != _animationGeneration) return;
        setState(() {
          _activeSegmentIndex = i;
          _isTypingReadingInSegment = false;
        });

        await _type(
          origParts[i],
          (v) {
            if (mounted && currentGen == _animationGeneration) {
              setState(() => _displayedOrigSegments[i] = v);
            }
          },
          const Duration(milliseconds: 60),
          currentGen,
        );

        if (!mounted || currentGen != _animationGeneration) return;
        await Future.delayed(const Duration(milliseconds: 120));

        if (!mounted || currentGen != _animationGeneration) return;
        if (i < readParts.length) {
          setState(() => _isTypingReadingInSegment = true);
          await _type(
            readParts[i],
            (v) {
              if (mounted && currentGen == _animationGeneration) {
                setState(() => _displayedReadSegments[i] = v);
              }
            },
            const Duration(milliseconds: 30),
            currentGen,
          );
        }
        if (!mounted || currentGen != _animationGeneration) return;
        await Future.delayed(const Duration(milliseconds: 160));
      }

      if (!mounted || currentGen != _animationGeneration) return;
      setState(() => _activeSegmentIndex = -1);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted || currentGen != _animationGeneration) return;
    if (q.english.isNotEmpty) {
      setState(() => _activeSection = _ActiveSection.english);
      await _type(
        q.english,
        (v) {
          if (mounted && currentGen == _animationGeneration) {
            setState(() => _english = v);
          }
        },
        const Duration(milliseconds: 16),
        currentGen,
      );
      if (!mounted || currentGen != _animationGeneration) return;
      await Future.delayed(const Duration(milliseconds: 240));
    }

    if (!mounted || currentGen != _animationGeneration) return;
    setState(() => _activeSection = _ActiveSection.translation);
    await _type(
      q.translation,
      (v) {
        if (mounted && currentGen == _animationGeneration) {
          setState(() => _translation = v);
        }
      },
      const Duration(milliseconds: 24),
      currentGen,
    );
    if (!mounted || currentGen != _animationGeneration) return;
    setState(() => _activeSection = _ActiveSection.none);
    await Future.delayed(const Duration(milliseconds: 240));

    if (!mounted || currentGen != _animationGeneration) return;
    setState(() => _sourceLine = q.source);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || currentGen != _animationGeneration) return;

    setState(() => _commentaryIn = true);
  }

  Future<void> _type(
    String text,
    void Function(String) onUpdate,
    Duration perChar,
    int generation,
  ) async {
    for (int i = 1; i <= text.length; i++) {
      if (!mounted || generation != _animationGeneration) return;
      onUpdate(text.substring(0, i));
      await Future.delayed(perChar);
    }
  }

  Future<void> _shareQuote(Quote quote) async {
    final buffer = StringBuffer()
      ..writeln('audistine? — 오늘의 한 문장')
      ..writeln();
    if (quote.original.isNotEmpty) {
      buffer.writeln(quote.original);
    }
    if (quote.reading.isNotEmpty) {
      buffer.writeln(quote.reading);
    }
    if (quote.original.isNotEmpty || quote.reading.isNotEmpty) {
      buffer.writeln();
    }
    if (quote.english.isNotEmpty) {
      buffer.writeln(quote.english);
      buffer.writeln();
    }
    buffer.writeln(quote.translation);
    buffer.writeln();
    buffer.writeln('— ${quote.source}');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '오늘의 명언이 복사되었습니다. 소중한 분들에게 전해보세요 🌿',
                  style: GoogleFonts.gowunDodum(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accentJade,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareSiteLink() async {
    await Clipboard.setData(
      const ClipboardData(text: 'https://audistine.web.app'),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.link, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '사이트 링크(https://audistine.web.app)가 복사되었습니다 🌿',
                  style: GoogleFonts.gowunDodum(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accentJade,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openQuoteMemoSheet(Quote quote) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => WriteDiarySheet(
        initialType: DiaryType.free,
        initialQuote: quote,
        onSaved: () {
          widget.onDiarySaved?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '명언 메모가 감정 일기에 저장되었습니다 🌿',
                style: GoogleFonts.gowunDodum(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              backgroundColor: AppColors.accentJade,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNotificationTimePicker() async {
    final permissionGranted =
        await NotificationService.requestNotificationPermission();
    if (!permissionGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('명언 알림을 사용하려면 브라우저 알림 권한을 허용해 주세요.')),
        );
      }
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _notifyTime,
      helpText: '오늘의 명언 알림 시각 설정',
    );
    if (picked != null) {
      setState(() => _notifyTime = picked);
      await StorageService.saveNotificationTime(picked);
      final serverPushReady =
          await NotificationService.scheduleDailyNotification(
            picked,
            previewText: 'audistine 오늘의 명언을 확인해 보세요.',
            forceEnable: true,
          );
      if (mounted) {
        final period = picked.hour < 12 ? '오전' : '오후';
        final displayHour = picked.hour == 0
            ? 12
            : (picked.hour > 12 ? picked.hour - 12 : picked.hour);
        final minStr = picked.minute.toString().padLeft(2, '0');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              serverPushReady
                  ? '매일 $period $displayHour:$minStr에 명언 알림이 설정되었습니다.'
                  : '매일 $period $displayHour:$minStr 시각은 저장됐지만 서버 푸시는 아직 연결되지 않았습니다.',
              style: GoogleFonts.gowunDodum(
                fontSize: 12.5,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.accentNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final quote = _quote;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isDesktop = screenWidth >= 768;
            final isNarrow = screenWidth < 380; // Z Flip 등 세로로 길고 가로가 좁은 기기 감지

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : (isNarrow ? 12 : 20),
                vertical: isDesktop ? 20 : (isNarrow ? 10 : 14),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 860 : 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.hideHeader) ...[
                        _buildHeader(isNarrow: isNarrow),
                        SizedBox(height: isNarrow ? 8 : 12),
                      ],
                      if (_initError != null)
                        Expanded(child: Center(child: _buildErrorCard()))
                      else if (quote == null)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentBrass,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: _buildQuoteCard(quote, isNarrow: isNarrow),
                        ),
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

  /// 상단 정보 바 (좌측: 날짜/시각/알림/안내, 우측: 장소/어제/오늘 3줄 날씨)
  /// 상단 정보 바 (1줄: 제목, 2줄: 안내/공유 우측정렬, 3줄: 설명문, 4줄: 일시 & 날씨)
  /// 상단 정보 바 (1줄: 제목 가운데, 2줄: 설명문 가운데, 3줄: 안내/공유 우측, 4줄: 일시 한줄 왼쪽, 5줄: 날씨 한줄)
  Widget _buildHeader({bool isNarrow = false}) {
    return Container(
      padding: EdgeInsets.only(bottom: isNarrow ? 10 : 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inkLine, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1줄: audistine? 제목 (가운데 정렬)
          _buildBrandLogo(baseSize: isNarrow ? 26 : 30),
          const SizedBox(height: 4),

          // 2줄: '그대는 들어보았는가?' 설명문 (제목 아래에 가운데 정렬)
          Center(
            child: Text(
              '그대는 들어보았는가?',
              style: GoogleFonts.gowunDodum(
                fontSize: isNarrow ? 12 : 13.5,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 3줄: 안내(물음표만), 공유(공유표시만) 버튼 (우측 정렬)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 이용 안내 버튼 (물음표만, 조금 작게)
              InkWell(
                onTap: _showAppGuideDialog,
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  padding: const EdgeInsets.all(4.5),
                  decoration: BoxDecoration(
                    color: AppColors.bgPanel2,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.inkLine),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    size: 14,
                    color: AppColors.accentJade,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 사이트 공유 버튼 (공유표시만)
              InkWell(
                onTap: _shareSiteLink,
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  padding: const EdgeInsets.all(4.5),
                  decoration: BoxDecoration(
                    color: AppColors.bgPanel2,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.inkLine),
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    size: 14,
                    color: AppColors.accentBrass,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4줄: 날짜와 시각 (가운데 정렬)
          HeaderDateTime(isNarrow: isNarrow),
          const SizedBox(height: 8),

          // 5줄: 그 아래줄에 한줄로 날씨표기 (가운데 정렬)
          Center(child: _buildSingleLineWeather(isNarrow: isNarrow)),
        ],
      ),
    );
  }

  /// 한줄 날씨 표기 위젯
  Widget _buildSingleLineWeather({bool isNarrow = false}) {
    final yesterday = _weather.yesterday ?? YesterdayWeather.defaultYesterday();
    final yMax = '${yesterday.maxTemp.round()}°';
    final yMin = '${yesterday.minTemp.round()}°';
    final tMax = '${_weather.maxTemp.round()}°';
    final tMin = '${_weather.minTemp.round()}°';

    return InkWell(
      onTap: _showCityPicker,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          color: AppColors.bgPanel2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.inkLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 13,
              color: AppColors.accentBrass,
            ),
            const SizedBox(width: 4),
            Text(
              _weather.locationName,
              style: GoogleFonts.gowunDodum(
                fontSize: isNarrow ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: AppColors.accentBrass,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '어제 $yMin/$yMax (${yesterday.description})',
              style: GoogleFonts.gowunDodum(
                fontSize: isNarrow ? 10.5 : 11.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '오늘 $tMin/$tMax (${_weather.description})',
              style: GoogleFonts.gowunDodum(
                fontSize: isNarrow ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 브랜드 로고 (문학 서정 이탤릭: Cormorant Garamond Italic 고정)
  Widget _buildBrandLogo({double baseSize = 25, bool isCenter = true}) {
    final textWidget = RichText(
      textAlign: isCenter ? TextAlign.center : TextAlign.left,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'audistine',
            style:
                GoogleFonts.cormorantGaramond(
                  fontSize: baseSize + 3,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.accentVermilion,
                ).copyWith(
                  fontFamilyFallback: const [
                    'Cormorant Garamond',
                    'EB Garamond',
                    'Garamond',
                    'Georgia',
                    'Baskerville',
                    'serif',
                  ],
                ),
          ),
          TextSpan(
            text: '?',
            style:
                GoogleFonts.cormorantGaramond(
                  fontSize: baseSize + 3,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentBrass,
                ).copyWith(
                  fontFamilyFallback: const [
                    'Cormorant Garamond',
                    'EB Garamond',
                    'Garamond',
                    'Georgia',
                    'Baskerville',
                    'serif',
                  ],
                ),
          ),
        ],
      ),
    );

    return isCenter
        ? Center(child: textWidget)
        : Align(alignment: Alignment.centerLeft, child: textWidget);
  }

  /// 날씨 지역(도시) 선택 및 어제/오늘 비교 모달
  void _showCityPicker() {
    final yesterday = _weather.yesterday ?? YesterdayWeather.defaultYesterday();
    final diff = _weather.tempDiffFromYesterday;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.inkLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.wb_sunny_outlined,
                          size: 18,
                          color: AppColors.accentBrass,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_weather.locationName} 날씨 비교',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _loadWeather();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.refresh,
                        size: 14,
                        color: AppColors.accentBrass,
                      ),
                      label: Text(
                        '새로고침',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 12,
                          color: AppColors.accentBrass,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 어제 vs 오늘 상세 비교 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgPanel,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.inkLine),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // 어제 요약 (좌측)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: AppColors.bgPanel2,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.inkLine),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '어제 날씨',
                                        style: GoogleFonts.gowunDodum(
                                          fontSize: 11.5,
                                          color: AppColors.textDim,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        yesterday.icon,
                                        size: 14,
                                        color: AppColors.textDim,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${yesterday.tempAtSameHour.toStringAsFixed(1)}°C',
                                    style: GoogleFonts.gowunDodum(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${yesterday.description} · ${yesterday.minTemp.round()}°/${yesterday.maxTemp.round()}°',
                                    style: GoogleFonts.gowunDodum(
                                      fontSize: 10.5,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 오늘 요약 (우측)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: AppColors.accentBrass.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.accentBrass.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '오늘 실시간',
                                        style: GoogleFonts.gowunDodum(
                                          fontSize: 11.5,
                                          color: AppColors.accentBrass,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        _weather.icon,
                                        size: 14,
                                        color: AppColors.accentBrass,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_weather.currentTemp.toStringAsFixed(1)}°C',
                                    style: GoogleFonts.gowunDodum(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_weather.description} · ${_weather.minTemp.round()}°/${_weather.maxTemp.round()}°',
                                    style: GoogleFonts.gowunDodum(
                                      fontSize: 10.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (diff != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgPanel2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                diff > 0
                                    ? Icons.trending_up
                                    : (diff < 0
                                          ? Icons.trending_down
                                          : Icons.compare_arrows),
                                size: 13,
                                color: diff > 0
                                    ? AppColors.accentVermilion
                                    : (diff < 0
                                          ? AppColors.accentJade
                                          : AppColors.textDim),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '어제 같은 시간 대비 ${_weather.tempDiffDescription}',
                                style: GoogleFonts.gowunDodum(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: diff > 0
                                      ? AppColors.accentVermilion
                                      : (diff < 0
                                            ? AppColors.accentJade
                                            : AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  '📍 지역 선택',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: CityLocation.majorCities.map((city) {
                    final isSelected = _weather.locationName == city.name;
                    return ChoiceChip(
                      label: Text(city.name),
                      selected: isSelected,
                      selectedColor: AppColors.accentBrass.withValues(
                        alpha: 0.2,
                      ),
                      backgroundColor: AppColors.bgPanel2,
                      showCheckmark: false,
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.accentBrass
                              : AppColors.inkLine,
                          width: isSelected ? 1.0 : 0.8,
                        ),
                      ),
                      labelStyle: GoogleFonts.gowunDodum(
                        fontSize: 11.5,
                        color: isSelected
                            ? AppColors.accentBrass
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) async {
                        Navigator.pop(ctx);
                        await WeatherService.setSelectedCity(city.name);
                        _loadWeather();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 효율적인 앱 이용 안내 (하루 동반 루틴) 다이얼로그
  void _showAppGuideDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        bottom: true,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accentBrass.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_stories_outlined,
                            color: AppColors.accentBrass,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'audistine? 하루 동반 이용 가이드',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgPanel2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.inkLine),
                ),
                child: Text(
                  '아침부터 밤까지, 마음을 챙기고 다독이는 자기관리 앱입니다.',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    _buildGuideStepCard(
                      timeEmoji: '🌅',
                      timeTitle: '1. 아침 (오늘 탭)',
                      stepContent: [
                        '상단에서 오늘의 최고/최저 기온과 날씨 정보를 확인합니다.',
                        '매일 새롭게 전해지는 오늘의 한시와 지혜로운 명언을 깊이 음미합니다.',
                        '마음에 깊은 울림을 준 문장에 대한 느낌을 [메모]할 수 있습니다.',
                      ],
                      accentColor: AppColors.accentBrass,
                    ),
                    const SizedBox(height: 12),
                    _buildGuideStepCard(
                      timeEmoji: '☀️',
                      timeTitle: '2. 낮 / 일상 (감정 일기 탭)',
                      stepContent: [
                        '마음이 불안하거나 흔들릴 때 5단계 인지 기록지를 작성합니다.',
                        '생각을 적으면 인지오류 질문이 표기될 수도 있습니다.',
                        '[신념 탐색 & 대처]에서 나를 옭아매는 규칙을 유연하게 바꿀 수 있습니다.',
                      ],
                      accentColor: AppColors.accentJade,
                    ),
                    const SizedBox(height: 12),
                    _buildGuideStepCard(
                      timeEmoji: '🌙',
                      timeTitle: '3. 밤 / 취침 전 (다음 일정 & 마음 쉼터 탭)',
                      stepContent: [
                        '[다음 일정]에 챙겨야 할 일을 적고, 필요한 경우 \'일정 5분 전 알람(one-beep)\'을 설정하여 머릿속 걱정을 비워냅니다(Brain Dump).',
                        '[마음 쉼터] 4-4-4-4 복식호흡으로 긴장된 몸과 신경계를 이완합니다.',
                        '[평온의 심상화] 평온한 풍경을 떠올리며 마음의 평안을 얻을 수 있습니다.',
                        '[명상 타이머] 설정한 시간 동안 호흡과 감각에 집중하는 훈련을 합니다.',
                      ],
                      accentColor: AppColors.accentNavy,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideStepCard({
    required String timeEmoji,
    required String timeTitle,
    required List<String> stepContent,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inkLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(timeEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  timeTitle,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...stepContent.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(Quote quote, {bool isNarrow = false}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 18 : 24,
        isNarrow ? 18 : 22,
        isNarrow ? 18 : 24,
        isNarrow ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        border: Border.all(color: AppColors.inkLine),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 고정 헤더: audistine? (문학 서정 이탤릭, 명언 바로 위 좌측 정렬)
          _buildBrandLogo(baseSize: isNarrow ? 23 : 25, isCenter: false),
          SizedBox(height: isNarrow ? 10 : 14),

          // 중앙 스크롤 본문 영역
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (quote.original.isNotEmpty) ...[
                    _buildOriginalAndReadingPairs(isNarrow: isNarrow),
                    SizedBox(height: isNarrow ? 12 : 16),
                  ],
                  if (quote.english.isNotEmpty) ...[
                    _buildTypedText(
                      _english,
                      style: GoogleFonts.gowunDodum(
                        fontSize: isNarrow ? 14 : 15,
                        fontStyle: FontStyle.italic,
                        color: AppColors.accentVermilion,
                        height: 1.45,
                      ),
                      showCursor: _activeSection == _ActiveSection.english,
                    ),
                    SizedBox(height: isNarrow ? 12 : 16),
                  ],
                  _buildTypedText(
                    _translation,
                    style: GoogleFonts.gowunDodum(
                      fontSize: isNarrow ? 14.5 : 15.5,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accentNavy,
                    ),
                    showCursor: _activeSection == _ActiveSection.translation,
                  ),
                  SizedBox(height: isNarrow ? 14 : 18),
                  Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentBrass, Colors.transparent],
                      ),
                    ),
                  ),
                  SizedBox(height: isNarrow ? 12 : 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '출처',
                        style: GoogleFonts.gowunDodum(
                          fontSize: isNarrow ? 10.5 : 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentBrass,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _sourceLine,
                          style: GoogleFonts.gowunDodum(
                            fontSize: isNarrow ? 12 : 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isNarrow ? 12 : 16),
                  _buildCommentary(quote.commentary, isNarrow: isNarrow),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 하단 고정 액션 버튼 (메모 / 공유)
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.inkLine, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 이 문장으로 메모 쓰기 (홈 탭 위에서 바로 모달 오픈)
                InkWell(
                  onTap: () => _openQuoteMemoSheet(quote),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_note,
                          size: 16,
                          color: AppColors.accentJade,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '나의 메모',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 12,
                            color: AppColors.accentJade,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 공유
                InkWell(
                  onTap: () => _shareQuote(quote),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.share_outlined,
                          size: 15,
                          color: AppColors.accentBrass,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '명언 공유',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 12,
                            color: AppColors.accentBrass,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 명언 알림 (시각 변경창 직접 호출)
                InkWell(
                  onTap: _openNotificationTimePicker,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          size: 15,
                          color: AppColors.accentBrass,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '명언 알림',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 12,
                            color: AppColors.accentBrass,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalAndReadingPairs({bool isNarrow = false}) {
    final maxSegments = _origSegments.length > _readSegments.length
        ? _origSegments.length
        : _readSegments.length;

    return Wrap(
      spacing: isNarrow ? 8 : 14,
      runSpacing: isNarrow ? 8 : 12,
      children: List.generate(maxSegments, (segmentIdx) {
        final origStr = _displayedOrigSegments.length > segmentIdx
            ? _displayedOrigSegments[segmentIdx]
            : '';
        final readStr = _displayedReadSegments.length > segmentIdx
            ? _displayedReadSegments[segmentIdx]
            : '';

        final isCurrentSegment =
            _activeSection == _ActiveSection.originalAndReading &&
            _activeSegmentIndex == segmentIdx;
        final maxLen = origStr.length > readStr.length
            ? origStr.length
            : readStr.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxLen, (charIdx) {
            final origChar = charIdx < origStr.length ? origStr[charIdx] : '';
            final readChar = charIdx < readStr.length ? readStr[charIdx] : '';

            final showOrigCursor =
                isCurrentSegment &&
                !_isTypingReadingInSegment &&
                charIdx == origStr.length - 1;
            final showReadCursor =
                isCurrentSegment &&
                _isTypingReadingInSegment &&
                charIdx == readStr.length - 1;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTypedText(
                    readChar,
                    style: GoogleFonts.gowunDodum(
                      fontSize: isNarrow ? 9.5 : 10,
                      color: AppColors.textMuted,
                      height: 1.1,
                    ),
                    showCursor: showReadCursor,
                  ),
                  const SizedBox(height: 3),
                  _buildTypedText(
                    origChar,
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontWeight: FontWeight.w400,
                      fontSize: isNarrow ? 15.5 : 17,
                      color: AppColors.accentJade,
                      height: 1.1,
                      fontFamilyFallback: const [
                        'NotoSerifKR',
                        'Noto Serif KR',
                        'Malgun Gothic',
                        'Apple SD Gothic Neo',
                        'Microsoft YaHei',
                        'SimSun',
                        'Batang',
                        'serif',
                      ],
                    ),
                    showCursor: showOrigCursor,
                  ),
                ],
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildTypedText(
    String text, {
    required TextStyle style,
    required bool showCursor,
  }) {
    return RichText(
      softWrap: true,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text),
          if (showCursor)
            TextSpan(
              text: '▏',
              style: style.copyWith(color: AppColors.accentBrass),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentary(String text, {bool isNarrow = false}) {
    return ClipRect(
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        offset: _commentaryIn ? Offset.zero : const Offset(0.15, 0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 900),
          opacity: _commentaryIn ? 1 : 0,
          child: Text(
            text,
            style: GoogleFonts.gowunDodum(
              fontSize: isNarrow ? 12.5 : 13,
              height: isNarrow ? 1.7 : 1.8,
              color: AppColors.accentNavy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentVermilion),
      ),
      child: Text(
        '초기화 중 오류가 발생했습니다:\n$_initError',
        style: GoogleFonts.gowunDodum(
          fontSize: 13,
          color: AppColors.accentVermilion,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/quote.dart';
import 'home_tab.dart';
import 'diary_tab.dart';
import 'mind_test_tab.dart';
import 'planner_tab.dart';
import 'rest_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;
  int _diaryRefreshKey = 0;
  int _restRefreshKey = 0;
  Quote? _pendingQuoteForDiary;
  RestMode? _pendingRestMode;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        _diaryRefreshKey++;
      }
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        _diaryRefreshKey++; // 감정 일기 탭 선택 시 항상 최신 일기/메모 목록 갱신
      }
    });
  }

  void _navigateToDiaryWithQuote(Quote quote) {
    setState(() {
      _pendingQuoteForDiary = quote;
      _currentIndex = 1;
      _diaryRefreshKey++;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToDiary() {
    setState(() {
      _currentIndex = 1;
      _diaryRefreshKey++;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToRestWithMode(RestMode mode) {
    setState(() {
      _pendingRestMode = mode;
      _currentIndex = 4;
      _restRefreshKey++;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        4,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onDiarySaved() {
    setState(() {
      _diaryRefreshKey++;
    });
  }

  void _clearPendingQuote() {
    setState(() {
      _pendingQuoteForDiary = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTab(onDiarySaved: _onDiarySaved),
      DiaryTab(
        pendingQuoteForDiary: _pendingQuoteForDiary,
        onClearedPendingQuote: _clearPendingQuote,
        refreshKey: _diaryRefreshKey,
      ),
      MindTestTab(
        onNavigateToRest: _navigateToRestWithMode,
        onNavigateToDiaryWithQuote: _navigateToDiaryWithQuote,
        onNavigateToDiary: _navigateToDiary,
      ),
      const PlannerTab(),
      RestTab(
        initialMode: _pendingRestMode,
        refreshKey: _restRefreshKey,
        isActive: _currentIndex == 4,
      ),
    ];

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;

            if (isDesktop) {
              return Scaffold(
                backgroundColor: AppColors.bgDeep,
                body: Row(
                  children: [
                    // PC용 좌측 고정 사이드바
                    _buildDesktopSidebar(),
                    // 세로 구분선
                    Container(width: 1, color: AppColors.inkLine),
                    // 메인 본문 영역 (데스크톱은 고정 뷰 인덱스 스택)
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: screens,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 모바일용 좌우 스와이프 제스처 전환(PageView) 및 하단 탭바 레이아웃
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
              child: Scaffold(
                body: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  children: screens,
                ),
                bottomNavigationBar: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgDeep,
                    border: Border(
                      top: BorderSide(color: AppColors.inkLine, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            0,
                            Icons.wb_sunny_outlined,
                            Icons.wb_sunny,
                            '오늘',
                          ),
                          _buildNavItem(
                            1,
                            Icons.edit_note_outlined,
                            Icons.edit_note,
                            '감정 일기',
                          ),
                          _buildNavItem(
                            2,
                            Icons.psychology_outlined,
                            Icons.psychology,
                            '마음 검사',
                          ),
                          _buildNavItem(
                            3,
                            Icons.event_note_outlined,
                            Icons.event_note,
                            '다음 일정',
                          ),
                          _buildNavItem(
                            4,
                            Icons.spa_outlined,
                            Icons.spa,
                            '마음 쉼터',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// PC용 좌측 사이드바 위젯
  Widget _buildDesktopSidebar() {
    final navItems = [
      (0, Icons.wb_sunny_outlined, Icons.wb_sunny, '오늘', '오늘의 명언 & 날씨'),
      (1, Icons.edit_note_outlined, Icons.edit_note, '감정 일기', '5단계 인지 기록 & 메모'),
      (
        2,
        Icons.psychology_outlined,
        Icons.psychology,
        '마음 검사',
        '감정 팔레트 & 기분 프로파일',
      ),
      (
        3,
        Icons.event_note_outlined,
        Icons.event_note,
        '다음 일정',
        '일정 알람 & 생각 비우기',
      ),
      (4, Icons.spa_outlined, Icons.spa, '마음 쉼터', '호흡·심상화·명상 타이머'),
    ];

    return Container(
      width: 220,
      color: AppColors.bgPanel,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 브랜드 로고 (문학 서정 이탤릭)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'audistine',
                    style:
                        GoogleFonts.cormorantGaramond(
                          fontSize: 27,
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
                          fontSize: 27,
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
            ),
          ),
          const SizedBox(height: 20),

          // 네비게이션 메뉴 목록
          Expanded(
            child: ListView(
              children: navItems.map((item) {
                final (idx, icon, activeIcon, title, subtitle) = item;
                final isSelected = _currentIndex == idx;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: isSelected
                        ? AppColors.accentBrass.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _onTabSelected(idx),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentBrass.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? activeIcon : icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.accentBrass
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.gowunDodum(
                                      fontSize: 13.5,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.accentBrass
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    subtitle,
                                    style: GoogleFonts.gowunDodum(
                                      fontSize: 10,
                                      color: isSelected
                                          ? AppColors.textMuted
                                          : AppColors.textDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 하단 힐링 문구 배지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgPanel2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inkLine),
            ),
            child: Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '오늘 하루도\n평온이 깃들기를',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.3,
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

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.accentBrass : AppColors.textDim;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? activeIcon : icon, size: 22, color: color),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

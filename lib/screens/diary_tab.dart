import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../models/diary_entry.dart';
import '../models/cognitive_distortion.dart';
import '../models/quote.dart';
import '../services/storage_service.dart';
import 'belief_explorer_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/header_date_time.dart';

class DiaryTab extends StatefulWidget {
  final Quote? pendingQuoteForDiary;
  final VoidCallback? onClearedPendingQuote;
  final int refreshKey;
  final VoidCallback? onQrPressed;

  const DiaryTab({
    super.key,
    this.pendingQuoteForDiary,
    this.onClearedPendingQuote,
    this.refreshKey = 0,
    this.onQrPressed,
  });

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<DiaryEntry> _diaries = [];
  bool _isLoading = true;

  // PC 데스크톱 2분할 상태 변수
  bool _isLeftPanelCollapsed = false;
  final double _leftPanelWidth = 350.0;
  DiaryEntry? _selectedEntry;
  bool _isWritingNew = true;
  Quote? _desktopPendingQuote;
  String _filterType = 'all'; // 'all', 'cbt', 'free'

  // 상담자 QR 전송용 사용자 선택 ID 셋 (최대 5건)
  final Set<String> _selectedForQrIds = {};

  void _toggleQrSelection(String id) {
    setState(() {
      if (_selectedForQrIds.contains(id)) {
        _selectedForQrIds.remove(id);
      } else {
        if (_selectedForQrIds.length >= 5) {
          _showInfoToast('QR 코드는 최대 5건까지 선택 가능합니다.');
          return;
        }
        _selectedForQrIds.add(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDiaries();
    if (widget.pendingQuoteForDiary != null) {
      _desktopPendingQuote = widget.pendingQuoteForDiary;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final isDesktop = MediaQuery.of(context).size.width >= 768;
        if (!isDesktop) {
          _openWriteModal(
            initialType: DiaryType.free,
            initialQuote: widget.pendingQuoteForDiary,
          );
        }
        widget.onClearedPendingQuote?.call();
      });
    }
  }

  @override
  void didUpdateWidget(covariant DiaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshKey != oldWidget.refreshKey) {
      _loadDiaries();
    }
    if (widget.pendingQuoteForDiary != null &&
        widget.pendingQuoteForDiary != oldWidget.pendingQuoteForDiary) {
      _desktopPendingQuote = widget.pendingQuoteForDiary;
      _isWritingNew = true;
      _selectedEntry = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final isDesktop = MediaQuery.of(context).size.width >= 768;
        if (!isDesktop) {
          _openWriteModal(
            initialType: DiaryType.free,
            initialQuote: widget.pendingQuoteForDiary,
          );
        }
        widget.onClearedPendingQuote?.call();
      });
    }
  }

  Future<void> _loadDiaries() async {
    setState(() => _isLoading = true);
    final list = await StorageService.loadDiaries();
    if (!mounted) return;
    setState(() {
      _diaries = list;
      _isLoading = false;
      if (_selectedEntry != null && !list.any((d) => d.id == _selectedEntry!.id)) {
        _selectedEntry = null;
        _isWritingNew = true;
      }
    });
  }

  Future<void> _deleteDiary(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgPanel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.inkLineLight),
        ),
        title: Text(
          '삭제 확인',
          style: GoogleFonts.gowunDodum(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '이 기록을 삭제하시겠습니까?',
          style: GoogleFonts.gowunDodum(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: GoogleFonts.gowunDodum(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentVermilion,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('삭제', style: GoogleFonts.gowunDodum(fontSize: 12.5)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _selectedForQrIds.remove(id);
      await StorageService.deleteDiary(id);
      await _loadDiaries();
    }
  }

  void _openWriteModal({DiaryType initialType = DiaryType.structuredCbt, Quote? initialQuote}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => WriteDiarySheet(
        initialType: initialType,
        initialQuote: initialQuote,
        onSaved: () {
          _loadDiaries();
        },
      ),
    );
  }

  void _openBeliefExplorer({String? initialThought, int initialTabIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BeliefExplorerSheet(
        initialThought: initialThought,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  void _openDistortionGuide({String? targetDistortionName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _DistortionGuideSheet(targetDistortionName: targetDistortionName),
    );
  }

  /// 작성 날짜와 정확한 시간(오전/오후 HH:mm) 포맷팅
  String _formatDateTime(DateTime dt) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = days[dt.weekday - 1];
    final period = dt.hour < 12 ? '오전' : '오후';
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ($weekday) $period $hour:$min';
  }

  List<DiaryEntry> _getFilteredDiaries() {
    if (_filterType == 'cbt') {
      return _diaries.where((d) => d.type == DiaryType.structuredCbt).toList();
    } else if (_filterType == 'free') {
      return _diaries.where((d) => d.type == DiaryType.free).toList();
    }
    return _diaries;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;

            if (isDesktop) {
              return _buildDesktopSplitLayout(constraints);
            }

            return _buildMobileLayout(constraints);
          },
        ),
      ),
    );
  }

  /// 모바일 단일 세로 스크롤 레이아웃
  Widget _buildMobileLayout(BoxConstraints constraints) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RefreshIndicator(
          onRefresh: _loadDiaries,
          color: AppColors.accentBrass,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: AppColors.accentBrass),
                        ),
                      )
                    else if (_diaries.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _diaries.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) => _buildDiaryCard(_diaries[i]),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// PC용 2분할(좌측 과거 목록 + 우측 실시간 작성/상세 뷰) 레이아웃
  Widget _buildDesktopSplitLayout(BoxConstraints constraints) {
    final filteredDiaries = _getFilteredDiaries();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 좌측 패널 (과거 일기 목록)
        if (!_isLeftPanelCollapsed) ...[
          SizedBox(
            width: _leftPanelWidth.clamp(280.0, 500.0),
            child: _buildDesktopSidebarList(filteredDiaries),
          ),
          // 세로 구분선 및 접기/펼치기 핸들
          _buildDesktopSplitDivider(),
        ],

        // 2. 우측 메인 영역 (작성 폼 또는 선택된 일기 상세 뷰)
        Expanded(
          child: _buildDesktopMainPane(),
        ),
      ],
    );
  }

  /// PC용 좌측 사이드바 목록
  Widget _buildDesktopSidebarList(List<DiaryEntry> filteredDiaries) {
    return Container(
      color: AppColors.bgPanel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 타이틀 바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.inkLine)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '과거 일기 목록',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgPanel2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.inkLine),
                          ),
                          child: Text(
                            '${_diaries.length}',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentBrass,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // 새 일기 작성 버튼
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedEntry = null;
                              _isWritingNew = true;
                              _desktopPendingQuote = null;
                            });
                          },
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(
                            '새 일기',
                            style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isWritingNew ? AppColors.accentBrass : AppColors.bgPanel2,
                            foregroundColor: _isWritingNew ? Colors.white : AppColors.textPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(
                                color: _isWritingNew ? AppColors.accentBrass : AppColors.inkLine,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 좌측 패널 닫기/접기 버튼
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20, color: AppColors.textMuted),
                          tooltip: '목록 창 닫기/접기',
                          onPressed: () {
                            setState(() => _isLeftPanelCollapsed = true);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 필터 칩 (전체 / 인지일기 / 메모)
                Row(
                  children: [
                    _buildFilterChip('all', '전체'),
                    const SizedBox(width: 6),
                    _buildFilterChip('cbt', '5단계 인지일기'),
                    const SizedBox(width: 6),
                    _buildFilterChip('free', '메모/자유'),
                  ],
                ),
              ],
            ),
          ),

          // 일기 목록 스크롤 뷰
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentBrass))
                : filteredDiaries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌿', style: TextStyle(fontSize: 28)),
                              const SizedBox(height: 8),
                              Text(
                                '작성된 일기가 없습니다.',
                                style: GoogleFonts.gowunDodum(fontSize: 13, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredDiaries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final entry = filteredDiaries[i];
                          final isSelected = !_isWritingNew && _selectedEntry?.id == entry.id;

                          return _buildDesktopDiaryListCard(entry, isSelected);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _filterType == type;

    return InkWell(
      onTap: () => setState(() => _filterType = type),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBrass.withValues(alpha: 0.15) : AppColors.bgPanel2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.accentBrass : AppColors.inkLine,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.gowunDodum(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.accentBrass : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopDiaryListCard(DiaryEntry entry, bool isSelected) {
    return Material(
      color: isSelected ? AppColors.accentBrass.withValues(alpha: 0.12) : AppColors.bgPanel2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedEntry = entry;
            _isWritingNew = false;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedForQrIds.contains(entry.id)
                  ? AppColors.accentJade
                  : (isSelected ? AppColors.accentBrass : AppColors.inkLine),
              width: _selectedForQrIds.contains(entry.id) || isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _toggleQrSelection(entry.id),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Icon(
                        _selectedForQrIds.contains(entry.id)
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 16,
                        color: _selectedForQrIds.contains(entry.id)
                            ? AppColors.accentJade
                            : AppColors.textDim,
                      ),
                    ),
                  ),
                  Text(entry.moodEmoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDateTime(entry.createdAt),
                      style: GoogleFonts.gowunDodum(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.accentBrass : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: entry.type == DiaryType.structuredCbt
                          ? AppColors.accentJade.withValues(alpha: 0.15)
                          : AppColors.accentBrass.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.type == DiaryType.structuredCbt ? '인지일기' : '메모',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: entry.type == DiaryType.structuredCbt
                            ? AppColors.accentJade
                            : AppColors.accentBrass,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textDim),
                    tooltip: '삭제',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    onPressed: () => _deleteDiary(entry.id),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                entry.type == DiaryType.structuredCbt
                    ? (entry.thought.isNotEmpty ? '생각: ${entry.thought}' : '상황: ${entry.situation}')
                    : (entry.content.isNotEmpty ? entry.content : entry.title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.gowunDodum(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 세로 구분선 및 ◀ 접기 버튼
  Widget _buildDesktopSplitDivider() {
    return Container(
      width: 12,
      color: AppColors.bgDeep,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 1, color: AppColors.inkLine),
          InkWell(
            onTap: () {
              setState(() => _isLeftPanelCollapsed = true);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 20,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgPanel,
                border: Border.all(color: AppColors.inkLine),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_left, size: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  /// PC용 우측 메인 영역 (상단 툴바 + 작성창 또는 상세 뷰)
  Widget _buildDesktopMainPane() {
    final hasDiaries = _diaries.isNotEmpty;

    return Container(
      color: AppColors.bgDeep,
      child: Column(
        children: [
          // 상단 툴바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgPanel,
              border: Border(bottom: BorderSide(color: AppColors.inkLine)),
            ),
            child: Row(
              children: [
                // 좌측 패널이 닫혀 있을 때 [과거 목록 열기] 버튼
                if (_isLeftPanelCollapsed) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _isLeftPanelCollapsed = false);
                    },
                    icon: const Icon(Icons.menu_open, size: 16, color: AppColors.accentBrass),
                    label: Text(
                      '과거 일기 목록 열기 (${_diaries.length})',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBrass,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accentBrass),
                      backgroundColor: AppColors.accentBrass.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],

                Text(
                  _isWritingNew
                      ? (_desktopPendingQuote != null ? '📝 명언 성찰 메모 작성' : '✏️ 새 감정 일기 작성')
                      : '📖 일기 상세 보기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),

                // 신념 탐색 & 인지오류 사전 버튼
                OutlinedButton.icon(
                  onPressed: () {
                    if (!hasDiaries) {
                      _showInfoToast('저장된 일기가 있어야 활성화됩니다.');
                      return;
                    }
                    _openBeliefExplorer(
                      initialThought: _selectedEntry?.thought,
                    );
                  },
                  icon: const Icon(Icons.psychology_alt_outlined, size: 14, color: AppColors.accentBrass),
                  label: Text('신념 탐색', style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.accentBrass)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accentBrass),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _openDistortionGuide(),
                  icon: const Icon(Icons.menu_book, size: 14, color: AppColors.textMuted),
                  label: Text('인지오류', style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.textMuted)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.inkLine),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                if (widget.onQrPressed != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'QR 코드 발급',
                    child: InkWell(
                      onTap: widget.onQrPressed,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'QR',
                          style: TextStyle(
                            color: AppColors.accentJade,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                if (!_isWritingNew && _selectedEntry != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedEntry = null;
                        _isWritingNew = true;
                        _desktopPendingQuote = null;
                      });
                    },
                    icon: const Icon(Icons.add, size: 14),
                    label: Text('새 일기 쓰기', style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBrass,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 메인 본문: 작성 폼 또는 일기 상세
          Expanded(
            child: _isWritingNew
                ? WriteDiarySheet(
                    key: ValueKey('embedded_write_${_desktopPendingQuote?.original ?? ""}_${DateTime.now().millisecondsSinceEpoch}'),
                    initialType: _desktopPendingQuote != null ? DiaryType.free : DiaryType.structuredCbt,
                    initialQuote: _desktopPendingQuote,
                    isEmbedded: true,
                    onSaved: _loadDiaries,
                    onSavedEntry: (savedEntry) {
                      _loadDiaries();
                      setState(() {
                        _selectedEntry = savedEntry;
                        _isWritingNew = false;
                        _desktopPendingQuote = null;
                      });
                    },
                  )
                : _selectedEntry != null
                    ? _buildDesktopDetailView(_selectedEntry!)
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// PC용 일기 상세 뷰
  Widget _buildDesktopDetailView(DiaryEntry entry) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDiaryCard(entry),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedEntry = null;
                        _isWritingNew = true;
                        _desktopPendingQuote = null;
                      });
                    },
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: Text(
                      '새로운 감정 일기 작성하기',
                      style: GoogleFonts.gowunDodum(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBrass,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.gowunDodum(fontSize: 12.5, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accentNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _buildClinicianQrUrl(DiaryEntry? targetEntry) {
    if (targetEntry == null) {
      return 'https://dds-clinician.web.app';
    }

    final payload = {
      'v': 1,
      'app': 'audistine',
      'mode': 'single',
      'id': targetEntry.id,
      'dt': targetEntry.createdAt.toIso8601String(),
      'type': targetEntry.type.name,
      'mood': '${targetEntry.moodEmoji} ${targetEntry.moodLabel}',
      'title': targetEntry.title,
      'situation': targetEntry.situation,
      'thought': targetEntry.thought,
      'emotion': targetEntry.emotion,
      'distortions': targetEntry.detectedDistortions,
      'alt': targetEntry.alternativeThought,
      'action': targetEntry.action,
      'content': targetEntry.content,
    };

    final jsonStr = jsonEncode(payload);
    final base64Payload = base64UrlEncode(utf8.encode(jsonStr));
    return 'https://dds-clinician.web.app/review#data=$base64Payload';
  }

  /// 선택된 N건(1~5건)의 감정 일기를 컴팩트 규격으로 묶어 단일 URL로 생성
  String _buildClinicianBatchQrUrl(List<DiaryEntry> entries) {
    if (entries.isEmpty) {
      return 'https://dds-clinician.web.app';
    }
    if (entries.length == 1) {
      return _buildClinicianQrUrl(entries.first);
    }

    String trimField(String text, int max) =>
        text.length > max ? '${text.substring(0, max - 3)}...' : text;

    final compactList = entries.take(5).map((e) {
      return {
        'id': e.id,
        'dt': DateFormat('yyyy-MM-dd HH:mm').format(e.createdAt),
        't': e.type.name,
        'm': '${e.moodEmoji} ${e.moodLabel}',
        'sit': trimField(e.situation, 90),
        'th': trimField(e.thought, 90),
        'em': trimField(e.emotion, 40),
        'd': e.detectedDistortions,
        'alt': trimField(e.alternativeThought, 90),
        'act': trimField(e.action, 90),
      };
    }).toList();

    final payload = {
      'v': 1,
      'app': 'audistine',
      'mode': 'batch',
      'count': compactList.length,
      'entries': compactList,
    };

    final jsonStr = jsonEncode(payload);
    final base64Payload = base64UrlEncode(utf8.encode(jsonStr));
    return 'https://dds-clinician.web.app/review#data=$base64Payload';
  }

  void _showQrDialog() {
    if (_diaries.isEmpty) {
      _showInfoToast('QR로 전송할 감정 일기가 없습니다. 먼저 일기를 작성해 주세요.');
      return;
    }

    // 메인 화면에서 선택된 항목이 없으면 현재 선택/최신 1건을 기본 선택
    if (_selectedForQrIds.isEmpty) {
      final defaultTarget = _selectedEntry ?? _diaries.first;
      _selectedForQrIds.add(defaultTarget.id);
    }

    bool showPickerList = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // 선택된 일기들 (최대 5건)
          final chosenEntries = _diaries
              .where((e) => _selectedForQrIds.contains(e.id))
              .take(5)
              .toList();

          final currentUrl = chosenEntries.isEmpty
              ? 'https://dds-clinician.web.app'
              : (chosenEntries.length == 1
                  ? _buildClinicianQrUrl(chosenEntries.first)
                  : _buildClinicianBatchQrUrl(chosenEntries));

          return AlertDialog(
            backgroundColor: AppColors.bgPanel,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            title: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accentJade, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '상담자(DDS-Clinician) 연동 QR',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentJade,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '선택하신 일기 내용만 상담자에게 안전하게 전달됩니다.',
                  style: GoogleFonts.gowunDodum(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            content: SizedBox(
              width: 330,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 선택 상태 요약 & 선택 변경 토글
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgPanel2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.inkLineLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.checklist_rounded, size: 15, color: AppColors.accentJade),
                              const SizedBox(width: 6),
                              Text(
                                '선택된 일기: ${chosenEntries.length}건 (최대 5건)',
                                style: GoogleFonts.gowunDodum(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (_diaries.length > 1)
                            InkWell(
                              onTap: () => setModalState(() => showPickerList = !showPickerList),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  showPickerList ? '접기' : '선택 변경',
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentJade,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 2. 일기 선택 변경 체크박스 목록 (접힘/펼침)
                    if (showPickerList && _diaries.length > 1)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: const BoxConstraints(maxHeight: 140),
                        decoration: BoxDecoration(
                          color: AppColors.bgPanel2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.inkLineLight),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _diaries.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.inkLineLight),
                          itemBuilder: (context, idx) {
                            final item = _diaries[idx];
                            final isChecked = _selectedForQrIds.contains(item.id);
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (isChecked) {
                                    if (_selectedForQrIds.length > 1) {
                                      _selectedForQrIds.remove(item.id);
                                    }
                                  } else {
                                    if (_selectedForQrIds.length < 5) {
                                      _selectedForQrIds.add(item.id);
                                    }
                                  }
                                });
                                setState(() {}); // 메인 화면 카드 체크박스 동기화
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                      size: 16,
                                      color: isChecked ? AppColors.accentJade : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${DateFormat('MM.dd').format(item.createdAt)} ${item.moodEmoji}',
                                      style: GoogleFonts.gowunDodum(
                                        fontSize: 11,
                                        fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                        color: isChecked ? AppColors.accentJade : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.situation.isNotEmpty
                                            ? item.situation
                                            : (item.thought.isNotEmpty ? item.thought : item.content),
                                        style: GoogleFonts.gowunDodum(fontSize: 10.5, color: AppColors.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // 3. QR 이미지
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inkLine),
                      ),
                      child: QrImageView(
                        data: currentUrl,
                        version: QrVersions.auto,
                        errorCorrectionLevel: QrErrorCorrectLevel.L,
                        size: 185.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1E293B),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: currentUrl));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          chosenEntries.length > 1
                              ? '선택된 ${chosenEntries.length}건 상담 링크가 복사되었습니다 (DDS-Clinician)'
                              : '상담자 열람 링크가 복사되었습니다 (DDS-Clinician)',
                          style: GoogleFonts.gowunDodum(fontSize: 12, color: Colors.white),
                        ),
                        backgroundColor: AppColors.accentJade,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentJade,
                  side: const BorderSide(color: AppColors.accentJade, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.copy_rounded, size: 13),
                label: Text(
                  '링크 복사',
                  style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  '닫기',
                  style: GoogleFonts.gowunDodum(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final hasDiaries = _diaries.isNotEmpty;

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inkLine, width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1줄: '감정 일기' 제목 (가운데 정렬)
          Center(
            child: Text(
              '감정 일기',
              style: GoogleFonts.gowunDodum(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accentJade,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 2줄: 'QR'은 작게해서 제목 다음줄 우측 정렬
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Tooltip(
                message: _selectedForQrIds.isNotEmpty
                    ? '선택된 ${_selectedForQrIds.length}건 QR 생성'
                    : '상담자 연동 QR',
                child: InkWell(
                  onTap: widget.onQrPressed ?? _showQrDialog,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _selectedForQrIds.isNotEmpty
                          ? AppColors.accentJade.withValues(alpha: 0.15)
                          : AppColors.bgPanel2,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _selectedForQrIds.isNotEmpty
                            ? AppColors.accentJade
                            : AppColors.inkLine,
                      ),
                    ),
                    child: Text(
                      _selectedForQrIds.isNotEmpty ? 'QR (${_selectedForQrIds.length})' : 'QR',
                      style: GoogleFonts.gowunDodum(
                        color: AppColors.accentJade,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3줄: 첫 화면과 동일한 위치에 날짜, 시각 표시
          const HeaderDateTime(),
          const SizedBox(height: 10),

          // 4줄: '일기쓰기', '신념탐색', '인지오류' 버튼 (위아래 폭 넓힘)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openWriteModal(initialType: DiaryType.structuredCbt),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentJade,
                  side: const BorderSide(
                    color: AppColors.accentJade,
                    width: 1.2,
                  ),
                  backgroundColor: AppColors.accentJade.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(
                  Icons.edit_note,
                  size: 15,
                  color: AppColors.accentJade,
                ),
                label: Text(
                  '일기쓰기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentJade,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (!hasDiaries) {
                        _showInfoToast('저장된 일기가 있어야 활성화됩니다.');
                        return;
                      }
                      _openBeliefExplorer();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hasDiaries ? AppColors.accentBrass : AppColors.textDim,
                      side: BorderSide(
                        color: hasDiaries ? AppColors.accentBrass : AppColors.inkLineLight,
                        width: 1.2,
                      ),
                      backgroundColor: hasDiaries ? Colors.transparent : AppColors.bgPanel2.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: Icon(
                      Icons.psychology_alt_outlined,
                      size: 14,
                      color: hasDiaries ? AppColors.accentBrass : AppColors.textDim,
                    ),
                    label: Text(
                      '신념 탐색',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 11.5,
                        fontWeight: hasDiaries ? FontWeight.bold : FontWeight.normal,
                        color: hasDiaries ? AppColors.accentBrass : AppColors.textDim,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (!hasDiaries) {
                        _showInfoToast('저장된 일기가 있어야 활성화됩니다.');
                        return;
                      }
                      _openDistortionGuide();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hasDiaries ? AppColors.textMuted : AppColors.textDim,
                      side: BorderSide(
                        color: hasDiaries ? AppColors.inkLine : AppColors.inkLineLight,
                        width: 1.2,
                      ),
                      backgroundColor: hasDiaries ? Colors.transparent : AppColors.bgPanel2.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: Icon(
                      Icons.menu_book,
                      size: 14,
                      color: hasDiaries ? AppColors.textMuted : AppColors.textDim,
                    ),
                    label: Text(
                      '인지오류',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 11.5,
                        color: hasDiaries ? AppColors.textMuted : AppColors.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Column(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 12),
          Text(
            '아직 작성된 감정 일기나 메모가 없습니다.',
            style: GoogleFonts.gowunDodum(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '오늘 마음을 스쳐 지나간 생각이나 감정을\n5단계 구조화 일기 또는 명언 메모로 적어보세요.',
            textAlign: TextAlign.center,
            style: GoogleFonts.gowunDodum(fontSize: 12.5, color: AppColors.textMuted, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryCard(DiaryEntry entry) {
    final isChecked = _selectedForQrIds.contains(entry.id);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isChecked ? AppColors.accentJade : AppColors.inkLine,
          width: isChecked ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 메타 (선택 체크박스 + 날짜 + 작성시간, 기분, 모드 라벨, 삭제 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleQrSelection(entry.id),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          isChecked
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 19,
                          color: isChecked ? AppColors.accentJade : AppColors.textDim,
                        ),
                      ),
                    ),
                    Text(entry.moodEmoji, style: const TextStyle(fontSize: 19)),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        _formatDateTime(entry.createdAt),
                        style: GoogleFonts.gowunDodum(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: entry.type == DiaryType.structuredCbt
                            ? AppColors.accentJade.withValues(alpha: 0.12)
                            : AppColors.accentBrass.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.type == DiaryType.structuredCbt ? '5단계 인지일기' : '메모',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: entry.type == DiaryType.structuredCbt
                              ? AppColors.accentJade
                              : AppColors.accentBrass,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.textDim),
                onPressed: () => _deleteDiary(entry.id),
                tooltip: '삭제',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 내용 영역
          // 명언 메모인 경우 상단에 명언 카드 요약 표시 (띄어쓰기, 줄바꿈 서식 적용)
          if (entry.quoteTranslation.isNotEmpty || entry.quoteOriginal.isNotEmpty || entry.quoteEnglish.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.bgCardWarm,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.inkLine, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.quoteOriginal.isNotEmpty) ...[
                    QuoteFormatter.buildRubyHanjaView(
                      original: entry.quoteOriginal,
                      reading: entry.quoteReading,
                      origFontSize: 16.5,
                      readFontSize: 11.0,
                      segmentSpacing: 10,
                      segmentRunSpacing: 8,
                    ),
                    const SizedBox(height: 10),
                  ] else if (entry.quoteEnglish.isNotEmpty) ...[
                    Text(
                      entry.quoteEnglish,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.accentVermilion.withValues(alpha: 0.9),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    QuoteFormatter.formatPoeticKorean(entry.quoteTranslation),
                    style: GoogleFonts.gowunDodum(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentNavy,
                      height: 1.65,
                    ),
                  ),
                  if (entry.quoteSource.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      '— ${entry.quoteSource}',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 12,
                        color: AppColors.accentBrass,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (entry.type == DiaryType.free) ...[
            if (entry.title.isNotEmpty) ...[
              Text(
                entry.title,
                style: GoogleFonts.gowunDodum(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              entry.content,
              style: GoogleFonts.gowunDodum(fontSize: 14.5, height: 1.65, color: AppColors.textSecondary),
            ),
          ] else ...[
            _buildSectionRow('📌 상황', entry.situation, AppColors.textPrimary),
            const SizedBox(height: 10),
            _buildSectionRow('💭 생각 (스친 생각)', entry.thought, AppColors.accentVermilion, isHighlight: true),
            const SizedBox(height: 10),
            _buildSectionRow('💧 감정', entry.emotion, AppColors.accentNavy),
            const SizedBox(height: 10),
            _buildSectionRow('💡 대안적 생각', entry.alternativeThought, AppColors.accentJade),
            const SizedBox(height: 10),
            _buildSectionRow('🏃 행동 (나의 반응)', entry.action, AppColors.textSecondary),

            if (entry.thought.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.inkLine, height: 1, thickness: 1),
              const SizedBox(height: 10),

              // 1. 인지오류 영역: 감지된 오류가 있으면 '위 생각 (스친 생각)의 오류 점검하기' 표제어 및 감지된 오류 칩 표출, 없으면 '인지오류 점검하기' 링크 표출
              if (entry.detectedDistortions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, size: 13, color: AppColors.accentBrass),
                      const SizedBox(width: 4),
                      Text(
                        '위 생각 (스친 생각)의 오류 점검하기',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11.5,
                          color: AppColors.accentBrass,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.detectedDistortions.map((d) {
                    return InkWell(
                      onTap: () => _openDistortionGuide(targetDistortionName: d),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.accentBrass.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentBrass.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lightbulb_outline, size: 11, color: AppColors.accentBrass),
                            const SizedBox(width: 3.5),
                            Text(
                              d,
                              style: GoogleFonts.gowunDodum(
                                fontSize: 10.5,
                                color: AppColors.accentBrass,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.open_in_new, size: 10, color: AppColors.accentBrass),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                InkWell(
                  onTap: () => _openDistortionGuide(),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '인지오류 점검하기 >',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // 2. 심층 뿌리 신념 탐색 영역
              InkWell(
                onTap: () => _openBeliefExplorer(
                  initialThought: entry.thought,
                  initialTabIndex: 0,
                ),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_downward, size: 13, color: AppColors.accentBrass),
                      const SizedBox(width: 4),
                      Text(
                        '이 생각의 뿌리 신념 탐색하기 >',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11.5,
                          color: AppColors.accentBrass,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionRow(String label, String content, Color accentColor, {bool isHighlight = false}) {
    if (content.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: isHighlight ? const EdgeInsets.all(12) : const EdgeInsets.symmetric(vertical: 3),
      decoration: isHighlight
          ? BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.gowunDodum(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.gowunDodum(
              fontSize: 14.5,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 명언 서식 유틸리티 (띄어쓰기, 한자-독음 루비 페어링, 시적 줄바꿈)
// ---------------------------------------------------------------------------
class QuoteFormatter {
  static final RegExp _punctuationRegex = RegExp(r'([.?!])\s+(?=\S)');
  static final RegExp _commaSplitRegex = RegExp(r',\s*');

  /// 한국어 명언 번역문의 쉼표, 마침표, 구절 어미에 맞추어 시적이고 운율감 있는 줄바꿈 및 띄어쓰기 서식 적용
  static String formatPoeticKorean(String text) {
    if (text.trim().isEmpty) return '';
    if (text.contains('\n')) return text.trim();

    // 1단계: 마침표/물음표/느낌표 + 공백 뒤 줄바꿈
    String formatted = text.replaceAllMapped(
      _punctuationRegex,
      (match) => '${match.group(1)}\n',
    );

    // 2단계: 쉼표(,) 뒤의 절 분리 (문맥상 행이 너무 짧지 않을 때)
    final lines = formatted.split('\n');
    final resultLines = <String>[];

    for (final line in lines) {
      if (line.contains(',') && line.length > 14) {
        final parts = line.split(_commaSplitRegex);
        final buffer = StringBuffer();
        for (int i = 0; i < parts.length; i++) {
          final p = parts[i].trim();
          if (p.isEmpty) continue;
          buffer.write(p);
          if (i < parts.length - 1) {
            buffer.write(',\n');
          }
        }
        resultLines.add(buffer.toString());
      } else {
        resultLines.add(line.trim());
      }
    }

    return resultLines.where((l) => l.isNotEmpty).join('\n');
  }

  /// 한자 원문과 독음을 어절 단위로 나누고, 각 한자 글자 위에 독음을 정갈하게 페어링하여 줄바꿈 지원
  static Widget buildRubyHanjaView({
    required String original,
    required String reading,
    double origFontSize = 16.5,
    double readFontSize = 10.5,
    Color origColor = AppColors.accentJade,
    Color readColor = AppColors.textMuted,
    double segmentSpacing = 12.0,
    double segmentRunSpacing = 10.0,
  }) {
    if (original.trim().isEmpty) return const SizedBox.shrink();

    final origParts = original.split(' ').where((s) => s.isNotEmpty).toList();
    final readParts = reading.split(' ').where((s) => s.isNotEmpty).toList();
    final maxSegments = origParts.length > readParts.length ? origParts.length : readParts.length;

    if (maxSegments == 0) return const SizedBox.shrink();

    return Wrap(
      spacing: segmentSpacing,
      runSpacing: segmentRunSpacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(maxSegments, (segmentIdx) {
        final origStr = segmentIdx < origParts.length ? origParts[segmentIdx] : '';
        final readStr = segmentIdx < readParts.length ? readParts[segmentIdx] : '';
        final maxLen = origStr.length > readStr.length ? origStr.length : readStr.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(maxLen, (charIdx) {
            final oChar = charIdx < origStr.length ? origStr[charIdx] : '';
            final rChar = charIdx < readStr.length ? readStr[charIdx] : '';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    rChar,
                    style: GoogleFonts.gowunDodum(
                      fontSize: readFontSize,
                      color: readColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    oChar,
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: origFontSize,
                      fontWeight: FontWeight.w600,
                      color: origColor,
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
                  ),
                ],
              ),
            );
          }),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// 일기 및 명언 메모 작성 모달 시트 및 임베디드 폼
// ---------------------------------------------------------------------------
class WriteDiarySheet extends StatefulWidget {
  final DiaryType initialType;
  final Quote? initialQuote;
  final VoidCallback onSaved;
  final void Function(DiaryEntry entry)? onSavedEntry;
  final bool isEmbedded;

  const WriteDiarySheet({
    super.key,
    this.initialType = DiaryType.structuredCbt,
    this.initialQuote,
    required this.onSaved,
    this.onSavedEntry,
    this.isEmbedded = false,
  });

  @override
  State<WriteDiarySheet> createState() => _WriteDiarySheetState();
}

class _WriteDiarySheetState extends State<WriteDiarySheet> {
  late DiaryType _type;
  String? _toastMessage;
  Timer? _toastTimer;

  final _titleController = TextEditingController();
  final _freeContentController = TextEditingController();

  final _emotionController = TextEditingController();
  final _situationController = TextEditingController();
  final _thoughtController = TextEditingController();
  final _alternativeController = TextEditingController();
  final _actionController = TextEditingController();

  List<CognitiveDistortion> _detectedDistortions = [];

  bool get _isQuoteMemoMode => widget.initialQuote != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _thoughtController.addListener(_onThoughtChanged);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _thoughtController.removeListener(_onThoughtChanged);
    _titleController.dispose();
    _freeContentController.dispose();
    _emotionController.dispose();
    _situationController.dispose();
    _thoughtController.dispose();
    _alternativeController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  void _onThoughtChanged() {
    final text = _thoughtController.text;
    final detected = CognitiveDistortionDatabase.detectDistortions(text);
    setState(() {
      _detectedDistortions = detected;
    });
  }

  Future<void> _save() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    final moodEmoji = _isQuoteMemoMode
        ? '📝'
        : (_type == DiaryType.structuredCbt ? '💡' : '📖');
    final moodLabel = _isQuoteMemoMode
        ? '명언 메모'
        : (_type == DiaryType.structuredCbt ? '인지일기' : '자유일기');

    final entry = DiaryEntry(
      id: id,
      createdAt: now,
      type: _type,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      title: _titleController.text.trim(),
      content: _freeContentController.text.trim(),
      situation: _situationController.text.trim(),
      thought: _thoughtController.text.trim(),
      emotion: _emotionController.text.trim(),
      alternativeThought: _alternativeController.text.trim(),
      action: _actionController.text.trim(),
      detectedDistortions: _detectedDistortions.map((d) => d.name).toList(),
      quoteOriginal: widget.initialQuote?.original ?? '',
      quoteReading: widget.initialQuote?.reading ?? '',
      quoteTranslation: widget.initialQuote?.translation ?? '',
      quoteSource: widget.initialQuote?.source ?? '',
      quoteEnglish: widget.initialQuote?.english ?? '',
      quoteCommentary: widget.initialQuote?.commentary ?? '',
    );

    if (_type == DiaryType.free) {
      if (entry.content.isEmpty && entry.title.isEmpty) {
        _showToast('메모 내용을 입력해주세요.');
        return;
      }
    } else {
      if (entry.thought.isEmpty && entry.situation.isEmpty && entry.emotion.isEmpty) {
        _showToast('감정이나 상황, 생각을 하나 이상 적어주세요.');
        return;
      }
    }

    await StorageService.saveDiary(entry);
    widget.onSaved();
    if (widget.isEmbedded) {
      widget.onSavedEntry?.call(entry);
      _showToast('일기가 성공적으로 저장되었습니다.');
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showToast(String msg) {
    _toastTimer?.cancel();
    setState(() => _toastMessage = msg);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _toastMessage = null);
      }
    });
  }

  void _openDistortionGuide({String? targetDistortionName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _DistortionGuideSheet(targetDistortionName: targetDistortionName),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgPanel2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _type = DiaryType.structuredCbt),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _type == DiaryType.structuredCbt ? AppColors.accentBrass : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  '5단계 인지 기록지',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _type == DiaryType.structuredCbt ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _type = DiaryType.free),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _type == DiaryType.free ? AppColors.accentBrass : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  '자유 서술 일기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _type == DiaryType.free ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // [명언 메모 모드일 때] 명언 카드 박스
        if (_isQuoteMemoMode && widget.initialQuote != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCardWarm,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 뱃지 및 출처
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentBrass.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📜', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '동양 고전 명언',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentBrass,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.initialQuote!.source.isNotEmpty)
                      Text(
                        '— ${widget.initialQuote!.source}',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11.5,
                          color: AppColors.textDim,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // 한자 원문 및 독음 루비 뷰
                if (widget.initialQuote!.original.isNotEmpty) ...[
                  QuoteFormatter.buildRubyHanjaView(
                    original: widget.initialQuote!.original,
                    reading: widget.initialQuote!.reading,
                    origFontSize: 16.0,
                    readFontSize: 10.0,
                    origColor: AppColors.accentJade,
                    readColor: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                ],

                // 영문 번역 (존재 시)
                if (widget.initialQuote!.english.isNotEmpty) ...[
                  Text(
                    widget.initialQuote!.english,
                    style: GoogleFonts.gowunDodum(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.accentVermilion.withValues(alpha: 0.9),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 한국어 번역 풀이
                Text(
                  QuoteFormatter.formatPoeticKorean(widget.initialQuote!.translation),
                  style: GoogleFonts.gowunDodum(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentNavy,
                    height: 1.7,
                    letterSpacing: 0.2,
                  ),
                ),

                // 명언 해설 (존재 시)
                if (widget.initialQuote!.commentary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgPanel2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.lightbulb_outline,
                            size: 13,
                            color: AppColors.accentBrass,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.initialQuote!.commentary,
                            style: GoogleFonts.gowunDodum(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 내용 입력 필드
        if (_type == DiaryType.free) ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.bgPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inkLine, width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isQuoteMemoMode ? Icons.edit_note : Icons.edit,
                      size: 17,
                      color: AppColors.accentBrass,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isQuoteMemoMode ? '명언 성찰 메모' : '자유 일기 내용',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBrass,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _freeContentController,
                  maxLines: _isQuoteMemoMode ? 8 : 10,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13.5,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: _isQuoteMemoMode
                        ? '이 문장을 읽고 떠오른 생각, 나의 다짐, 오늘의 감정을 자유롭게 적어보세요.'
                        : '오늘 하루 있었던 일이나 생각, 감정을 편안하게 적어보세요.',
                    hintStyle: GoogleFonts.gowunDodum(
                      fontSize: 12.5,
                      color: AppColors.textDim,
                      height: 1.5,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          _buildStepInput(
            stepNum: '1',
            title: '감정 (지금 느끼는 기분)',
            hint: '예: 서운함, 억울함, 불안함 70%',
            controller: _emotionController,
            accentColor: AppColors.accentNavy,
            maxLines: 2,
          ),
          const SizedBox(height: 14),

          _buildStepInput(
            stepNum: '2',
            title: '상황 (무슨 일이 일어났나요?)',
            hint: '예: 동료 직원이 아는 척하지 않고 그냥 지나쳤다.',
            controller: _situationController,
            accentColor: AppColors.textPrimary,
            maxLines: 2,
          ),
          const SizedBox(height: 14),

          _buildStepInput(
            stepNum: '3',
            title: '생각 (그 순간 스쳐 지나간 생각은?)',
            hint: '예: 저 사람은 나를 싫어해, 날 무시하는 거야',
            controller: _thoughtController,
            accentColor: AppColors.accentVermilion,
            maxLines: 2,
          ),

          if (_detectedDistortions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._detectedDistortions.map((d) => _buildDistortionAlertBox(d)),
          ],

          const SizedBox(height: 14),

          _buildStepInput(
            stepNum: '4',
            title: '대안적 생각 (다른 가능성이나 관점은?)',
            hint: '예: 나를 미처 못 봤거나, 마침 급한 일이 있었을 수도 있어.',
            controller: _alternativeController,
            accentColor: AppColors.accentJade,
            maxLines: 3,
          ),
          const SizedBox(height: 14),

          _buildStepInput(
            stepNum: '5',
            title: '행동 (결국 어떻게 반응했나요?)',
            hint: '예: 나도 모른 척했지만, 내일은 먼저 인사해보기로 했다.',
            controller: _actionController,
            accentColor: AppColors.textSecondary,
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  Widget _buildFloatingToast() {
    return Positioned(
      bottom: widget.isEmbedded ? 20 : 56,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _toastMessage != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentNavy.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _toastMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gowunDodum(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isQuoteMemoMode) ...[
                      _buildModeToggle(),
                      const SizedBox(height: 16),
                    ],
                    _buildFormContent(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBrass,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          _isQuoteMemoMode ? '메모 저장하기' : '일기 저장하기',
                          style: GoogleFonts.gowunDodum(fontSize: 14.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_toastMessage != null) _buildFloatingToast(),
        ],
      );
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Stack(
            children: [
              Column(
                children: [
                  // 상단 타이틀 및 닫기 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isQuoteMemoMode ? '명언 메모' : '감정 일기 쓰기',
                        style: GoogleFonts.gowunDodum(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (!_isQuoteMemoMode) ...[
                    _buildModeToggle(),
                    const SizedBox(height: 12),
                  ],

                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildFormContent(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 하단 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBrass,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        _isQuoteMemoMode ? '메모 저장하기' : '일기 저장하기',
                        style: GoogleFonts.gowunDodum(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              if (_toastMessage != null) _buildFloatingToast(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepInput({
    required String stepNum,
    required String title,
    required String hint,
    required TextEditingController controller,
    required Color accentColor,
    int maxLines = 1,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inkLine, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNum,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.gowunDodum(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.gowunDodum(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.textDim, height: 1.4),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistortionAlertBox(CognitiveDistortion d) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.accentBrass.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb, size: 14, color: AppColors.accentBrass),
                  const SizedBox(width: 4),
                  Text(
                    '혹시 [${d.name}] 오류일까요?',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBrass,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openDistortionGuide(targetDistortionName: d.name),
                child: Text(
                  '사전 보기 >',
                  style: GoogleFonts.gowunDodum(fontSize: 11, color: AppColors.accentBrass, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '🔍 성찰 질문: ${d.reframingQuestion}',
            style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 10가지 인지오류 안내 모달 시트 (도움말/사전)
// ---------------------------------------------------------------------------
class _DistortionGuideSheet extends StatefulWidget {
  final String? targetDistortionName;
  const _DistortionGuideSheet({this.targetDistortionName});

  @override
  State<_DistortionGuideSheet> createState() => _DistortionGuideSheetState();
}

class _DistortionGuideSheetState extends State<_DistortionGuideSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.targetDistortionName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = widget.targetDistortionName!.trim().toLowerCase();
        final index = CognitiveDistortionDatabase.all.indexWhere(
          (d) => d.name.toLowerCase().contains(target) || target.contains(d.name.toLowerCase().split(' ')[0]),
        );
        if (index != -1 && _scrollController.hasClients) {
          final targetOffset = (index * 160.0).clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              color: AppColors.inkLineLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: AppColors.accentBrass, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '인지 오류(생각의 왜곡) 사전',
                    style: GoogleFonts.gowunDodum(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '누구나 불안하거나 힘들 때 생각에 오류가 생깁니다. 내 생각이 아래 유형 중 어디에 해당하는지 살펴보세요.',
            style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              itemCount: CognitiveDistortionDatabase.all.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final d = CognitiveDistortionDatabase.all[i];
                final isTarget = widget.targetDistortionName != null &&
                    (d.name.toLowerCase().contains(widget.targetDistortionName!.toLowerCase()) ||
                        widget.targetDistortionName!.toLowerCase().contains(d.name.toLowerCase().split(' ')[0]));

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isTarget ? AppColors.accentBrass.withValues(alpha: 0.1) : AppColors.bgPanel,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isTarget ? AppColors.accentBrass : AppColors.inkLineLight,
                      width: isTarget ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isTarget ? AppColors.accentBrass.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
                        blurRadius: isTarget ? 10 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isTarget ? AppColors.accentBrass : AppColors.accentBrass.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: GoogleFonts.gowunDodum(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isTarget ? Colors.white : AppColors.accentBrass,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.name,
                              style: GoogleFonts.gowunDodum(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isTarget ? AppColors.accentBrass : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isTarget)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentBrass,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '선택된 오류',
                                style: GoogleFonts.gowunDodum(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.shortDesc,
                        style: GoogleFonts.gowunDodum(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgPanel2,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.inkLineLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '예시: ${d.example}',
                              style: GoogleFonts.gowunDodum(
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                                color: AppColors.accentVermilion,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '💡 성찰 질문: ${d.reframingQuestion}',
                              style: GoogleFonts.gowunDodum(
                                fontSize: 11.5,
                                color: AppColors.accentJade,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}

/// 터치 판별(단순 탭 vs 8px 이상 드래그 이동) 기능이 탑재된 자유 드래그 플로팅 버튼
class _DraggableDiaryFab extends StatefulWidget {
  final Size bounds;
  final VoidCallback onTap;

  const _DraggableDiaryFab({
    required this.bounds,
    required this.onTap,
  });

  @override
  State<_DraggableDiaryFab> createState() => _DraggableDiaryFabState();
}

class _DraggableDiaryFabState extends State<_DraggableDiaryFab> {
  Offset? _position;
  Offset _dragStartGlobal = Offset.zero;
  bool _isDragging = false;
  static const double _dragThreshold = 8.0; // 8픽셀 이상 움직여야 드래그로 판정

  @override
  Widget build(BuildContext context) {
    const btnW = 120.0;
    const btnH = 46.0;
    const margin = 16.0;

    final screenW = widget.bounds.width;
    final screenH = widget.bounds.height;

    const minX = margin;
    final maxX = (screenW - btnW - margin).clamp(minX, double.infinity);
    const minY = margin;
    final maxY = (screenH - btnH - margin).clamp(minY, double.infinity);

    // 초기 위치: 화면 우측 하단
    if (_position == null) {
      _position = Offset(maxX, (maxY - 58.0).clamp(minY, maxY));
    } else {
      _position = Offset(
        _position!.dx.clamp(minX, maxX),
        _position!.dy.clamp(minY, maxY),
      );
    }

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: Listener(
        onPointerDown: (event) {
          _dragStartGlobal = event.position;
          _isDragging = false;
        },
        onPointerMove: (event) {
          final totalDelta = event.position - _dragStartGlobal;
          if (!_isDragging && totalDelta.distance > _dragThreshold) {
            _isDragging = true;
          }
          if (_isDragging) {
            setState(() {
              final nextX = (_position!.dx + event.delta.dx).clamp(minX, maxX);
              final nextY = (_position!.dy + event.delta.dy).clamp(minY, maxY);
              _position = Offset(nextX, nextY);
            });
          }
        },
        onPointerUp: (event) {
          if (!_isDragging) {
            // 드래그가 아닌 단순 탭인 경우 100% 확실하게 일기 쓰기 모달 실행
            widget.onTap();
          }
          _isDragging = false;
        },
        child: Material(
          elevation: 6,
          color: AppColors.accentBrass,
          borderRadius: BorderRadius.circular(24),
          shadowColor: Colors.black54,
          child: Container(
            width: btnW,
            height: btnH,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_note, size: 22, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '일기 쓰기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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


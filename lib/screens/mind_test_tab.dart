import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/belief_test_model.dart';
import '../models/mind_test_model.dart';
import '../models/quote.dart';
import '../models/self_connection_test_model.dart';
import '../models/survival_rule_test_model.dart';
import '../screens/belief_test_sheet.dart';
import '../screens/rest_tab.dart';
import '../screens/self_connection_test_sheet.dart';
import '../screens/survival_rule_test_sheet.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/header_date_time.dart';

class MindTestTab extends StatefulWidget {
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;
  final VoidCallback? onQrPressed;

  const MindTestTab({
    super.key,
    this.onNavigateToRest,
    this.onNavigateToDiaryWithQuote,
    this.onNavigateToDiary,
    this.onQrPressed,
  });

  @override
  State<MindTestTab> createState() => _MindTestTabState();
}

class _MindTestTabState extends State<MindTestTab>
    with AutomaticKeepAliveClientMixin<MindTestTab> {
  List<MindTestResult> _results = [];
  List<SelfConnectionTestResult> _selfConnectionResults = [];
  List<BeliefTestResult> _beliefResults = [];
  List<SurvivalRuleTestResult> _survivalRuleResults = [];
  bool _isLoading = true;
  int _historyFilterIndex = 0; // 0: 전체, 1: 기분 팔레트, 2: 자존감·외로움, 3: 핵심신념, 4: 삶의규칙

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final list = await StorageService.loadMindTestResults();
    final scList = await StorageService.loadSelfConnectionTestResults();
    final bList = await StorageService.loadBeliefTestResults();
    final srList = await StorageService.loadSurvivalRuleTestResults();
    if (!mounted) return;
    setState(() {
      _results = list;
      _selfConnectionResults = scList;
      _beliefResults = bList;
      _survivalRuleResults = srList;
      _isLoading = false;
    });
  }

  void _startEmotionPaletteTest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmotionPaletteFlowModal(
        onCompleted: (result) async {
          await StorageService.saveMindTestResult(result);
          _loadResults();
        },
        onNavigateToRest: widget.onNavigateToRest,
        onNavigateToDiary: widget.onNavigateToDiary,
      ),
    );
  }

  void _startSelfConnectionTest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelfConnectionFlowModal(
        onCompleted: (result) async {
          await StorageService.saveSelfConnectionTestResult(result);
          _loadResults();
        },
        onNavigateToRest: widget.onNavigateToRest,
        onNavigateToDiaryWithQuote: widget.onNavigateToDiaryWithQuote,
        onNavigateToDiary: widget.onNavigateToDiary,
      ),
    );
  }

  void _startBeliefTest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BeliefTestFlowModal(
        onCompleted: (result) async {
          await StorageService.saveBeliefTestResult(result);
          _loadResults();
        },
        onNavigateToRest: widget.onNavigateToRest,
        onNavigateToDiaryWithQuote: widget.onNavigateToDiaryWithQuote,
        onNavigateToDiary: widget.onNavigateToDiary,
      ),
    );
  }

  void _startSurvivalRuleTest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SurvivalRuleFlowModal(
        onCompleted: (result) async {
          await StorageService.saveSurvivalRuleTestResult(result);
          _loadResults();
        },
        onNavigateToRest: widget.onNavigateToRest,
        onNavigateToDiaryWithQuote: widget.onNavigateToDiaryWithQuote,
        onNavigateToDiary: widget.onNavigateToDiary,
      ),
    );
  }

  void _showResultDetailModal(MindTestResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ResultDetailSheet(
        result: result,
        onNavigateToRest: widget.onNavigateToRest,
        onNavigateToDiary: widget.onNavigateToDiary,
      ),
    );
  }

  void _showSelfConnectionDetailModal(SelfConnectionTestResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelfConnectionResultDetailSheet(
        result: result,
        onNavigateToRest: widget.onNavigateToRest,
        onNavigateToDiaryWithQuote: widget.onNavigateToDiaryWithQuote,
        onNavigateToDiary: widget.onNavigateToDiary,
      ),
    );
  }

  void _showBeliefDetailModal(BeliefTestResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BeliefTestResultDetailSheet(
        result: result,
        onNavigateToRest: widget.onNavigateToRest,
        onNavigateToDiaryWithQuote: widget.onNavigateToDiaryWithQuote,
        onNavigateToDiary: widget.onNavigateToDiary,
      ),
    );
  }

  void _showSurvivalRuleDetailModal(SurvivalRuleTestResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SurvivalRuleResultDetailSheet(
        result: result,
        onNavigateToRest: widget.onNavigateToRest,
        onNavigateToDiaryWithQuote: widget.onNavigateToDiaryWithQuote,
        onNavigateToDiary: widget.onNavigateToDiary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final latestEmotionResult = _results.isNotEmpty ? _results.first : null;
    final latestSelfConnectionResult =
        _selfConnectionResults.isNotEmpty ? _selfConnectionResults.first : null;
    final latestBeliefResult =
        _beliefResults.isNotEmpty ? _beliefResults.first : null;
    final latestSurvivalRuleResult =
        _survivalRuleResults.isNotEmpty ? _survivalRuleResults.first : null;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '마음 검사',
          style: GoogleFonts.gowunDodum(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (widget.onQrPressed != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'QR 코드 발급',
                child: InkWell(
                  onTap: widget.onQrPressed,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'QR',
                      style: TextStyle(
                        color: AppColors.accentBrass,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentBrass))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 일시 표시 (첫 화면과 동일한 스타일 및 위치)
                  const HeaderDateTime(),
                  const SizedBox(height: 12),

                  // 상단 환영 / 철학 배너
                  _buildIntroBanner(),
                  const SizedBox(height: 22),

                  // 검사 프로그램 섹션 헤더
                  Text(
                    '마음 진단 프로그램',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // [검사 1] 🎨 감정 팔레트 검사 (기분 프로파일링)
                  _buildEmotionPaletteCard(),
                  const SizedBox(height: 14),

                  // [검사 2] 🧭 내면 & 관계의 나침반 (자존감 & 외로움 절대 평가)
                  _buildSelfConnectionCard(),
                  const SizedBox(height: 14),

                  // [검사 3] 🛡️ 핵심 신념 탐색 & 삶의 규칙 (CBT 인지 재구성)
                  _buildBeliefTestCard(),
                  const SizedBox(height: 14),

                  // [검사 4] 📜 삶의 규칙 & 방어 기제 탐색 (경직도 & 3단계 완화)
                  _buildSurvivalRuleCard(),
                  const SizedBox(height: 24),

                  // 최근 검사 결과 섹션
                  if (latestSurvivalRuleResult != null ||
                      latestBeliefResult != null ||
                      latestSelfConnectionResult != null ||
                      latestEmotionResult != null) ...[
                    _buildLatestResultsSection(
                      latestEmotion: latestEmotionResult,
                      latestSelfConnection: latestSelfConnectionResult,
                      latestBelief: latestBeliefResult,
                      latestSurvivalRule: latestSurvivalRuleResult,
                    ),
                    const SizedBox(height: 28),
                  ],

                  // 검사 기록 히스토리 목록
                  _buildHistorySection(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentBrass.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              color: AppColors.accentBrass,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '내면의 신념을 탐색하고 처방을 받아보세요.',
              style: GoogleFonts.gowunDodum(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionPaletteCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.accentBrass.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '기분 프로파일링',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBrass,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '24개 단어',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '🎨 감정 팔레트 & 마음 지형도',
              style: GoogleFonts.gowunDodum(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '지금 내 마음에 머무는 단어들을 찾아 기분의 지형도를 살핍니다.',
              style: GoogleFonts.gowunDodum(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startEmotionPaletteTest,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.bgDeep,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.inkLine),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow_rounded,
                    size: 20, color: AppColors.accentBrass),
                label: Text(
                  '감정 팔레트 검사 시작',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfConnectionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.accentNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '절대 준거 평가',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '6문항',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '🧭 내면과 관계의 나침반 (자존감 & 외로움)',
              style: GoogleFonts.gowunDodum(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '자존감과 외로움을 연결하여 살핍니다.',
              style: GoogleFonts.gowunDodum(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startSelfConnectionTest,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.bgDeep,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.inkLine),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.explore_outlined,
                    size: 18, color: AppColors.accentNavy),
                label: Text(
                  '나침반 검사 시작하기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeliefTestCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.accentJade.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '신념 인지 재구성',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentJade,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '8문항',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '🛡️ 핵심 신념 탐색 & 삶의 규칙 (CBT)',
              style: GoogleFonts.gowunDodum(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '내 삶의 규칙을 진단하고 유연한 대안 신념을 찾아봅니다.',
              style: GoogleFonts.gowunDodum(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startBeliefTest,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.bgDeep,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.inkLine),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.psychology_outlined,
                    size: 18, color: AppColors.accentJade),
                label: Text(
                  '핵심 신념 검사 시작하기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurvivalRuleCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.accentVermilion.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '방어 메커니즘 & 경직도',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentVermilion,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '6문항',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '📜 삶의 규칙 & 방어 기제 탐색',
              style: GoogleFonts.gowunDodum(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '자신에게 부과한 삶의 규칙을 파악하여 경직성을 완화합니다.',
              style: GoogleFonts.gowunDodum(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startSurvivalRuleTest,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.bgDeep,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.inkLine),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.rule_folder_outlined,
                    size: 18, color: AppColors.accentVermilion),
                label: Text(
                  '삶의 규칙 검사 시작하기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestResultsSection({
    MindTestResult? latestEmotion,
    SelfConnectionTestResult? latestSelfConnection,
    BeliefTestResult? latestBelief,
    SurvivalRuleTestResult? latestSurvivalRule,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 검사 결과',
          style: GoogleFonts.gowunDodum(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (latestSurvivalRule != null) ...[
          _buildLatestSurvivalRuleResultCard(latestSurvivalRule),
          if (latestBelief != null ||
              latestSelfConnection != null ||
              latestEmotion != null)
            const SizedBox(height: 12),
        ],
        if (latestBelief != null) ...[
          _buildLatestBeliefResultCard(latestBelief),
          if (latestSelfConnection != null || latestEmotion != null)
            const SizedBox(height: 12),
        ],
        if (latestSelfConnection != null) ...[
          _buildLatestSelfConnectionResultCard(latestSelfConnection),
          if (latestEmotion != null) const SizedBox(height: 12),
        ],
        if (latestEmotion != null)
          _buildLatestEmotionResultCard(latestEmotion),
      ],
    );
  }

  Widget _buildLatestSurvivalRuleResultCard(SurvivalRuleTestResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentVermilion,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '최근 삶의 규칙 진단',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${result.createdAt.month}월 ${result.createdAt.day}일',
                style: GoogleFonts.gowunDodum(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '📜 ${result.dominantRule.title}',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color:
                            result.rigidityLevel.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${result.rigidityLevel.title} (${result.rigidityScore}점)',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: result.rigidityLevel.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.dominantRule.coreRulePhrase,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentJade.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 13, color: AppColors.accentJade),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          result.dominantRule.flexibleNewRule,
                          style: GoogleFonts.gowunDodum(
                            fontSize: 11.5,
                            color: AppColors.accentJade,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showSurvivalRuleDetailModal(result),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.inkLine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  ),
                  child: Text(
                    '규칙 분석 보기',
                    style: GoogleFonts.gowunDodum(fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onNavigateToRest != null) {
                      widget.onNavigateToRest!(result.prescription.targetMode);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentJade,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    elevation: 0,
                  ),
                  icon: Icon(result.prescription.icon, size: 15),
                  label: Text(
                    '맞춤 쉼터 가기',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestBeliefResultCard(BeliefTestResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentJade,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '최근 핵심 신념 진단',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${result.createdAt.month}월 ${result.createdAt.day}일',
                style: GoogleFonts.gowunDodum(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🛡️ ${result.dominantTemplate.title}',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.accentJade.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${result.dominantTemplate.emoji} ${result.scores[result.dominantTemplate.id] ?? 0}점',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentJade,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.dominantTemplate.intermediateRule,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentJade.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 13, color: AppColors.accentJade),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          result.dominantTemplate.flexibleRule,
                          style: GoogleFonts.gowunDodum(
                            fontSize: 11.5,
                            color: AppColors.accentJade,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showBeliefDetailModal(result),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.inkLine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  ),
                  child: Text(
                    '신념 분석 보기',
                    style: GoogleFonts.gowunDodum(fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onNavigateToRest != null) {
                      widget.onNavigateToRest!(result.prescription.targetMode);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentJade,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    elevation: 0,
                  ),
                  icon: Icon(result.prescription.icon, size: 15),
                  label: Text(
                    '맞춤 쉼터 가기',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestSelfConnectionResultCard(
      SelfConnectionTestResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '최근 나침반 진단 (자존감 & 외로움)',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${result.createdAt.month}월 ${result.createdAt.day}일',
                style: GoogleFonts.gowunDodum(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏞️ ${result.landscapeTitle}',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.landscapeSubtitle,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.accentJade.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🛡️ ${result.selfEsteemType.title}',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentJade,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.accentNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🕊️ ${result.lonelinessLevel.title}',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showSelfConnectionDetailModal(result),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.inkLine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  ),
                  child: Text(
                    '결과 분석 보기',
                    style: GoogleFonts.gowunDodum(fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onNavigateToRest != null) {
                      widget.onNavigateToRest!(result.prescription.targetMode);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentJade,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    elevation: 0,
                  ),
                  icon: Icon(result.prescription.icon, size: 15),
                  label: Text(
                    '맞춤 쉼터 가기',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestEmotionResultCard(MindTestResult result) {
    final topEmotion = result.dominantEmotion;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          topEmotion?.word.tagColor ?? AppColors.accentBrass,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '최근 기분 지형도',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${result.createdAt.month}월 ${result.createdAt.day}일',
                style: GoogleFonts.gowunDodum(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🏞️ ${result.atmosphereTitle}',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (topEmotion != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color:
                              topEmotion.word.tagColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${topEmotion.word.label}',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: topEmotion.word.tagColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.atmosphereDesc,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showResultDetailModal(result),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.inkLine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  ),
                  child: Text(
                    '자세히 보기',
                    style: GoogleFonts.gowunDodum(fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onNavigateToRest != null) {
                      widget.onNavigateToRest!(result.prescription.targetMode);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentJade,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    elevation: 0,
                  ),
                  icon: Icon(result.prescription.icon, size: 15),
                  label: Text(
                    '맞춤 쉼터 가기',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    // 통합 히스토리 리스트 생성
    final List<({DateTime date, Widget widget})> historyItems = [];

    if (_historyFilterIndex == 0 || _historyFilterIndex == 1) {
      for (final res in _results) {
        final top = res.dominantEmotion;
        historyItems.add((
          date: res.createdAt,
          widget: Dismissible(
            key: Key('mind_test_${res.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) async {
              await StorageService.deleteMindTestResult(res.id);
              _loadResults();
            },
            child: InkWell(
              onTap: () => _showResultDetailModal(res),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgPanel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inkLineLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: top?.word.tagColor ?? AppColors.accentBrass,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBrass
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '기분',
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentBrass,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  res.atmosphereTitle,
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${res.createdAt.year}.${res.createdAt.month}.${res.createdAt.day} · ${res.selectedEmotions.map((e) => e.word.label).join(', ')}',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textDim),
                  ],
                ),
              ),
            ),
          ),
        ));
      }
    }

    if (_historyFilterIndex == 0 || _historyFilterIndex == 2) {
      for (final res in _selfConnectionResults) {
        historyItems.add((
          date: res.createdAt,
          widget: Dismissible(
            key: Key('self_conn_${res.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) async {
              await StorageService.deleteSelfConnectionTestResult(res.id);
              _loadResults();
            },
            child: InkWell(
              onTap: () => _showSelfConnectionDetailModal(res),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgPanel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inkLineLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentNavy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentNavy
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '나침반',
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentNavy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  res.landscapeTitle,
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${res.createdAt.year}.${res.createdAt.month}.${res.createdAt.day} · ${res.selfEsteemType.title} · ${res.lonelinessLevel.title}',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textDim),
                  ],
                ),
              ),
            ),
          ),
        ));
      }
    }

    if (_historyFilterIndex == 0 || _historyFilterIndex == 3) {
      for (final res in _beliefResults) {
        historyItems.add((
          date: res.createdAt,
          widget: Dismissible(
            key: Key('belief_${res.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) async {
              await StorageService.deleteBeliefTestResult(res.id);
              _loadResults();
            },
            child: InkWell(
              onTap: () => _showBeliefDetailModal(res),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgPanel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inkLineLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentJade,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentJade
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '핵심신념',
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentJade,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  res.dominantTemplate.title,
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${res.createdAt.year}.${res.createdAt.month}.${res.createdAt.day} · ${res.dominantTemplate.emoji} ${res.scores[res.dominantTemplate.id] ?? 0}점 · ${res.dominantTemplate.coreFear}',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textDim),
                  ],
                ),
              ),
            ),
          ),
        ));
      }
    }

    if (_historyFilterIndex == 0 || _historyFilterIndex == 4) {
      for (final res in _survivalRuleResults) {
        historyItems.add((
          date: res.createdAt,
          widget: Dismissible(
            key: Key('survival_${res.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) async {
              await StorageService.deleteSurvivalRuleTestResult(res.id);
              _loadResults();
            },
            child: InkWell(
              onTap: () => _showSurvivalRuleDetailModal(res),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgPanel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inkLineLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentVermilion,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentVermilion
                                      .withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '삶의규칙',
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentVermilion,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  res.dominantRule.title,
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${res.createdAt.year}.${res.createdAt.month}.${res.createdAt.day} · ${res.rigidityLevel.title} (${res.rigidityScore}점) · ${res.dominantRule.coreRulePhrase}',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textDim),
                  ],
                ),
              ),
            ),
          ),
        ));
      }
    }

    historyItems.sort((a, b) => b.date.compareTo(a.date));

    final filterLabels = ['전체', '기분', '자존감·외로움', '핵심신념', '삶의규칙'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '내 마음의 기록',
              style: GoogleFonts.gowunDodum(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            // 필터 세그먼트
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(filterLabels.length, (idx) {
                  final isSelected = _historyFilterIndex == idx;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _historyFilterIndex = idx;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentNavy
                            : AppColors.bgPanel2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentNavy
                              : AppColors.inkLineLight,
                        ),
                      ),
                      child: Text(
                        filterLabels[idx],
                        style: GoogleFonts.gowunDodum(
                          fontSize: 10.5,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (historyItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.bgPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: Center(
              child: Text(
                '해당 분류의 검사 기록이 아직 없습니다.',
                style: GoogleFonts.gowunDodum(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historyItems.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) => historyItems[index].widget,
          ),
      ],
    );
  }
}

/// 감정 팔레트 검사 2-Step 진행 모달
class _EmotionPaletteFlowModal extends StatefulWidget {
  final Future<void> Function(MindTestResult result) onCompleted;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final VoidCallback? onNavigateToDiary;

  const _EmotionPaletteFlowModal({
    required this.onCompleted,
    this.onNavigateToRest,
    this.onNavigateToDiary,
  });

  @override
  State<_EmotionPaletteFlowModal> createState() =>
      _EmotionPaletteFlowModalState();
}

class _EmotionPaletteFlowModalState extends State<_EmotionPaletteFlowModal> {
  int _step = 1; // 1: 감정 선택, 2: 강도 조율, 3: 결과 화면
  final List<SelectedEmotion> _selectedEmotions = [];
  MindTestResult? _result;

  void _toggleEmotion(EmotionWord word) {
    final idx = _selectedEmotions.indexWhere((e) => e.word.id == word.id);
    setState(() {
      if (idx >= 0) {
        _selectedEmotions.removeAt(idx);
      } else {
        if (_selectedEmotions.length < 5) {
          _selectedEmotions.add(SelectedEmotion(word: word, intensity: 2));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '감정은 최대 5개까지 선택할 수 있습니다.',
                style: GoogleFonts.gowunDodum(),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _updateIntensity(EmotionWord word, int intensity) {
    setState(() {
      final idx = _selectedEmotions.indexWhere((e) => e.word.id == word.id);
      if (idx >= 0) {
        _selectedEmotions[idx] =
            SelectedEmotion(word: word, intensity: intensity);
      }
    });
  }

  void _completeTest() async {
    final res = MindTestResult.analyze(_selectedEmotions);
    setState(() {
      _result = res;
      _step = 3;
    });
    await widget.onCompleted(res);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 모달 핸들
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inkLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // 스텝 인디케이터 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _step == 1
                        ? '1단계: 지금 마음에 와닿는 감정'
                        : _step == 2
                            ? '2단계: 감정의 깊이 조율'
                            : '마음 분석 결과',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_step < 3)
                    Text(
                      '$_step / 2',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 13,
                        color: AppColors.accentBrass,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.inkLine, height: 1),

            // 메인 바디 영역
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _step == 1
                    ? _buildStep1SelectEmotions()
                    : _step == 2
                        ? _buildStep2Intensity()
                        : _buildStep3ResultView(_result!),
              ),
            ),

            // 하단 조작 버튼
            if (_step < 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    if (_step == 2)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step = 1),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side:
                                const BorderSide(color: AppColors.inkLineLight),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '이전',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (_step == 2) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedEmotions.isEmpty
                            ? null
                            : () {
                                if (_step == 1) {
                                  setState(() => _step = 2);
                                } else {
                                  _completeTest();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBrass,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.inkLine.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _step == 1
                              ? '다음 (${_selectedEmotions.length}개 선택)'
                              : '진단 결과 확인하기',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1SelectEmotions() {
    final domainMap = {
      EmotionCategory.vitality: (
        title: '✨ 활력·열정 (고각성 긍정)',
        color: AppColors.accentBrass,
      ),
      EmotionCategory.peace: (
        title: '🌿 평온·충전 (저각성 긍정)',
        color: AppColors.accentJade,
      ),
      EmotionCategory.tension: (
        title: '⚡ 긴장·부담 (고각성 부정)',
        color: AppColors.accentVermilion,
      ),
      EmotionCategory.depletion: (
        title: '🌧️ 방전·소진 (저각성 부정)',
        color: AppColors.accentNavy,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘 마음에 가장 뚜렷하게 남는 단어를 1~5개 선택해주세요.',
          style: GoogleFonts.gowunDodum(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        ...EmotionCategory.values.map((cat) {
          final info = domainMap[cat]!;
          final wordsInCat =
              EmotionWord.defaultWords.where((w) => w.category == cat).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.title,
                style: GoogleFonts.gowunDodum(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: info.color,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: wordsInCat.map((w) {
                  final isSelected =
                      _selectedEmotions.any((e) => e.word.id == w.id);
                  return FilterChip(
                    label: Text(w.label),
                    selected: isSelected,
                    onSelected: (_) => _toggleEmotion(w),
                    labelStyle: GoogleFonts.gowunDodum(
                      fontSize: 12.5,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.bgPanel2,
                    selectedColor: info.color,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? info.color
                            : AppColors.inkLineLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStep2Intensity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선택하신 감정이 얼마나 강하게 느껴지는지 조율해 주세요.',
          style: GoogleFonts.gowunDodum(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ..._selectedEmotions.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgPanel2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: item.word.tagColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.word.label,
                          style: GoogleFonts.gowunDodum(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBrass.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.intensityLabel,
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBrass,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accentBrass,
                    inactiveTrackColor: AppColors.inkLine,
                    thumbColor: AppColors.accentBrass,
                    overlayColor: AppColors.accentBrass.withValues(alpha: 0.2),
                    valueIndicatorColor: AppColors.accentBrass,
                    valueIndicatorTextStyle:
                        GoogleFonts.gowunDodum(color: Colors.white),
                  ),
                  child: Slider(
                    value: item.intensity.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label: '${item.intensity}단계',
                    onChanged: (val) =>
                        _updateIntensity(item.word, val.round()),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep3ResultView(MindTestResult result) {
    final dominant = result.dominantEmotion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 진단 결과 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgPanel2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentBrass.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Text(
                '🗺️ ${result.atmosphereTitle}',
                style: GoogleFonts.gowunDodum(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              if (dominant != null)
                Text(
                  '주요 감정: ${dominant.word.label} (${dominant.word.categoryLabel})',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentBrass,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                result.atmosphereDesc,
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunDodum(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.dynamicsMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunDodum(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 처방 카드
        Text(
          '🌿 맞춤 마음 처방',
          style: GoogleFonts.gowunDodum(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgPanel2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inkLineLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(result.prescription.icon,
                      color: AppColors.accentJade, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.prescription.title,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.prescription.reason,
                style: GoogleFonts.gowunDodum(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 액션 버튼 (쉼터 이동 / 닫기)
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.onNavigateToDiary != null) {
                    widget.onNavigateToDiary!();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.inkLineLight),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '감정 일기 쓰기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.onNavigateToRest != null) {
                    widget.onNavigateToRest!(result.prescription.targetMode);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentJade,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: Icon(result.prescription.icon, size: 17),
                label: Text(
                  '맞춤 쉼터 가기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 감정 팔레트 검사 결과 상세 보기 시트
class _ResultDetailSheet extends StatelessWidget {
  final MindTestResult result;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final VoidCallback? onNavigateToDiary;

  const _ResultDetailSheet({
    required this.result,
    this.onNavigateToRest,
    this.onNavigateToDiary,
  });

  @override
  Widget build(BuildContext context) {
    final dominant = result.dominantEmotion;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 모달 핸들
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inkLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '감정 팔레트 기록 상세',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.inkLine, height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 검사 일자 배너
                    Center(
                      child: Text(
                        '${result.createdAt.year}년 ${result.createdAt.month}월 ${result.createdAt.day}일 검사',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 감정 배지 요약
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.bgPanel2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentBrass.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🗺️ ${result.atmosphereTitle}',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (dominant != null)
                            Text(
                              '주요 감정: ${dominant.word.label} (${dominant.word.categoryLabel})',
                              style: GoogleFonts.gowunDodum(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentBrass,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            result.atmosphereDesc,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.gowunDodum(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 선택된 감정 목록
                    Text(
                      '선택했던 감정 단어들',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: result.selectedEmotions.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.bgPanel2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.inkLineLight),
                          ),
                          child: Text(
                            '${e.word.label} (${e.intensityLabel})',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 처방 요약
                    Text(
                      '🌿 맞춤 쉼터 처방',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgPanel2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inkLineLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.prescription.title,
                            style: GoogleFonts.gowunDodum(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.prescription.reason,
                            style: GoogleFonts.gowunDodum(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 버튼들
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (onNavigateToDiary != null) {
                                onNavigateToDiary!();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(
                                  color: AppColors.inkLineLight),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              '감정 일기 쓰기',
                              style: GoogleFonts.gowunDodum(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              if (onNavigateToRest != null) {
                                onNavigateToRest!(
                                    result.prescription.targetMode);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentJade,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: Icon(result.prescription.icon, size: 16),
                            label: Text(
                              '맞춤 쉼터 가기',
                              style: GoogleFonts.gowunDodum(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

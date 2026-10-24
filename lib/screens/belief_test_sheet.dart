import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/belief_model.dart';
import '../models/belief_test_model.dart';
import '../models/quote.dart';
import '../screens/rest_tab.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// 핵심신념 검사 플로우 모달 (원터치 자동 전환, 수정 불가)
class BeliefTestFlowModal extends StatefulWidget {
  final Future<void> Function(BeliefTestResult result) onCompleted;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;

  const BeliefTestFlowModal({
    super.key,
    required this.onCompleted,
    this.onNavigateToRest,
    this.onNavigateToDiaryWithQuote,
    this.onNavigateToDiary,
  });

  @override
  State<BeliefTestFlowModal> createState() => _BeliefTestFlowModalState();
}

class _BeliefTestFlowModalState extends State<BeliefTestFlowModal> {
  final List<BeliefTestQuestion> _questions =
      BeliefTestQuestion.defaultQuestions;
  final Map<String, BeliefTestOption> _selectedAnswers = {};
  int _currentIndex = 0;
  bool _isAnalyzing = false;
  bool _isTransitioning = false;
  BeliefTestResult? _result;

  void _selectOption(
      BeliefTestQuestion question, BeliefTestOption option) async {
    if (_isTransitioning || _isAnalyzing) return;

    setState(() {
      _isTransitioning = true;
      _selectedAnswers[question.id] = option;
    });

    // 선택 시각 피드백 후 즉시 다음 문항으로 자동 이동 (수정 불가)
    await Future.delayed(const Duration(milliseconds: 230));
    if (!mounted) return;

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isTransitioning = false;
      });
    } else {
      // 마지막 문항 완료 -> 즉시 분석
      setState(() {
        _isAnalyzing = true;
      });

      final answers = _questions.map((q) {
        return BeliefTestAnswer(
          questionId: q.id,
          option: _selectedAnswers[q.id] ?? q.options.first,
        );
      }).toList();

      final res = BeliefTestResult.analyze(answers);
      await widget.onCompleted(res);

      if (mounted) {
        setState(() {
          _result = res;
          _isAnalyzing = false;
          _isTransitioning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: _result != null
            ? Column(
                children: [
                  _buildHeader(title: '핵심 신념 진단 & 처방 결과'),
                  const Divider(height: 1, color: AppColors.inkLine),
                  Expanded(
                    child: BeliefTestResultDetailContent(
                      result: _result!,
                      onNavigateToRest: widget.onNavigateToRest,
                      onNavigateToDiaryWithQuote: widget.onNavigateToDiaryWithQuote,
                      onNavigateToDiary: widget.onNavigateToDiary,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildHeader(
                    title: '🛡️ 핵심 신념 탐색 (문항 ${_currentIndex + 1}/${_questions.length})',
                  ),
                  const Divider(height: 1, color: AppColors.inkLine),
                  Expanded(
                    child: _isAnalyzing
                        ? _buildAnalyzingView()
                        : _buildQuestionStep(_questions[_currentIndex]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader({required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.gowunDodum(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accentVermilion),
          const SizedBox(height: 18),
          Text(
            '무의식 속에 숨겨진 8가지 생존 규칙과\n핵심 두려움을 분석하고 있습니다...',
            textAlign: TextAlign.center,
            style: GoogleFonts.gowunDodum(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStep(BeliefTestQuestion question) {
    final selectedOption = _selectedAnswers[question.id];
    final progress = (_currentIndex + 1) / _questions.length;
    const themeColor = AppColors.accentVermilion;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.inkLineLight,
          valueColor: const AlwaysStoppedAnimation<Color>(themeColor),
          minHeight: 3.5,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '🛡️ 상황: ${question.categoryTag}',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 질문 타이틀 & 서브타이틀
                Text(
                  question.title,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 17.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question.subtitle,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),

                // 선택지 목록 (4지선다 자동 전환)
                ...question.options.map((option) {
                  final isSelected = selectedOption?.id == option.id;

                  return GestureDetector(
                    onTap: () => _selectOption(question, option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeColor.withValues(alpha: 0.08)
                            : AppColors.bgPanel,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? themeColor : AppColors.inkLine,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            color: isSelected ? themeColor : AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option.text,
                              style: GoogleFonts.gowunDodum(
                                fontSize: 13.5,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                height: 1.45,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // 하단 안내 영역
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_outlined,
                  size: 15, color: themeColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '답변을 선택하면 바로 다음 문항으로 이동합니다 (수정 불가)',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 핵심신념 검사 결과 상세 시트 (모달 바텀시트용)
class BeliefTestResultDetailSheet extends StatelessWidget {
  final BeliefTestResult result;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;

  const BeliefTestResultDetailSheet({
    super.key,
    required this.result,
    this.onNavigateToRest,
    this.onNavigateToDiaryWithQuote,
    this.onNavigateToDiary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '핵심 신념 진단 & 처방 결과',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.inkLine),
          Expanded(
            child: BeliefTestResultDetailContent(
              result: result,
              onNavigateToRest: onNavigateToRest,
              onNavigateToDiaryWithQuote: onNavigateToDiaryWithQuote,
              onNavigateToDiary: onNavigateToDiary,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 핵심신념 검사 결과 상세 내용 위젯
class BeliefTestResultDetailContent extends StatelessWidget {
  final BeliefTestResult result;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;

  const BeliefTestResultDetailContent({
    super.key,
    required this.result,
    this.onNavigateToRest,
    this.onNavigateToDiaryWithQuote,
    this.onNavigateToDiary,
  });

  @override
  Widget build(BuildContext context) {
    final dom = result.dominantTemplate;
    final sec = result.secondaryTemplate;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 핵심 신념 헤더 카드
          _buildBeliefHeaderCard(dom, sec),
          const SizedBox(height: 18),

          // 2. 무의식 생존 규칙 & 두려움 해체 카드
          _buildRuleAndFearCard(dom),
          const SizedBox(height: 18),

          // 3. 유연한 새로운 대처 규칙 카드
          _buildFlexibleRuleCard(dom),
          const SizedBox(height: 18),

          // 4. 3분 마음 행동 실험 카드
          _buildActionExperimentCard(context, dom),
          const SizedBox(height: 18),

          // 5. 8대 신념 스펙트럼 랭킹 분포
          _buildBeliefRankingSection(),
          const SizedBox(height: 18),

          // 6. 맞춤 마음 처방 액션 카드
          _buildPrescriptionCard(context),
          const SizedBox(height: 18),

          // 7. 감성 큐레이션 선물 카드
          _buildCurationCard(context),
          const SizedBox(height: 24),

          // 8. 다이어리 기록 연계 버튼
          if (onNavigateToDiary != null || onNavigateToDiaryWithQuote != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onNavigateToDiaryWithQuote != null) {
                    final quote = Quote(
                      id: DateTime.now().millisecondsSinceEpoch % 100000,
                      source: '핵심 신념 진단',
                      original: '',
                      reading: '',
                      english: '',
                      translation: '${dom.emoji} ${dom.title} 신념 탐색',
                      commentary:
                          '생존 규칙: ${dom.intermediateRule}\n\n새로운 규칙: ${dom.flexibleRule}\n\n행동 실험: ${dom.actionExperiment}',
                      mood: 'peaceful',
                    );
                    onNavigateToDiaryWithQuote!(quote);
                  } else if (onNavigateToDiary != null) {
                    onNavigateToDiary!();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentVermilion,
                  side: BorderSide(color: AppColors.accentVermilion.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: Text(
                  '이 성찰을 다이어리에 기록하기',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildBeliefHeaderCard(BeliefTemplate dom, BeliefTemplate? sec) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgPanel,
            AppColors.accentVermilion.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentVermilion.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentVermilion.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '주요 핵심 신념',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentVermilion,
                  ),
                ),
              ),
              Text(
                '${result.createdAt.year}.${result.createdAt.month}.${result.createdAt.day}',
                style: GoogleFonts.gowunDodum(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(dom.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dom.title,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (sec != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '부 신념: ${sec.emoji} ${sec.title}',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dom.description,
            style: GoogleFonts.gowunDodum(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleAndFearCard(BeliefTemplate dom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 18, color: AppColors.accentBrass),
              const SizedBox(width: 8),
              Text(
                '내가 고수해 온 생존 규칙 (중간신념)',
                style: GoogleFonts.gowunDodum(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentBrass.withValues(alpha: 0.3)),
            ),
            child: Text(
              '"${dom.intermediateRule}"',
              style: GoogleFonts.gowunDodum(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.lock_open_outlined,
                  size: 18, color: AppColors.accentVermilion),
              const SizedBox(width: 8),
              Text(
                '규칙 밑에 숨겨진 무의식적 두려움 (핵심신념)',
                style: GoogleFonts.gowunDodum(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentVermilion.withValues(alpha: 0.3)),
            ),
            child: Text(
              '"${dom.coreFear}"',
              style: GoogleFonts.gowunDodum(
                fontSize: 13,
                color: AppColors.accentVermilion,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlexibleRuleCard(BeliefTemplate dom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentJade.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_outlined,
                  size: 18, color: AppColors.accentJade),
              const SizedBox(width: 8),
              Text(
                '🌿 새로운 유연한 대처 규칙 (적응적 신념)',
                style: GoogleFonts.gowunDodum(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              dom.flexibleRule,
              style: GoogleFonts.gowunDodum(
                fontSize: 13.5,
                color: AppColors.accentJade,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionExperimentCard(BuildContext context, BeliefTemplate dom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_outlined,
                  size: 18, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                '⚡ 오늘 시도해 볼 3분 마음 행동 실험',
                style: GoogleFonts.gowunDodum(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dom.actionExperiment,
            style: GoogleFonts.gowunDodum(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final entry = UserBeliefEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: dom.title,
                  emoji: dom.emoji,
                  intermediateRule: dom.intermediateRule,
                  coreFear: dom.coreFear,
                  flexibleRule: dom.flexibleRule,
                  actionExperiment: dom.actionExperiment,
                  createdAt: DateTime.now(),
                  sourceThought: '핵심신념 검사 결과',
                );
                await StorageService.saveUserBelief(entry);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${dom.emoji} ${dom.title} 신념이 내 신념 노트에 등록되었습니다 📖',
                      style: GoogleFonts.gowunDodum(color: Colors.white, fontSize: 13),
                    ),
                    backgroundColor: AppColors.accentJade,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: Text(
                '이 신념을 내 신념 노트에 저장하기',
                style: GoogleFonts.gowunDodum(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeliefRankingSection() {
    final sorted = result.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxScore = sorted.isNotEmpty ? sorted.first.value : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '8대 핵심 신념 활성화 분포',
            style: GoogleFonts.gowunDodum(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((e) {
            final t = BeliefTemplate.presets.firstWhere(
              (p) => p.id == e.key,
              orElse: () => BeliefTemplate.presets.first,
            );
            final ratio = maxScore > 0 ? (e.value / maxScore) : 0.0;
            final isTop = t.id == result.dominantTemplate.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${t.emoji} ${t.title}',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 11.5,
                        fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                        color: isTop ? AppColors.accentVermilion : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.05, 1.0),
                        backgroundColor: AppColors.bgDeep,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isTop
                              ? AppColors.accentVermilion
                              : AppColors.accentBrass.withValues(alpha: 0.5),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context) {
    final presc = result.prescription;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentJade.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentJade.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🌿 추천 마음 처방',
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inkLine),
                ),
                child: Icon(presc.icon, color: AppColors.accentJade, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presc.title,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      presc.reason,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                if (onNavigateToRest != null) {
                  onNavigateToRest!(presc.targetMode);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentJade,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: Icon(presc.icon, size: 16),
              label: Text(
                presc.actionLabel,
                style: GoogleFonts.gowunDodum(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurationCard(BuildContext context) {
    final cur = result.curation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBrassSoft.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentBrass.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🎁 오늘의 마음 케어 추천',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentBrass,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '#${cur.tag}',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inkLine),
                ),
                child: Icon(cur.icon, color: AppColors.accentBrass, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cur.title,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cur.subtitle,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 ${cur.recommendationReason}',
              style: GoogleFonts.gowunDodum(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/belief_model.dart';
import '../models/quote.dart';
import '../models/survival_rule_test_model.dart';
import '../screens/rest_tab.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// 삶의 규칙 검사 플로우 모달 (원터치 자동 전환, 수정 불가)
class SurvivalRuleFlowModal extends StatefulWidget {
  final Future<void> Function(SurvivalRuleTestResult result) onCompleted;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;

  const SurvivalRuleFlowModal({
    super.key,
    required this.onCompleted,
    this.onNavigateToRest,
    this.onNavigateToDiaryWithQuote,
    this.onNavigateToDiary,
  });

  @override
  State<SurvivalRuleFlowModal> createState() => _SurvivalRuleFlowModalState();
}

class _SurvivalRuleFlowModalState extends State<SurvivalRuleFlowModal> {
  final List<SurvivalRuleQuestion> _questions =
      SurvivalRuleQuestion.defaultQuestions;
  final Map<String, SurvivalRuleOption> _selectedAnswers = {};
  int _currentIndex = 0;
  bool _isAnalyzing = false;
  bool _isTransitioning = false;
  SurvivalRuleTestResult? _result;

  void _selectOption(
      SurvivalRuleQuestion question, SurvivalRuleOption option) async {
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
        return SurvivalRuleAnswer(
          questionId: q.id,
          option: _selectedAnswers[q.id] ?? q.options.first,
        );
      }).toList();

      final res = SurvivalRuleTestResult.analyze(answers);
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
                  _buildHeader(title: '삶의 규칙 진단 & 완화 처방 결과'),
                  const Divider(height: 1, color: AppColors.inkLine),
                  Expanded(
                    child: SurvivalRuleResultDetailContent(
                      result: _result!,
                      onNavigateToRest: widget.onNavigateToRest,
                      onNavigateToDiaryWithQuote: widget.onNavigateToDiaryWithQuote,
                      onNavigateToDiary: widget.onNavigateToDiary,
                    ),
                  ),
                ],
              )
            : _isAnalyzing
                ? _buildAnalyzingView()
                : _buildQuestionView(),
      ),
    );
  }

  Widget _buildHeader({required String title}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.gowunDodum(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFFF97316),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '내면의 방어 규칙과 경직도를 분석하고 있습니다...',
            style: GoogleFonts.gowunDodum(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '나를 지켜주었던 규칙 뒤에 숨겨진 진실을 만납니다.',
            style: GoogleFonts.gowunDodum(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    final question = _questions[_currentIndex];
    final selectedOption = _selectedAnswers[question.id];
    final progress = (_currentIndex + 1) / _questions.length;
    const themeColor = AppColors.accentVermilion;

    return Column(
      children: [
        _buildHeader(title: '생존 규칙 탐색 검사'),
        const Divider(height: 1, color: AppColors.inkLine),

        // 프로그레스 바
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '문항 ${_currentIndex + 1} / ${_questions.length}',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% 완료',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.bgPanel2,
                  valueColor: const AlwaysStoppedAnimation<Color>(themeColor),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),

        // 질문 영역
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상황 태그
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '🛡️ ${question.situationTitle}',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 질문 프롬프트
                Text(
                  question.questionPrompt,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question.dilemmaContext,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

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
                            : [],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? themeColor : AppColors.textDim,
                                width: 2,
                              ),
                              color: isSelected ? themeColor : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 15, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              option.text,
                              style: GoogleFonts.gowunDodum(
                                fontSize: 13.5,
                                height: 1.45,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
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

        // 하단 안내
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_outlined, size: 15, color: themeColor),
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

/// 생존 규칙 검사 결과 상세 시트 (모달 바텀시트용)
class SurvivalRuleResultDetailSheet extends StatelessWidget {
  final SurvivalRuleTestResult result;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;

  const SurvivalRuleResultDetailSheet({
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
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '생존 규칙 진단 & 완화 처방',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.inkLine),
            Expanded(
              child: SurvivalRuleResultDetailContent(
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

/// 생존 규칙 결과 상세 내용 뷰
class SurvivalRuleResultDetailContent extends StatelessWidget {
  final SurvivalRuleTestResult result;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;

  const SurvivalRuleResultDetailContent({
    super.key,
    required this.result,
    this.onNavigateToRest,
    this.onNavigateToDiaryWithQuote,
    this.onNavigateToDiary,
  });

  @override
  Widget build(BuildContext context) {
    final dom = result.dominantRule;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 도미넌트 생존 규칙 배너
          _buildDominantRuleHeader(dom),
          const SizedBox(height: 18),

          // 2. 규칙 경직도 게이지 & 분석
          _buildRigidityGaugeCard(),
          const SizedBox(height: 18),

          // 3. 규칙의 과거 기원과 현재의 대가 분해
          _buildOriginAndCostCard(dom),
          const SizedBox(height: 18),

          // 4. 생존 규칙 완화 3단계 처방 (핵심 리포트)
          _buildThreeStepReframingCard(context, dom),
          const SizedBox(height: 18),

          // 5. 6대 생존 규칙 방어 스펙트럼 랭킹
          _buildArchetypeSpectrumCard(),
          const SizedBox(height: 18),

          // 6. 맞춤 쉼터 처방
          _buildPrescriptionCard(context),
          const SizedBox(height: 18),

          // 7. 감성 큐레이션 선물
          _buildCurationCard(),
          const SizedBox(height: 24),

          // 8. 내 신념/규칙 노트에 저장하기 버튼
          _buildSaveToNoteButton(context, dom),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDominantRuleHeader(SurvivalRuleProfile dom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgPanel,
            const Color(0xFFF97316).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dom.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '나의 주된 생존 규칙',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dom.title,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inkLineLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📜 ', style: TextStyle(fontSize: 15)),
                Expanded(
                  child: Text(
                    dom.coreRulePhrase,
                    style: GoogleFonts.gowunDodum(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.45,
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

  Widget _buildRigidityGaugeCard() {
    final level = result.rigidityLevel;
    final score = result.rigidityScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '규칙 경직도 지수',
                style: GoogleFonts.gowunDodum(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: level.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${level.title} ($score점)',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: level.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.bgDeep,
              valueColor: AlwaysStoppedAnimation<Color>(level.color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('유연한 적응 (0)',
                  style: GoogleFonts.gowunDodum(
                      fontSize: 11, color: AppColors.textMuted)),
              Text('주의적 긴장 (50)',
                  style: GoogleFonts.gowunDodum(
                      fontSize: 11, color: AppColors.textMuted)),
              Text('만성적 과부하 (100)',
                  style: GoogleFonts.gowunDodum(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            level.description,
            style: GoogleFonts.gowunDodum(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginAndCostCard(SurvivalRuleProfile dom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔍 생존 규칙의 기원과 대가',
            style: GoogleFonts.gowunDodum(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // 과거의 방패 (기원)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentJade.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accentJade.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 16, color: AppColors.accentJade),
                    const SizedBox(width: 6),
                    Text(
                      '과거 나를 지켜준 방패 (기여와 순기능)',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentJade,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dom.protectionOrigin,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 현재의 대가 (비용)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentVermilion.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accentVermilion.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link_off,
                        size: 16, color: AppColors.accentVermilion),
                    const SizedBox(width: 6),
                    Text(
                      '현재 나에게 치르게 하는 대가 (피로와 한계)',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentVermilion,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dom.currentCost,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeStepReframingCard(
      BuildContext context, SurvivalRuleProfile dom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 18, color: Color(0xFFF97316)),
              ),
              const SizedBox(width: 10),
              Text(
                '🌿 규칙 완화 3단계 실천 처방',
                style: GoogleFonts.gowunDodum(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1단계: 알아차림 구호
          _buildStepItem(
            stepNumber: '1',
            stepTitle: '알아차림 구호 (Anchor Phrase)',
            stepDesc: '규칙이 나를 지배하려 할 때 속으로 가볍게 읊조려 줍니다.',
            content: dom.awarenessPhrase,
            badgeColor: const Color(0xFFF97316),
          ),
          const SizedBox(height: 12),

          // 2단계: 작은 예외 허용 실험
          _buildStepItem(
            stepNumber: '2',
            stepTitle: '작은 예외 허용 실험 (3분 실천)',
            stepDesc: '규칙의 완벽한 통제에서 살짝 벗어나는 안전한 예외를 시도합니다.',
            content: dom.exceptionExperiment,
            badgeColor: AppColors.accentJade,
          ),
          const SizedBox(height: 12),

          // 3단계: 새로운 유연한 규칙
          _buildStepItem(
            stepNumber: '3',
            stepTitle: '새로운 유연한 규칙 (Adaptive Rule)',
            stepDesc: '나를 옥죄던 당위 명제를 대신할 숨 쉴 수 있는 새 규칙입니다.',
            content: dom.flexibleNewRule,
            badgeColor: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String stepTitle,
    required String stepDesc,
    required String content,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
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
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stepTitle,
                style: GoogleFonts.gowunDodum(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stepDesc,
            style: GoogleFonts.gowunDodum(
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              content,
              style: GoogleFonts.gowunDodum(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchetypeSpectrumCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 6대 생존 규칙 방어 스펙트럼',
            style: GoogleFonts.gowunDodum(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...SurvivalRuleType.values.map((type) {
            final profile = SurvivalRuleProfile.profiles[type]!;
            final count = result.archetypeScores[type] ?? 0;
            final isDominant = type == result.dominantRule.type;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(profile.emoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            profile.title,
                            style: GoogleFonts.gowunDodum(
                              fontSize: 12.5,
                              fontWeight: isDominant
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isDominant
                                  ? const Color(0xFFF97316)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$count점',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDominant
                              ? const Color(0xFFF97316)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (count / 6).clamp(0.0, 1.0),
                      backgroundColor: AppColors.bgDeep,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDominant
                            ? const Color(0xFFF97316)
                            : AppColors.inkLine,
                      ),
                      minHeight: 6,
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
    final p = result.prescription;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentJade.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(p.icon, size: 20, color: AppColors.accentJade),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '맞춤 쉼표 처방',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 11.5,
                        color: AppColors.accentJade,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      p.title,
                      style: GoogleFonts.gowunDodum(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.reason,
            style: GoogleFonts.gowunDodum(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                if (onNavigateToRest != null) {
                  onNavigateToRest!(p.targetMode);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentJade,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                p.actionLabel,
                style: GoogleFonts.gowunDodum(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurationCard() {
    final c = result.curation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentBrass.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(c.icon, size: 22, color: AppColors.accentBrass),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBrass.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c.categoryLabel,
                        style: GoogleFonts.gowunDodum(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBrass,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#${c.tag}',
                      style: GoogleFonts.gowunDodum(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.title,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  c.subtitle,
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
    );
  }

  Widget _buildSaveToNoteButton(BuildContext context, SurvivalRuleProfile dom) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final userBelief = UserBeliefEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            createdAt: DateTime.now(),
            title: dom.title,
            emoji: dom.emoji,
            intermediateRule: dom.coreRulePhrase,
            coreFear: dom.protectionOrigin,
            flexibleRule: dom.flexibleNewRule,
            actionExperiment: dom.exceptionExperiment,
            sourceThought: '생존 규칙 검사를 통해 진단된 규칙 완화 처방입니다.',
          );

          await StorageService.saveUserBelief(userBelief);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '내 신념/규칙 노트에 성공적으로 저장되었습니다 🌿',
                  style: GoogleFonts.gowunDodum(),
                ),
                backgroundColor: AppColors.accentJade,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF97316),
          side: const BorderSide(color: Color(0xFFF97316), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.bookmark_add_outlined, size: 19),
        label: Text(
          '내 신념·생존 규칙 노트에 저장하기',
          style: GoogleFonts.gowunDodum(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

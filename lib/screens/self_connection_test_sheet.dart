import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quote.dart';
import '../models/self_connection_test_model.dart';
import '../screens/rest_tab.dart';
import '../theme/app_theme.dart';

/// 자존감 & 외로움 절대 평가 검사 플로우 모달
class SelfConnectionFlowModal extends StatefulWidget {
  final Future<void> Function(SelfConnectionTestResult result) onCompleted;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;

  const SelfConnectionFlowModal({
    super.key,
    required this.onCompleted,
    this.onNavigateToRest,
    this.onNavigateToDiaryWithQuote,
    this.onNavigateToDiary,
  });

  @override
  State<SelfConnectionFlowModal> createState() =>
      _SelfConnectionFlowModalState();
}

class _SelfConnectionFlowModalState extends State<SelfConnectionFlowModal> {
  final List<SelfConnectionQuestion> _questions =
      SelfConnectionQuestion.defaultQuestions;
  final Map<String, SelfConnectionOption> _selectedAnswers = {};
  int _currentIndex = 0;
  bool _isAnalyzing = false;
  bool _isTransitioning = false;
  SelfConnectionTestResult? _result;

  void _selectOption(
      SelfConnectionQuestion question, SelfConnectionOption option) async {
    if (_isTransitioning || _isAnalyzing) return;

    setState(() {
      _isTransitioning = true;
      _selectedAnswers[question.id] = option;
    });

    // 선택 시각 피드백을 위한 미세 딜레이 (선택 즉시 다음으로 자동 이동)
    await Future.delayed(const Duration(milliseconds: 230));
    if (!mounted) return;

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isTransitioning = false;
      });
    } else {
      _completeAnalysis();
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isTransitioning = false;
      });
    }
  }

  void _goToNext() {
    if (_selectedAnswers.containsKey(_questions[_currentIndex].id)) {
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _isTransitioning = false;
        });
      } else {
        _completeAnalysis();
      }
    }
  }

  void _completeAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    final answers = _questions.map((q) {
      return SelfConnectionAnswer(
        questionId: q.id,
        option: _selectedAnswers[q.id] ?? q.options.first,
      );
    }).toList();

    final res = SelfConnectionTestResult.analyze(answers);
    await widget.onCompleted(res);

    if (mounted) {
      setState(() {
        _result = res;
        _isAnalyzing = false;
        _isTransitioning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: AppColors.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _result != null
            ? Column(
                children: [
                  _buildHeader(title: '내면과 관계의 나침반 결과'),
                  const Divider(height: 1, color: AppColors.inkLine),
                  Expanded(
                    child: SelfConnectionResultDetailContent(
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
                    title: '🧭 내면 & 관계의 나침반 (문항 ${_currentIndex + 1}/${_questions.length})',
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
          const CircularProgressIndicator(color: AppColors.accentBrass),
          const SizedBox(height: 18),
          Text(
            '내면의 3대 기둥과 연결감 스펙트럼을\n절대 기준으로 분석하고 있습니다...',
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

  Widget _buildQuestionStep(SelfConnectionQuestion question) {
    final selectedOption = _selectedAnswers[question.id];
    final progress = (_currentIndex + 1) / _questions.length;

    String domainLabel = '';
    Color domainColor = AppColors.accentBrass;
    if (question.isSelfEsteem) {
      switch (question.domain as SelfEsteemDomain) {
        case SelfEsteemDomain.selfAcceptance:
          domainLabel = '🌱 자존감 기둥 1: 자기 수용';
          domainColor = AppColors.accentJade;
          break;
        case SelfEsteemDomain.selfEfficacy:
          domainLabel = '⚡ 자존감 기둥 2: 자기 신뢰';
          domainColor = AppColors.accentBrass;
          break;
        case SelfEsteemDomain.selfBoundaries:
          domainLabel = '🛡️ 자존감 기둥 3: 자기 경계';
          domainColor = AppColors.accentVermilion;
          break;
      }
    } else {
      switch (question.domain as LonelinessDomain) {
        case LonelinessDomain.intimateConnection:
          domainLabel = '🕊️ 연결감 지표 1: 정서적 친밀감';
          domainColor = AppColors.accentNavy;
          break;
        case LonelinessDomain.socialConnection:
          domainLabel = '🌿 연결감 지표 2: 사회적 소속감';
          domainColor = AppColors.accentJade;
          break;
        case LonelinessDomain.solitudePower:
          domainLabel = '🌙 연결감 지표 3: 고독 자생력';
          domainColor = AppColors.accentBrass;
          break;
      }
    }

    return Column(
      children: [
        // 프로그레스 바
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.inkLineLight,
          valueColor: AlwaysStoppedAnimation<Color>(domainColor),
          minHeight: 3.5,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 도메인 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: domainColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: domainColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    domainLabel,
                    style: GoogleFonts.gowunDodum(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: domainColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 질문 타이틀 & 서브타이틀
                Text(
                  question.title,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 18,
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
                const SizedBox(height: 24),

                // 선택지 목록 (절대 서술형)
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
                            ? domainColor.withValues(alpha: 0.08)
                            : AppColors.bgPanel,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? domainColor : AppColors.inkLine,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: domainColor.withValues(alpha: 0.15),
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
                            color: isSelected ? domainColor : AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (option.tag.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgDeep,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${option.tag}',
                                      style: GoogleFonts.gowunDodum(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? domainColor
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                Text(
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
                              ],
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

        // 하단 버튼 영역
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Row(
            children: [
              if (_currentIndex > 0) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _goToPrevious,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.inkLine),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  onPressed: selectedOption != null ? _goToNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: domainColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.bgPanel2,
                    disabledForegroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1
                        ? '다음 문항으로'
                        : '나침반 분석 완료하기',
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
    );
  }
}

/// 자존감 & 외로움 검사 결과 상세 시트 (모달 바텀시트용)
class SelfConnectionResultDetailSheet extends StatelessWidget {
  final SelfConnectionTestResult result;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;

  const SelfConnectionResultDetailSheet({
    super.key,
    required this.result,
    this.onNavigateToRest,
    this.onNavigateToDiaryWithQuote,
    this.onNavigateToDiary,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: AppColors.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '내면과 관계의 나침반 분석 결과',
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
              child: SelfConnectionResultDetailContent(
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

/// 자존감 & 외로움 검사 결과 상세 내용 위젯
class SelfConnectionResultDetailContent extends StatelessWidget {
  final SelfConnectionTestResult result;
  final void Function(RestMode targetMode)? onNavigateToRest;
  final void Function(Quote quote)? onNavigateToDiaryWithQuote;
  final VoidCallback? onNavigateToDiary;

  const SelfConnectionResultDetailContent({
    super.key,
    required this.result,
    this.onNavigateToRest,
    this.onNavigateToDiaryWithQuote,
    this.onNavigateToDiary,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 마음 지형도 헤더 카드
          _buildLandscapeBanner(),
          const SizedBox(height: 18),

          // 2. 자존감 3대 기둥 절대 평가 카드
          _buildSelfEsteemSection(),
          const SizedBox(height: 18),

          // 3. 외로움 & 연결감 스펙트럼 카드
          _buildLonelinessSection(),
          const SizedBox(height: 18),

          // 4. 심층 내면 통찰 (Insight Narrative)
          _buildInsightSection(),
          const SizedBox(height: 18),

          // 5. 맞춤 마음쉼터 처방 액션 카드
          _buildPrescriptionCard(context),
          const SizedBox(height: 18),

          // 6. 감성 큐레이션 선물 카드
          _buildCurationCard(context),
          const SizedBox(height: 24),

          // 7. 다이어리 기록 연계 버튼
          if (onNavigateToDiary != null || onNavigateToDiaryWithQuote != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onNavigateToDiaryWithQuote != null) {
                    final quote = Quote(
                      id: 0,
                      source: '내면과 관계의 나침반',
                      original: '',
                      reading: '',
                      english: '',
                      translation:
                          '${result.landscapeTitle} · ${result.selfEsteemType.title} · ${result.lonelinessLevel.title}',
                      commentary: result.insightNarrative,
                      mood: 'peaceful',
                    );
                    onNavigateToDiaryWithQuote!(quote);
                  } else if (onNavigateToDiary != null) {
                    onNavigateToDiary!();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentBrass,
                  side: const BorderSide(color: AppColors.accentBrassSoft),
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

  Widget _buildLandscapeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgPanel,
            AppColors.accentBrass.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentBrassSoft),
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
                  color: AppColors.accentBrass.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🧭 종합 마음 지형도',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentBrass,
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
          Text(
            '🏞️ ${result.landscapeTitle}',
            style: GoogleFonts.gowunDodum(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.landscapeSubtitle,
            style: GoogleFonts.gowunDodum(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfEsteemSection() {
    final acceptStatus =
        result.selfEsteemDomainStatuses[SelfEsteemDomain.selfAcceptance] ??
            DomainStatus.sufficient;
    final efficacyStatus =
        result.selfEsteemDomainStatuses[SelfEsteemDomain.selfEfficacy] ??
            DomainStatus.sufficient;
    final boundaryStatus =
        result.selfEsteemDomainStatuses[SelfEsteemDomain.selfBoundaries] ??
            DomainStatus.sufficient;

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
                  size: 18, color: AppColors.accentJade),
              const SizedBox(width: 8),
              Text(
                '자존감 3대 기둥 절대 분석',
                style: GoogleFonts.gowunDodum(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentJade.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.selfEsteemType.title,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentJade,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.selfEsteemType.summary,
            style: GoogleFonts.gowunDodum(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.inkLineLight),
          const SizedBox(height: 14),

          // 3대 기둥 지표
          _buildPillarRow('🌱 자기 수용 (실수·결점 포용)', acceptStatus),
          const SizedBox(height: 8),
          _buildPillarRow('⚡ 자기 신뢰 (주도성·해결력)', efficacyStatus),
          const SizedBox(height: 8),
          _buildPillarRow('🛡️ 자기 경계 (인정 독립·거절력)', boundaryStatus),
        ],
      ),
    );
  }

  Widget _buildPillarRow(String label, DomainStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inkLineLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.gowunDodum(
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: status.color.withValues(alpha: 0.4)),
            ),
            child: Text(
              status.label,
              style: GoogleFonts.gowunDodum(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLonelinessSection() {
    final intimateStatus =
        result.lonelinessDomainStatuses[LonelinessDomain.intimateConnection] ??
            DomainStatus.sufficient;
    final socialStatus =
        result.lonelinessDomainStatuses[LonelinessDomain.socialConnection] ??
            DomainStatus.sufficient;
    final solitudeStatus =
        result.lonelinessDomainStatuses[LonelinessDomain.solitudePower] ??
            DomainStatus.sufficient;

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
              const Icon(Icons.favorite_border_rounded,
                  size: 18, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                '외로움 & 연결감 스펙트럼',
                style: GoogleFonts.gowunDodum(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.lonelinessLevel.title,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.lonelinessLevel.summary,
            style: GoogleFonts.gowunDodum(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // 4단계 스펙트럼 게이지
          _buildSpectrumGauge(result.lonelinessLevel),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.inkLineLight),
          const SizedBox(height: 14),

          // 3대 연결 지표
          _buildPillarRow('🕊️ 정서적 친밀감 (심층 안전망)', intimateStatus),
          const SizedBox(height: 8),
          _buildPillarRow('🌿 사회적 소속감 (자연스러운 유대)', socialStatus),
          const SizedBox(height: 8),
          _buildPillarRow('🌙 고독 자생력 (혼자만의 평온)', solitudeStatus),
        ],
      ),
    );
  }

  Widget _buildSpectrumGauge(LonelinessLevel currentLevel) {
    final levels = [
      (level: LonelinessLevel.fertileSolitude, label: 'Lv.1 고독'),
      (level: LonelinessLevel.transientThirst, label: 'Lv.2 갈증'),
      (level: LonelinessLevel.emotionalDisconnect, label: 'Lv.3 단절'),
      (level: LonelinessLevel.deepIsolation, label: 'Lv.4 고립'),
    ];

    return Row(
      children: levels.map((item) {
        final isCurrent = item.level == currentLevel;
        final color = isCurrent ? const Color(0xFF3B82F6) : AppColors.inkLine;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.18)
                  : AppColors.bgDeep,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color,
                width: isCurrent ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: Text(
                item.label,
                style: GoogleFonts.gowunDodum(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBrassSoft.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: AppColors.accentBrass),
              const SizedBox(width: 8),
              Text(
                '내면의 통찰과 방향성',
                style: GoogleFonts.gowunDodum(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.insightNarrative,
            style: GoogleFonts.gowunDodum(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
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

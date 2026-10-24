import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/belief_model.dart';
import '../services/storage_service.dart';

class BeliefExplorerSheet extends StatefulWidget {
  final String? initialThought;
  final int initialTabIndex;

  const BeliefExplorerSheet({
    super.key,
    this.initialThought,
    this.initialTabIndex = 0,
  });

  @override
  State<BeliefExplorerSheet> createState() => _BeliefExplorerSheetState();
}

class _BeliefExplorerSheetState extends State<BeliefExplorerSheet> {
  int _selectedTabIndex = 0;
  List<UserBeliefEntry> _myBeliefs = [];
  bool _isLoadingBeliefs = true;
  String? _toastMessage;
  Timer? _toastTimer;

  // 하향 화살표 탐색기 텍스트 컨트롤러
  final TextEditingController _thoughtController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _ruleController = TextEditingController();
  final TextEditingController _fearController = TextEditingController();
  final TextEditingController _flexibleRuleController = TextEditingController();
  final TextEditingController _experimentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialThought != null ? 0 : widget.initialTabIndex;
    if (widget.initialThought != null && widget.initialThought!.isNotEmpty) {
      _thoughtController.text = widget.initialThought!;
    }
    _loadBeliefs();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _thoughtController.dispose();
    _meaningController.dispose();
    _ruleController.dispose();
    _fearController.dispose();
    _flexibleRuleController.dispose();
    _experimentController.dispose();
    super.dispose();
  }

  Future<void> _loadBeliefs() async {
    setState(() => _isLoadingBeliefs = true);
    final list = await StorageService.loadUserBeliefs();
    if (!mounted) return;
    setState(() {
      _myBeliefs = list;
      _isLoadingBeliefs = false;
    });
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

  // 템플릿 담기 다이얼로그
  void _openTemplateEditor(BeliefTemplate t) {
    final ruleCtrl = TextEditingController(text: t.intermediateRule);
    final fearCtrl = TextEditingController(text: t.coreFear);
    final flexCtrl = TextEditingController(text: t.flexibleRule);
    final expCtrl = TextEditingController(text: t.actionExperiment);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgPanel,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Text(t.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${t.title} 신념 등록',
                style: GoogleFonts.gowunDodum(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🛡️ 내가 지켜온 삶의 규칙 (중간신념)',
                style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentBrass),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: ruleCtrl,
                maxLines: 2,
                style: GoogleFonts.gowunDodum(fontSize: 12.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgCardWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '💔 그 밑의 두려움 (핵심신념)',
                style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentVermilion),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: fearCtrl,
                maxLines: 2,
                style: GoogleFonts.gowunDodum(fontSize: 12.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgCardWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '🌿 새로운 유연한 규칙 (대처)',
                style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentJade),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: flexCtrl,
                maxLines: 2,
                style: GoogleFonts.gowunDodum(fontSize: 12.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgCardWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '🧪 오늘의 작은 행동 실험',
                style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentNavy),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: expCtrl,
                maxLines: 2,
                style: GoogleFonts.gowunDodum(fontSize: 12.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgCardWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: GoogleFonts.gowunDodum(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEntry = UserBeliefEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: t.title,
                emoji: t.emoji,
                intermediateRule: ruleCtrl.text.trim(),
                coreFear: fearCtrl.text.trim(),
                flexibleRule: flexCtrl.text.trim(),
                actionExperiment: expCtrl.text.trim(),
                createdAt: DateTime.now(),
              );
              Navigator.pop(ctx);
              await StorageService.saveUserBelief(newEntry);
              if (!mounted) return;
              _loadBeliefs();
              setState(() => _selectedTabIndex = 2); // 내 신념 보관함으로 이동
              _showToast('마음 신념과 대처법이 저장되었습니다 🌿');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBrass,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('내 신념에 저장', style: GoogleFonts.gowunDodum(fontSize: 12.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: AppColors.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(18, 12, 18, bottomInset + 16),
        child: Stack(
        children: [
          Column(
            children: [
              // 상단 드래그 바 (부드러운 디자인)
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkLine.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentBrass.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology_alt_outlined, color: AppColors.accentBrass, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '마음 신념 탐색 & 대처소',
                        style: GoogleFonts.gowunDodum(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 깔끔한 선 없는 플랫 세그먼트 탭바
              _buildCustomTabBar(),
              const SizedBox(height: 12),

              // 탭 내용
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    _buildDownwardArrowTab(),
                    _buildTemplateTab(),
                    _buildMyBeliefsTab(),
                  ],
                ),
              ),
            ],
          ),

          // 바텀시트 내부 플로팅 토스트 알림 배너
          if (_toastMessage != null)
            Positioned(
              bottom: 12,
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
            ),
        ],
      ),
    ),
  );
}

  /// 외곽선 없이 부드럽게 전환되는 세그먼트 탭바
  Widget _buildCustomTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCardWarm,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildTabItem(index: 0, label: '하향 화살표', icon: Icons.arrow_downward),
          _buildTabItem(index: 1, label: '8대 템플릿', icon: Icons.auto_stories_outlined),
          _buildTabItem(index: 2, label: '신념 보관함', icon: Icons.bookmark_outline),
        ],
      ),
    );
  }

  Widget _buildTabItem({required int index, required String label, required IconData icon}) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentBrass : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accentBrass.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.gowunDodum(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 1: 하향 화살표 대화형 셀프 탐색기
  // -------------------------------------------------------------------------
  Widget _buildDownwardArrowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCardWarm,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_downward, color: AppColors.accentBrass, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '스쳐 지나간 생각의 밑바닥으로 내려가 나의 숨은 두려움과 삶의 규칙을 찾아냅니다.',
                    style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 1단계: 출발점 (생각)
          _buildArrowCard(
            stepNumber: '1',
            title: '출발점: 마음에 걸린 그 생각',
            subtitle: '최근 나를 괴롭히거나 불안하게 만든 생각은 무엇인가요?',
            child: TextField(
              controller: _thoughtController,
              style: GoogleFonts.gowunDodum(fontSize: 13),
              decoration: InputDecoration(
                hintText: '예: 팀장님이 내 보고서를 차갑게 봤어 / 실수를 해버렸어',
                filled: true,
                fillColor: AppColors.bgCardWarm,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          _buildStepConnector(),

          // 2단계: 의미 질문
          _buildArrowCard(
            stepNumber: '2',
            title: '만약 그 생각이 사실이라면, 그것은 나에게 어떤 의미인가요?',
            subtitle: '보기 중 가장 와닿는 것을 누르거나 직접 적어보세요.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildChoiceChip('사람들이 나를 무능하게 볼 것이다', _meaningController),
                    _buildChoiceChip('나는 인정받지 못하고 버림받을 것이다', _meaningController),
                    _buildChoiceChip('모든 일이 내 뜻대로 통제되지 않는다', _meaningController),
                    _buildChoiceChip('내 존재나 노력은 헛수고라는 뜻이다', _meaningController),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _meaningController,
                  style: GoogleFonts.gowunDodum(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '선택하거나 직접 의미를 적어보세요',
                    filled: true,
                    fillColor: AppColors.bgCardWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          _buildStepConnector(),

          // 3단계: 삶의 규칙 질문
          _buildArrowCard(
            stepNumber: '3',
            title: '그래서 평소 나를 지키기 위해 어떤 규칙을 지키려 애쓰나요?',
            subtitle: '이것이 바로 내가 만들어둔 [삶의 규칙(중간신념)]입니다.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildChoiceChip('모든 일을 빈틈없이 완벽하게 해내야 한다', _ruleController),
                    _buildChoiceChip('남들의 기분을 먼저 살피고 거절하지 않아야 한다', _ruleController),
                    _buildChoiceChip('모든 변수를 미리 철저하게 통제해야 한다', _ruleController),
                    _buildChoiceChip('내 감정은 참고 다른 사람에게 맞춰야 한다', _ruleController),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ruleController,
                  style: GoogleFonts.gowunDodum(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '선택하거나 나의 행동 규칙을 적어보세요',
                    filled: true,
                    fillColor: AppColors.bgCardWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          _buildStepConnector(),

          // 4단계: 뿌리 두려움 도달 (핵심신념)
          _buildArrowCard(
            stepNumber: '4',
            title: '그 규칙이 무너지면, 내 마음 밑바닥에 어떤 두려움이 있나요?',
            subtitle: '이것이 나의 가장 깊은 [핵심 두려움(핵심신념)]입니다.',
            accentColor: AppColors.accentVermilion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildChoiceChip('나는 부족하고 무능한 사람이다', _fearController),
                    _buildChoiceChip('나는 있는 그대로는 사랑받을 수 없다', _fearController),
                    _buildChoiceChip('세상은 위험하고 나는 너무 취약하다', _fearController),
                    _buildChoiceChip('나는 가치 없는 존재다', _fearController),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fearController,
                  style: GoogleFonts.gowunDodum(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '선택하거나 깊은 두려움을 적어보세요',
                    filled: true,
                    fillColor: AppColors.bgCardWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          _buildStepConnector(),

          // 5단계: 유연한 새 규칙 & 행동 실험 수립
          _buildArrowCard(
            stepNumber: '5',
            title: '대처 워크시트: 새로운 유연한 규칙 & 작은 실험',
            subtitle: '경직된 규칙을 유연하게 풀고, 오늘 시도해볼 작은 실험을 적어보세요.',
            accentColor: AppColors.accentJade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌿 유연한 새 규칙:', style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentJade)),
                const SizedBox(height: 4),
                TextField(
                  controller: _flexibleRuleController,
                  maxLines: 2,
                  style: GoogleFonts.gowunDodum(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '예: 실수해도 괜찮다. 실수는 성장의 일부이며 내 가치는 변하지 않는다.',
                    filled: true,
                    fillColor: AppColors.bgCardWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Text('🧪 오늘의 작은 행동 실험:', style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentNavy)),
                const SizedBox(height: 4),
                TextField(
                  controller: _experimentController,
                  maxLines: 2,
                  style: GoogleFonts.gowunDodum(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '예: 오늘 오타 하나를 수정하지 않고 넘어가 보기 / 거절해 보기',
                    filled: true,
                    fillColor: AppColors.bgCardWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveDownwardArrowResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBrass,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                '발견한 신념 & 대처법 저장하기',
                style: GoogleFonts.gowunDodum(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Icon(Icons.arrow_downward_rounded, color: AppColors.accentBrassSoft, size: 16),
      ),
    );
  }

  Widget _buildArrowCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required Widget child,
    Color accentColor = AppColors.accentBrass,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(12),
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
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.gowunDodum(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String text, TextEditingController controller) {
    return InkWell(
      onTap: () {
        setState(() {
          controller.text = text;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.bgCardWarm,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: GoogleFonts.gowunDodum(fontSize: 11, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Future<void> _saveDownwardArrowResult() async {
    final rule = _ruleController.text.trim();
    final fear = _fearController.text.trim();
    final flex = _flexibleRuleController.text.trim();
    final exp = _experimentController.text.trim();

    if (rule.isEmpty && fear.isEmpty) {
      _showToast('삶의 규칙이나 두려움을 적어주세요.');
      return;
    }

    final newEntry = UserBeliefEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '하향 화살표로 찾은 신념',
      emoji: '🔍',
      intermediateRule: rule.isNotEmpty ? rule : '내가 지켜온 행동 규칙',
      coreFear: fear.isNotEmpty ? fear : '마음 밑바닥의 두려움',
      flexibleRule: flex.isNotEmpty ? flex : '실수해도 괜찮으며 내 가치는 충분하다.',
      actionExperiment: exp,
      sourceThought: _thoughtController.text.trim(),
      createdAt: DateTime.now(),
    );

    await StorageService.saveUserBelief(newEntry);
    if (!mounted) return;
    _loadBeliefs();
    setState(() => _selectedTabIndex = 2);
    _showToast('신념과 유연한 대처법이 저장되었습니다 🌿');
  }

  // -------------------------------------------------------------------------
  // TAB 2: 8대 삶의 규칙 템플릿
  // -------------------------------------------------------------------------
  Widget _buildTemplateTab() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: BeliefTemplate.presets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final t = BeliefTemplate.presets[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgPanel,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(t.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.title,
                            style: GoogleFonts.gowunDodum(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openTemplateEditor(t),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBrass.withValues(alpha: 0.15),
                      foregroundColor: AppColors.accentBrass,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.add, size: 13),
                    label: Text(
                      '내 신념에 담기',
                      style: GoogleFonts.gowunDodum(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                t.description,
                style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),

              // 규칙 & 두려움 요약 카드 (부드러운 배경 분리)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgCardWarm,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🛡️ 삶의 규칙: ', style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentBrass)),
                        Expanded(
                          child: Text(
                            t.intermediateRule,
                            style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💔 숨은 두려움: ', style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentVermilion)),
                        Expanded(
                          child: Text(
                            t.coreFear,
                            style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.accentVermilion, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🌿 유연한 대처: ', style: GoogleFonts.gowunDodum(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentJade)),
                        Expanded(
                          child: Text(
                            t.flexibleRule,
                            style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.accentJade, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // TAB 3: 나의 신념 보관함
  // -------------------------------------------------------------------------
  Widget _buildMyBeliefsTab() {
    if (_isLoadingBeliefs) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentBrass),
      );
    }

    if (_myBeliefs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text(
                '아직 등록된 신념이 없습니다.',
                style: GoogleFonts.gowunDodum(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '[8대 템플릿]에서 내 유형을 고르거나\n[하향 화살표]를 통해 내 마음의 뿌리 신념을 찾아보세요.',
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _myBeliefs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final b = _myBeliefs[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgPanel,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(b.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.title,
                            style: GoogleFonts.gowunDodum(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textDim),
                    onPressed: () async {
                      await StorageService.deleteUserBelief(b.id);
                      _loadBeliefs();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 삶의 규칙 vs 뿌리 두려움 (선 없이 부드러운 카드)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgCardWarm,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🛡️ 내가 지켜온 삶의 규칙:', style: GoogleFonts.gowunDodum(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentBrass)),
                    const SizedBox(height: 2),
                    Text(b.intermediateRule, style: GoogleFonts.gowunDodum(fontSize: 12.5, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text('💔 그 밑의 깊은 두려움:', style: GoogleFonts.gowunDodum(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentVermilion)),
                    const SizedBox(height: 2),
                    Text(b.coreFear, style: GoogleFonts.gowunDodum(fontSize: 12.5, color: AppColors.accentVermilion)),
                    const SizedBox(height: 8),
                    Text('🌿 나의 유연한 새 규칙:', style: GoogleFonts.gowunDodum(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentJade)),
                    const SizedBox(height: 2),
                    Text(b.flexibleRule, style: GoogleFonts.gowunDodum(fontSize: 12.5, color: AppColors.accentJade, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              if (b.actionExperiment.isNotEmpty) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    await StorageService.toggleBeliefExperiment(b.id);
                    _loadBeliefs();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: b.isCompletedExperiment ? AppColors.accentJade.withValues(alpha: 0.12) : AppColors.bgCardWarm,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          b.isCompletedExperiment ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: b.isCompletedExperiment ? AppColors.accentJade : AppColors.accentBrass,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '작은 실험: ${b.actionExperiment}',
                            style: GoogleFonts.gowunDodum(
                              fontSize: 11.5,
                              color: b.isCompletedExperiment ? AppColors.textDim : AppColors.textPrimary,
                              decoration: b.isCompletedExperiment ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'mind_test_model.dart';
import 'survival_rule_test_model.dart';

/// 75대 행동 활성화(Pleasant Activities) 마스터 풀 및 상태별 추천 엔진
class PleasantActivityPool {
  PleasantActivityPool._();

  // ==========================================
  // 1. 감정 팔레트 검사 (EmotionCategory) 활동 풀
  // ==========================================
  static final Map<EmotionCategory, List<CurationItem>> emotionPool = {
    EmotionCategory.tension: [
      const CurationItem(
        category: 'relax',
        categoryLabel: '신체 이완 활동',
        tag: '긴장 풀기',
        title: '따뜻한 물로 손발 씻고 목·어깨 가볍게 털어내기',
        subtitle: '체온을 올리고 굳어있던 상체 근육을 부드럽게 털어내며 이완하기',
        recommendationReason: '몸의 감각을 따뜻하게 깨우고 부드럽게 이완하여 긴장된 신경을 풀어줍니다.',
        icon: Icons.spa_outlined,
      ),
      const CurationItem(
        category: 'relax',
        categoryLabel: '신체 돌봄 활동',
        tag: '몸의 긴장 낮추기',
        title: '가벼운 스트레칭과 요가 동작으로 몸 구석구석 기지개 켜기',
        subtitle: '목, 어깨, 허리를 부드럽게 늘려주며 굳은 근육에 산소 공급하기',
        recommendationReason: '가벼운 신체 이완은 교감신경의 흥분을 가라앉히는 데 효과적입니다.',
        icon: Icons.self_improvement_outlined,
      ),
      const CurationItem(
        category: 'nature',
        categoryLabel: '자연 돌봄 활동',
        tag: '초록의 안정감',
        title: '화분 식물 돌보기 & 초록 식물에 시원한 물 주기',
        subtitle: '화분의 흙을 살피고 잎사귀를 부드럽게 닦아주며 교감하기',
        recommendationReason: '식물을 가꾸는 정적인 돌봄 행동은 스트레스 호르몬을 낮춰줍니다.',
        icon: Icons.water_drop_outlined,
      ),
      const CurationItem(
        category: 'rest',
        categoryLabel: '감각 쉼 활동',
        tag: '따뜻한 입욕',
        title: '따뜻한 물로 샤워하거나 욕조에서 반신욕 즐기기',
        subtitle: '수증기와 온기에 몸을 맡기고 하루의 피로와 긴장 씻어내기',
        recommendationReason: '온수는 혈액순환을 촉진하고 전신의 근육 긴장을 빠르게 이완합니다.',
        icon: Icons.bathtub_outlined,
      ),
    ],
    EmotionCategory.depletion: [
      const CurationItem(
        category: 'rest',
        categoryLabel: '감각 휴식 활동',
        tag: '안전한 충전',
        title: '포근한 담요 덮고 잔잔한 자연 소리(빗소리·숲소리) 듣기',
        subtitle: '시각 자극을 줄이고 편안한 환경에서 청각 감각에만 머물기',
        recommendationReason: '에너지가 고갈되었을 때는 생각을 멈추고 안전하고 포근한 감각에 머무는 것이 좋습니다.',
        icon: Icons.bed_outlined,
      ),
      const CurationItem(
        category: 'pause',
        categoryLabel: '무위 쉼 활동',
        tag: '완전한 방전 쉼',
        title: '아무것도 하지 않고 편안하게 누워 빈둥거리기',
        subtitle: '생산성 압박을 내려놓고 침대나 소파에서 몸의 무게 온전히 맡기기',
        recommendationReason: '방전된 상태에서는 자책 없이 멈추는 것이 가장 빠른 회복의 길입니다.',
        icon: Icons.hotel_outlined,
      ),
      const CurationItem(
        category: 'nature',
        categoryLabel: '햇살 충전 활동',
        tag: '생체 리듬 회복',
        title: '햇볕 잘 드는 창가나 벤치에서 따뜻하게 일광욕하기',
        subtitle: '눈을 감고 뺨에 닿는 온기를 느끼며 몸속 에너지 충전하기',
        recommendationReason: '햇볕은 행복 호르몬 세로토닌 합성을 도와 무기력감을 덜어줍니다.',
        icon: Icons.wb_sunny_outlined,
      ),
      const CurationItem(
        category: 'audio',
        categoryLabel: '정서 치유 활동',
        tag: '마음의 위로',
        title: '좋아하는 잔잔한 연주곡이나 오디오북 들으며 눈 감기',
        subtitle: '자극적인 영상 대신 부드러운 소리에 귀 기울이며 뇌 피로 덜기',
        recommendationReason: '부드러운 청각 자극은 과부하된 뇌파를 알파파로 유도합니다.',
        icon: Icons.headphones_outlined,
      ),
    ],
    EmotionCategory.vitality: [
      const CurationItem(
        category: 'stroll',
        categoryLabel: '일상 활력 활동',
        tag: '가벼운 전환',
        title: '새로운 길로 15분 산책하며 주변 풍경 사진 한 장 남기기',
        subtitle: '평소와 다른 길을 걸으며 일상의 작은 아름다움 발견하기',
        recommendationReason: '풍부한 내면의 에너지를 기분 좋은 탐색과 신체 활동으로 확장해 보세요.',
        icon: Icons.directions_walk_outlined,
      ),
      const CurationItem(
        category: 'sports',
        categoryLabel: '에너지 활동',
        tag: '시원한 바람',
        title: '시원한 바람을 맞으며 자전거를 타거나 가볍게 조깅하기',
        subtitle: '기분 좋은 심장 박동을 느끼며 활력의 흐름 만끽하기',
        recommendationReason: '적절한 신체 활동은 엔도르핀을 생성하여 긍정 정서를 오래 지속시킵니다.',
        icon: Icons.directions_bike_outlined,
      ),
      const CurationItem(
        category: 'cook',
        categoryLabel: '창작 미식 활동',
        tag: '나를 위한 요리',
        title: '먹고 싶었던 특별한 레시피로 요리하거나 맛있는 간식 만들기',
        subtitle: '신선한 재료를 다듬고 향긋한 냄새를 맡으며 완성의 기쁨 누리기',
        recommendationReason: '요리는 오감을 골고루 자극하며 창의적인 몰입감을 제공합니다.',
        icon: Icons.restaurant_outlined,
      ),
      const CurationItem(
        category: 'music',
        categoryLabel: '리듬 표현 활동',
        tag: '신나는 표현',
        title: '좋아하는 신나는 음악에 맞춰 가볍게 몸을 흔들고 노래 부르기',
        subtitle: '에너지를 억누르지 않고 리듬에 몸을 맡겨 자유롭게 표현하기',
        recommendationReason: '음악과 신체 표현은 기쁨의 에너지를 전신으로 확산시킵니다.',
        icon: Icons.music_note_outlined,
      ),
    ],
    EmotionCategory.peace: [
      const CurationItem(
        category: 'nature',
        categoryLabel: '마음 음미 활동',
        tag: '자연과 여백',
        title: '창가에서 하늘 구름 바라보며 시원한 바람 쐬기',
        subtitle: '시선을 먼 곳에 두고 바람의 촉감을 천천히 느껴보기',
        recommendationReason: '지금의 맑고 평온한 마음을 오감으로 깊이 음미하고 기억에 담아둡니다.',
        icon: Icons.wb_sunny_outlined,
      ),
      const CurationItem(
        category: 'culture',
        categoryLabel: '사색 독서 활동',
        tag: '마음의 양식',
        title: '좋아하는 책의 마음에 드는 문장을 소리 내어 천천히 읽어보기',
        subtitle: '도서관이나 조용한 방에서 문장이 주는 깊은 여운 음미하기',
        recommendationReason: '차분한 독서는 평온한 마음에 깊은 지혜와 안정감을 더해줍니다.',
        icon: Icons.menu_book_outlined,
      ),
      const CurationItem(
        category: 'nature',
        categoryLabel: '자연 향기 활동',
        tag: '오감 힐링',
        title: '꽃이나 초록 식물의 싱그러운 흙내음 깊게 맡기',
        subtitle: '자연이 주는 맑고 은은한 향기에 집중하며 평화 누리기',
        recommendationReason: '식물의 천연 피톤치드와 향기는 부교감신경을 강화합니다.',
        icon: Icons.local_florist_outlined,
      ),
      const CurationItem(
        category: 'mind',
        categoryLabel: '고요 머물기 활동',
        tag: '마음의 평화',
        title: '평화로운 벤치나 툇마루에 앉아 5분간 가만히 풍경 감상하기',
        subtitle: '스마트폰을 내려놓고 지나가는 바람과 세상의 리듬 지켜보기',
        recommendationReason: '여백을 즐기는 시간은 마음의 내적 회복 탄력성을 단단하게 만듭니다.',
        icon: Icons.chair_outlined,
      ),
    ],
  };

  // ==========================================
  // 2. 자존감 & 외로움 검사 활동 풀
  // ==========================================
  static final Map<String, List<CurationItem>> selfConnectionPool = {
    'solid_connected': [
      // 푸르른 생명의 숲
      const CurationItem(
        category: 'connect',
        categoryLabel: '다정한 연결 활동',
        tag: '마음 나누기',
        title: '소중한 사람에게 짧고 다정한 안부 메시지 하나 보내기',
        subtitle: '따뜻한 마음을 표현하며 일상의 소중한 관계에 온기 더하기',
        recommendationReason: '내면의 충만한 에너지를 건강하고 다정한 유대감으로 나누어 보세요.',
        icon: Icons.favorite_border,
      ),
      const CurationItem(
        category: 'gratitude',
        categoryLabel: '감사 전하기 활동',
        tag: '고마움 표현',
        title: '고마운 사람 3명을 떠올리며 마음속으로 진심 어린 감사 전하기',
        subtitle: '그들이 내 삶에 있어 주어 고마운 이유를 차분히 적어보기',
        recommendationReason: '감사를 표현하는 행동은 관계의 친밀도와 삶의 만족도를 높입니다.',
        icon: Icons.volunteer_activism_outlined,
      ),
    ],
    'solid_lonely': [
      // 달빛 비추는 고요한 언덕
      const CurationItem(
        category: 'space',
        categoryLabel: '온기 체감 활동',
        tag: '세상과의 연결',
        title: '좋아하는 공간(공원, 산책로, 도서관)에서 사람들의 온기 느끼기',
        subtitle: '말을 섞지 않아도 같은 공간에 머무는 이들의 평화로운 기운 함께하기',
        recommendationReason: '혼자만의 고요함 속에 은은한 세상의 생기를 채워 넣습니다.',
        icon: Icons.people_outline,
      ),
      const CurationItem(
        category: 'connect',
        categoryLabel: '옛 친구 연락 활동',
        tag: '작은 연결 시작',
        title: '오랜만에 생각난 옛 친구나 지인에게 가벼운 안부 전하기',
        subtitle: '"문득 생각나서 연락했어" 한마디로 잊고 있던 온기 깨우기',
        recommendationReason: '작은 용기를 낸 연결은 마음속 외로움의 벽을 허무는 열쇠가 됩니다.',
        icon: Icons.chat_bubble_outline,
      ),
    ],
    'fragile_connected': [
      // 물안개 낀 잔잔한 포구
      const CurationItem(
        category: 'music',
        categoryLabel: '나를 위한 몰입 활동',
        tag: '온전한 내 시간',
        title: '휴대폰을 잠시 덮고 좋아하는 음악 한 곡 온전히 집중해서 듣기',
        subtitle: '남들의 시선이나 연락을 차단하고 오롯이 내 감각에만 귀 기울이기',
        recommendationReason: '타인을 챙기느라 바빴던 마음을 잠시 내려놓고 나 자신을 온전히 채웁니다.',
        icon: Icons.headphones_outlined,
      ),
      const CurationItem(
        category: 'self_care',
        categoryLabel: '나를 위한 단장 활동',
        tag: '나 자신 대접하기',
        title: '마음에 드는 옷을 차려입고 나만을 위한 특별한 산책 즐기기',
        subtitle: '누구에게 보여주기 위함이 아닌, 나를 위해 단정하게 가꾸기',
        recommendationReason: '스스로를 정성껏 돌보는 행위는 손상된 자존감을 회복시키는 기초입니다.',
        icon: Icons.checkroom_outlined,
      ),
    ],
    'fragile_lonely': [
      // 비 내리는 따뜻한 오두막
      const CurationItem(
        category: 'self_compassion',
        categoryLabel: '자기 자비 활동',
        tag: '스스로 다독이기',
        title: '양손을 가슴에 얹고 스스로에게 "오늘 정말 고생 많았어" 말해주기',
        subtitle: '따뜻한 손의 온기를 느끼며 나에게 건네는 가장 친절한 위로',
        recommendationReason: '외롭고 지친 나를 비판하지 않고 가장 따뜻한 친구처럼 안아줍니다.',
        icon: Icons.favorite_outline,
      ),
      const CurationItem(
        category: 'gift',
        categoryLabel: '나를 위한 선물 활동',
        tag: '작은 친절 베풀기',
        title: '나를 응원하는 마음으로 소소하게 갖고 싶던 작은 선물 사주기',
        subtitle: '따뜻한 음료나 작은 꽃 한 송이로 나 자신에게 감사 표현하기',
        recommendationReason: '스스로에게 건네는 작은 호의는 차가워진 마음에 따스한 온기를 줍니다.',
        icon: Icons.card_giftcard_outlined,
      ),
    ],
    'balanced': [
      // 바람이 쉬어가는 툇마루
      const CurationItem(
        category: 'refresh',
        categoryLabel: '환경 정돈 활동',
        tag: '작은 정돈과 환기',
        title: '책상 위 물건 3가지 정돈하고 좋아하는 향기나 바람 들이마시기',
        subtitle: '내 주변의 작은 공간을 깔끔하게 가꾸며 맑은 기분 환기하기',
        recommendationReason: '작은 정돈을 통해 내면의 통제감과 산뜻한 여유를 되찾습니다.',
        icon: Icons.cleaning_services_outlined,
      ),
      const CurationItem(
        category: 'nature',
        categoryLabel: '초록 돌봄 활동',
        tag: '생명 가꾸기',
        title: '실내 화분에 물을 주고 초록 잎사귀를 햇볕 쪽으로 돌려주기',
        subtitle: '작은 생명이 자라나는 모습을 바라보며 마음에 싱그러움 더하기',
        recommendationReason: '생명을 돌보는 소소한 행동은 일상에 잔잔한 균형감을 줍니다.',
        icon: Icons.park_outlined,
      ),
    ],
  };

  // ==========================================
  // 3. 핵심 신념 탐색 검사 활동 풀
  // ==========================================
  static final Map<String, List<CurationItem>> beliefPool = {
    'perfectionism': [
      const CurationItem(
        category: 'permission',
        categoryLabel: '불완전함 허용 활동',
        tag: '충분함 연습',
        title: '완벽하게 하려던 일 중 하나를 "이 정도면 충분해" 하고 멈춰보기',
        subtitle: '100점이 아니어도 괜찮다는 마음으로 80%에서 편안하게 마침표 찍기',
        recommendationReason: '과도한 기준을 내려놓고 마음의 숨통과 휴식을 허락합니다.',
        icon: Icons.check_circle_outline,
      ),
      const CurationItem(
        category: 'pause',
        categoryLabel: '무위 쉼 활동',
        tag: '빈둥거림의 미학',
        title: '10분 동안 아무런 성과 없이 좋아하는 그림 낙서나 퍼즐 즐기기',
        subtitle: '잘해야 한다는 결과를 버리고 순수한 과정의 재미에만 몰입하기',
        recommendationReason: '평가 없는 놀이는 완벽주의 신경망의 긴장을 풀어줍니다.',
        icon: Icons.draw_outlined,
      ),
    ],
    'approval_seeking': [
      const CurationItem(
        category: 'self_priority',
        categoryLabel: '나 중심 돌봄 활동',
        tag: '내 취향 우선',
        title: '무리한 부탁 하나를 정중히 미루거나 내가 좋아하는 간식 천천히 음미하기',
        subtitle: '남들의 눈치 대신 오늘 내가 진짜 원하는 작은 선택 하나 해보기',
        recommendationReason: '외부로 쏠려있던 주의를 내 마음에 돌려 스스로를 소중히 대접합니다.',
        icon: Icons.sentiment_satisfied_alt,
      ),
      const CurationItem(
        category: 'self_choice',
        categoryLabel: '주체적 선택 활동',
        tag: '나만의 시간',
        title: '오롯이 혼자만의 산책을 즐기며 내가 걷고 싶은 방향으로만 걷기',
        subtitle: '남에게 맞추지 않고 나의 걸음걸이 속도와 시선에 집중하기',
        recommendationReason: '나의 욕구에 집중하는 경험은 타인 인정에 대한 의존도를 낮춥니다.',
        icon: Icons.directions_walk_outlined,
      ),
    ],
    'excessive_control': [
      const CurationItem(
        category: 'spontaneity',
        categoryLabel: '자율 탐색 활동',
        tag: '흐름에 맡기기',
        title: '산책길에서 갈림길이 나오면 생각 없이 발길 닿는 대로 걸어보기',
        subtitle: '계획과 통제를 잠시 내려놓고 우연이 주는 작은 즐거움 경험하기',
        recommendationReason: '모든 것을 통제하지 않아도 안전하고 즐거울 수 있음을 몸으로 배웁니다.',
        icon: Icons.explore_outlined,
      ),
      const CurationItem(
        category: 'nature',
        categoryLabel: '자연 관조 활동',
        tag: '자연의 섭리',
        title: '모닥불 불멍을 보거나 흘러가는 구름의 모양 가만히 지켜보기',
        subtitle: '바꾸려 애쓰지 않고 흐름대로 흘러가는 자연의 변화 느끼기',
        recommendationReason: '통제 불가능함을 수용할 때 비로소 깊은 내적 평화가 찾아옵니다.',
        icon: Icons.local_fire_department_outlined,
      ),
    ],
    'default': [
      const CurationItem(
        category: 'mindfulness',
        categoryLabel: '감각 주의 활동',
        tag: '현재에 머물기',
        title: '따뜻한 물 한 잔 천천히 마시며 목 넘김 감각에만 집중하기',
        subtitle: '생각을 멈추고 지금 이 순간 내 몸이 느끼는 온기와 감각 알아차리기',
        recommendationReason: '굳어있던 마음에 부드러운 여백과 유연성을 선물합니다.',
        icon: Icons.water_drop_outlined,
      ),
      const CurationItem(
        category: 'nature',
        categoryLabel: '초록 교감 활동',
        tag: '식물 돌봄',
        title: '초록 식물에 물을 주고 흙냄새를 천천히 들이마시기',
        subtitle: '생명의 싱그러운 에너지를 오감으로 느끼며 차분하게 안착하기',
        recommendationReason: '자연과의 접촉은 불안한 생각의 소용돌이를 잠재워줍니다.',
        icon: Icons.yard_outlined,
      ),
    ],
  };

  // ==========================================
  // 4. 삶의 규칙 탐색 검사 활동 풀
  // ==========================================
  static final Map<SurvivalRuleType, List<CurationItem>> survivalRulePool = {
    SurvivalRuleType.overachieving: [
      const CurationItem(
        category: 'pause',
        categoryLabel: '무위(無爲) 쉼 활동',
        tag: '멍때리기 연습',
        title: '알람을 10분 맞춰두고 어떤 생산적인 일도 하지 않고 멍때리기',
        subtitle: '생산성과 성과 압박을 잠시 내려놓고 온전한 무위(無爲)의 편안함 누리기',
        recommendationReason: '아무것도 하지 않아도 나는 그 자체로 가치 있고 안전함을 경험합니다.',
        icon: Icons.timer_outlined,
      ),
      const CurationItem(
        category: 'rest',
        categoryLabel: '몸 쉼 활동',
        tag: '포근한 휴식',
        title: '편안한 옷으로 갈아입고 좋아하는 쿠션에 기대어 20분 낮잠 자기',
        subtitle: '해야 할 일 목록을 덮어두고 지친 뇌와 몸에 완전한 방학 주기',
        recommendationReason: '쉼은 성과의 도구가 아닌, 인간으로서 마땅히 누려야 할 권리입니다.',
        icon: Icons.airline_seat_recline_extra_outlined,
      ),
    ],
    SurvivalRuleType.pleasing: [
      const CurationItem(
        category: 'self_choice',
        categoryLabel: '자기 주도 활동',
        tag: '내 취향 누리기',
        title: '오늘 내가 진짜 먹고 싶은 메뉴나 보고 싶은 영상을 혼자 즐기기',
        subtitle: '타인의 입맛이나 기분을 맞추지 않고 온전히 내 마음에 맞추는 시간',
        recommendationReason: '남을 향했던 배려를 나 자신에게 선물하여 내면의 주체성을 회복합니다.',
        icon: Icons.thumb_up_alt_outlined,
      ),
      const CurationItem(
        category: 'creation',
        categoryLabel: '나만의 창작 활동',
        tag: '온전한 내 표현',
        title: '누구에게도 보여주지 않을 나만의 비밀 일기나 소소한 시 한 편 쓰기',
        subtitle: '남의 평가를 신경 쓰지 않고 내 진짜 마음을 솔직하게 털어놓기',
        recommendationReason: '평가받지 않는 자기표현은 타인 중심적 사고를 건강하게 해체합니다.',
        icon: Icons.edit_note_outlined,
      ),
    ],
    SurvivalRuleType.hyperControl: [
      const CurationItem(
        category: 'release',
        categoryLabel: '통제 이완 활동',
        tag: '숨 비워내기',
        title: '창문을 활짝 열고 바람결을 느끼며 깊은 한숨 3번 내쉬기',
        subtitle: '몸의 힘을 빼고 "모든 것을 내가 다 해결하지 않아도 돼" 속삭이기',
        recommendationReason: '긴장된 통제 레이더를 끄고 흐름에 몸을 맡기는 안도감을 느낍니다.',
        icon: Icons.air,
      ),
      const CurationItem(
        category: 'nature',
        categoryLabel: '물길 산책 활동',
        tag: '자연의 유연함',
        title: '강가, 호수, 분수대 옆을 걸으며 물결의 자연스러운 흐름 바라보기',
        subtitle: '억지로 통제하지 않아도 순리대로 흘러가는 자연의 유연함 배우기',
        recommendationReason: '흐르는 물을 관찰하는 것은 경직된 통제 강박을 이완시킵니다.',
        icon: Icons.waves_outlined,
      ),
    ],
    SurvivalRuleType.emotionalWall: [
      const CurationItem(
        category: 'soft_smile',
        categoryLabel: '정서 환기 활동',
        tag: '미소와 온기',
        title: '좋아하는 귀여운 동물 사진이나 자연 풍경 보며 마음속 미소 지어보기',
        subtitle: '닫아두었던 감정의 문을 무해하고 따뜻한 대상에게 살포시 열어보기',
        recommendationReason: '방어하느라 굳어있던 마음에 부드러운 감정의 온기가 스며듭니다.',
        icon: Icons.sentiment_very_satisfied,
      ),
      const CurationItem(
        category: 'music',
        categoryLabel: '감정 정화 활동',
        tag: '마음의 멜로디',
        title: '혼자 있는 공간에서 좋아하는 음악을 크게 틀고 따라 부르기',
        subtitle: '숨겨왔던 내면의 감정을 목소리에 실어 밖으로 시원하게 터뜨리기',
        recommendationReason: '노래 부르기는 억압된 감정을 안전하게 방출하고 정화해 줍니다.',
        icon: Icons.mic_external_on_outlined,
      ),
    ],
    SurvivalRuleType.hyperResponsibility: [
      const CurationItem(
        category: 'defer',
        categoryLabel: '짐 내려놓기 활동',
        tag: '과감한 미루기',
        title: '오늘 할 일 목록 중 1가지를 "내일 해도 괜찮아" 하고 과감하게 미뤄두기',
        subtitle: '모든 책임을 오늘 다 짊어지지 않고 나에게 휴식의 우선순위 양보하기',
        recommendationReason: '책임감의 덫에서 벗어나 나를 지키는 건강한 분리를 실천합니다.',
        icon: Icons.event_busy_outlined,
      ),
      const CurationItem(
        category: 'nature',
        categoryLabel: '시원한 바람 쐬기',
        tag: '머리 식히기',
        title: '바깥으로 나가 10분간 하늘을 바라보며 가볍게 걷기',
        subtitle: '"세상은 내가 다 짊어지지 않아도 잘 돌아간다" 생각 환기하기',
        recommendationReason: '과도한 책임감에서 한 발짝 물러설 때 객관적 시야와 여유가 생깁니다.',
        icon: Icons.nature_people_outlined,
      ),
    ],
    SurvivalRuleType.preemptiveSurrender: [
      const CurationItem(
        category: 'micro_step',
        categoryLabel: '초미세 성취 활동',
        tag: '10초 작은 시작',
        title: '물 한 컵 마시기 or 신발 가지런히 놓기 같은 10초 행동 하나 완료하기',
        subtitle: '실패할 수 없는 아주 작은 행동을 마치고 스스로에게 엄지 척 들어주기',
        recommendationReason: '체념의 무력감을 깨고 "나는 움직일 수 있다"는 작은 효능감을 깨웁니다.',
        icon: Icons.auto_awesome,
      ),
      const CurationItem(
        category: 'plant',
        categoryLabel: '작은 돌봄 활동',
        tag: '초록 식물 물주기',
        title: '초록 식물에 물 한 컵을 주고 잎사귀 한 장 다정하게 쓰다듬기',
        subtitle: '부담 없는 30초 돌봄을 통해 생명의 기운과 나의 움직임 확인하기',
        recommendationReason: '작고 확실한 성공 경험은 무력감의 껍질을 깨는 가장 강력한 시작입니다.',
        icon: Icons.spa_outlined,
      ),
    ],
  };

  // ==========================================
  // 추천 헬퍼 메서드
  // ==========================================
  static CurationItem getEmotionActivity(EmotionCategory cat, [int? seed]) {
    final list = emotionPool[cat] ?? emotionPool[EmotionCategory.peace]!;
    if (seed != null) {
      return list[seed.abs() % list.length];
    }
    return list.first;
  }

  static CurationItem getSelfConnectionActivity(String key, [int? seed]) {
    final list = selfConnectionPool[key] ?? selfConnectionPool['balanced']!;
    if (seed != null) {
      return list[seed.abs() % list.length];
    }
    return list.first;
  }

  static CurationItem getBeliefActivity(String key, [int? seed]) {
    final list = beliefPool[key] ?? beliefPool['default']!;
    if (seed != null) {
      return list[seed.abs() % list.length];
    }
    return list.first;
  }

  static CurationItem getSurvivalRuleActivity(SurvivalRuleType type, [int? seed]) {
    final list = survivalRulePool[type] ?? survivalRulePool[SurvivalRuleType.overachieving]!;
    if (seed != null) {
      return list[seed.abs() % list.length];
    }
    return list.first;
  }
}

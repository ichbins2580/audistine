# DDS-Clinician (상담자 웹) - Audistine 감정 일기 QR 연동 규격서

## 1. 개요
* **발신 앱**: `audistine` (내담자용 마음 관리 웹/앱)
* **수신 앱**: `DDS-Clinician` (`https://dds-clinician.web.app/review`)
* **전송 방식**: URL Hash 기반 Base64Url 인코딩 (외부 DB 없이 안전한 P2P 전송)
* **전송 규격**: 단건 일기 또는 내담자가 직접 체크한 묶음 일기 (최대 5건)

---

## 2. 수신 URL 구조
```
https://dds-clinician.web.app/review#data={BASE64_URL_PAYLOAD}
```
* `#data=` 뒤의 문자열을 Base64Url 디코딩하고 UTF-8 JSON으로 파싱합니다.

---

## 3. 데이터 페이로드 스키마

### (A) 단건 전송 모드 (`mode: "single"`)
내담자가 1건만 선택하여 보낸 경우:
```json
{
  "v": 1,
  "app": "audistine",
  "mode": "single",
  "id": "cbt_1729600000000",
  "createdAt": "2026-10-22T14:30:00.000",
  "type": "structuredCbt",
  "mood": "😢 우울",
  "situation": "직장에서 프로젝트 마감 일정을 통보받았을 때",
  "thought": "나는 이걸 제시간에 끝내지 못하고 실패할 것이다.",
  "emotion": "불안(85%), 무력감(70%)",
  "distortions": ["파국화", "이분법적 사고"],
  "alt": "일정이 촉박하지만 우선순위를 나누어 단계별로 진행하면 충분히 해낼 수 있다.",
  "action": "오늘 1단계 핵심 업무부터 먼저 착수하기",
  "content": ""
}
```

### (B) 묶음 전송 모드 (`mode: "batch"`)
내담자가 여러 건(2~5건)을 직접 체크하여 보낸 경우 (압축 경량 키 적용):
```json
{
  "v": 1,
  "app": "audistine",
  "mode": "batch",
  "count": 3,
  "entries": [
    {
      "id": "cbt_001",
      "dt": "2026-10-22 14:30",
      "t": "structuredCbt",
      "m": "😢 우울",
      "sit": "상황 내용...",
      "th": "자동적 사고 내용...",
      "em": "불안 80%",
      "d": ["파국화", "점쟁이 오류"],
      "alt": "대안적 사고 내용...",
      "act": "실행 계획..."
    }
  ]
}
```
* **약어 필드 맵핑**:
  - `dt`: 작성 일시 (`yyyy-MM-dd HH:mm`)
  - `t`: 일기 유형 (`structuredCbt`)
  - `m`: 기분 (`moodEmoji + moodLabel`)
  - `sit`: 상황 (Situation)
  - `th`: 자동적 사고 (Automatic Thought)
  - `em`: 감정 (Emotion)
  - `d`: 인지 왜곡 유형 목록 (Distortions)
  - `alt`: 대안적 사고 (Alternative Thought)
  - `act`: 실행 계획 (Action Plan)

---

## 4. DDS-Clinician 수신 처리 JavaScript 예시 코드

```javascript
// URL에서 #data= 페이로드 추출 및 디코딩 함수
function parseAudistinePayload() {
  const hash = window.location.hash;
  if (!hash.includes('#data=')) return null;

  try {
    const base64Url = hash.split('#data=')[1];
    // Base64Url -> Base64 변환
    let base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    while (base64.length % 4) {
      base64 += '=';
    }
    // UTF-8 디코딩
    const jsonStr = decodeURIComponent(
      Array.prototype.map.call(atob(base64), function(c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
      }).join('')
    );
    return JSON.parse(jsonStr);
  } catch (err) {
    console.error('QR 데이터 디코딩 실패:', err);
    return null;
  }
}

// 화면 렌더링 분기
const payload = parseAudistinePayload();
if (payload) {
  if (payload.mode === 'batch') {
    console.log(`내담자의 ${payload.count}건 일기 목록 렌더링`);
    renderBatchTimeline(payload.entries);
  } else {
    console.log('단건 상세 인지 기록지 렌더링');
    renderSingleDiary(payload);
  }
}
```

---

## 5. DDS 개발 시 Antigravity에 요청할 수 있는 프롬프트 팁
새 폴더 `MyFlutter/DDS`를 열고 다음과 같이 말씀하시면 됩니다:
> **"audistine에서 상담자 연동 QR(또는 링크)로 보낸 5단계 인지 기록지 데이터를 받아서 상담자 화면에 보여주는 review 페이지를 구현해줘. 규격은 audistine의 CLINICIAN_QR_SPEC.md를 기반으로 해줘."**

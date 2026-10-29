# Jongnyang Gauge (종량제 쓰레기봉투 게이지)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-jongnyang-gauge
```

KR04 · 한국 현지화 시리즈. 상호작용 철학: **계량 게이지 Volume Gauge**. 이 Agent는 자 하나입니다. 왼쪽은 현재 봉투의 충전 눈금(리터 단위로 등록), 오른쪽은 장부입니다. 음식물 쓰레기 배출 횟수와 추정 요금, 내보낸 봉투 수. 눈금이 80%에 닿으면 "곧 가득 차요"라고 알려주고, 가득 차면 THROW(봉투를 묶어 배출)한 뒤 새 봉투를 열어야만 합니다. 화면 안에서 더 욱여넣을 수 있는 척은 하지 않습니다. 쓰레기 종류를 알아보지도 않습니다(분류는 각 지자체 안내서와 JP06식 규칙 카드의 일입니다). 지키는 것은 부피와 무게, 이 두 경제 장부뿐입니다. 봉투 용량은 포장에 인쇄된 숫자를 스캔해 설정할 수 있습니다(잠정 인식).

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/jongnyang-gauge/preview-jongnyang-gauge-index.png>)
![미리보기-s2](<../../screenshots/jongnyang-gauge/preview-jongnyang-gauge-s2.png>)
![미리보기-s3](<../../screenshots/jongnyang-gauge/preview-jongnyang-gauge-s3.png>)
![미리보기-s4](<../../screenshots/jongnyang-gauge/preview-jongnyang-gauge-s4.png>)

## 현지성

한국의 종량제는 쓰레기를 돈으로 바꾸는 제도입니다. 일반 쓰레기는 유료 표준 종량제 봉투에 넣어야 하고, 음식물쓰레기는 무게 칩으로 따로 요금이 매겨집니다. 봉투를 크게 사면 낭비, 작게 사면 다 담지 못하고, 음식물 쓰레기의 물기를 빼느냐 마느냐가 무게와 요금을 그대로 좌우합니다.

## 기능 흐름 (폐쇄 루프)

- 봉투 재기: +1L로 리터씩 충전량을 등록하면 게이지 눈금이 함께 오릅니다. 80%에서 음성 경고를 알립니다
- 음식물: FOOD로 음식물 쓰레기 배출을 한 번씩 등록합니다(1회 0.5kg 기준). 요금 추정이 나란히 누적됩니다(추정임을 명시)
- 배출: THROW로 봉투를 묶어 개수를 +1하고 눈금을 비웁니다. SCAN으로 봉투 포장의 용량 숫자를 스캔해 봉투 종류(10/20/50L)를 바꿀 수 있습니다

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(+1L와 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| `CAMERA` | 사진 확인 경로(기능 흐름 참조. 실패하면 SKIP) |

## 정직한 경계

- 충전량과 음식물 무게는 모두 손으로 등록한 기준 수치이며 저울로 잰 값이 아닙니다. 요금은 단가 기준 추정이며, 실제 금액은 각 지자체 단가가 기준입니다
- 봉투 종류 단가는 지역마다 다릅니다. 이 Agent는 부피와 횟수만 기록하고, 금액은 규모 참고용일 뿐입니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/jongnyang-gauge
~/tools/bin/aix pack . -o ../dist/jongnyang-gauge.aix
~/tools/bin/aix list ../dist/jongnyang-gauge.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Jongnyang Gauge (가져오기 후 기입 예정) |
| Version / Build | 1.0.3 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | At home in Korea: tracks standard trash-bag fill level and food-waste drop ledger. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 종량제 수거 게이지: 당신의 표준 봉투를 리터씩 오르는 부피 눈금으로 보여주고, 80% 경고를 알리며, 배출하면 봉투를 묶어 셉니다. 나란한 장부에는 음식물 쓰레기 배출과 명확히 추정이라 표시된 요금 추정이 기록됩니다. 재는 것은 부피와 습관입니다. 무게를 쟀다고도, 쓰레기를 분류했다고도 말하지 않습니다.

### Opening Message

> ## Jongnyang Gauge
> 
> 한국에서는 쓰레기가 계량되니, 저는 계량기입니다. 봉투가 차는 대로 리터를 기록하고, 눈금이 오르는 것을 지켜보고, 가득 차면 묶어서 다음 봉투를 시작하세요. 음식물 쓰레기 배출은 장부에 따로 한 줄씩 쌓입니다. 추정은 추정이라 표시됩니다.

### Preview Media

- `preview-jongnyang-gauge-index.png` — 초기 상태
- `preview-jongnyang-gauge-s2.png` — 데모 상태 2
- `preview-jongnyang-gauge-s3.png` — 데모 상태 3
- `preview-jongnyang-gauge-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 계량 게이지 Volume Gauge. 세로 게이지: 왼쪽 충전 눈금이 칸칸이 오르고, 오른쪽은 장부

**Improvements**

- 없음 (첫 버전)

**Fixes**

- 없음 (첫 버전)

### Change Log (Build 1.0.1)

**Features added**

- 없음

**Improvements**

- 버튼을 이 Agent의 UI 형태에 맞게 개별 스타일링했습니다(형태는 설계 계약 참조). 더 이상 시리즈 전체가 같은 버튼 세트를 공유하지 않습니다

**Fixes**

- 실제 기기의 단색 녹색 패널에 맞춘 색상 조정: 기존 순백 #ffffff를 녹색 계조로 바꿨고(가장 밝은 녹색 #7dff9e), 명암은 녹색만으로 표현합니다
- 게이지 눈금을 범용 블록 문자로 교체(기존 글리프가 미리보기 글꼴에 없어 네모로 표시되던 문제)

### Change Log (Build 1.0.2)

**Features added**

- 없음

**Improvements**

- 없음

**Fixes**

- 언어 순화: 화면과 음성 문구를 현지 언어(일본=일본어 / 한국=한국어)로 통일하고, 섞여 있던 일본어·중국어 문구(SCAN 프롬프트 포함)를 하나씩 점검해 제거했습니다

### Change Log (Build 1.0.3)

**Features added**

- 없음

**Improvements**

- 없음

**Fixes**

- FileReader 제거(Ink 런타임에 존재하지 않아 실기기에서 반드시 실패함): 사진 Blob→dataURL 변환을 공식 문서 경로인 `blob.arrayBuffer()` + 분할 `btoa`로 바꾸고, 실패 시 전 함대 오류 코드 E2005를 표시한다.

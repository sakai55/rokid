# Cafe Stamp (카페 스탬프 카드)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-cafe-stamp
```

**AIX 직접 다운로드**(최신 버전): [cafe-stamp.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/cafe-stamp.aix)

KR13 · 한국 현지화 시리즈. 상호작용 철학: **도장 카드 Stamp Card**. 이 Agent는 도장만 기록하는 카드 한 장입니다. 10칸 도장판에 커피 한 잔마다 STAMP로 도장 하나를 찍고, 10개가 차면 FREE로 무료 한 잔과 교환한 뒤 판을 비우고 다시 기록합니다. 잘못 찍으면 UNDO로 마지막 도장을 되돌립니다. 교환한 무료 잔 수는 따로 셉니다. 어떤 가게 시스템과도 연동되지 않고 잔액도 조회하지 않습니다. 카드 규칙(몇 개에 한 잔인지)은 가게 안의 고지가 기준이며, 화면에 명시됩니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/cafe-stamp/preview-cafe-stamp-index.png>)
![미리보기-s2](<../../screenshots/cafe-stamp/preview-cafe-stamp-s2.png>)
![미리보기-s3](<../../screenshots/cafe-stamp/preview-cafe-stamp-s3.png>)
![미리보기-s4](<../../screenshots/cafe-stamp/preview-cafe-stamp-s4.png>)

## 현지성

한국 카페의 스탬프 카드는 흔한 단골 제도입니다. 한 잔 사면 도장 하나, 10개를 모으면 무료 한 잔. 가장 헷갈리기 쉬운 것은 "이 카드에 도장이 몇 개 찍혔고, 무료 잔은 받았는지"입니다. 특히 여러 가게의 카드가 섞여 있을 때 그렇습니다. 안경은 QR을 스캔하지도, 가게를 알아보지도 않습니다. 이 카드 한 장의 도장 수와 교환만 지킵니다.

## 기능 흐름 (폐쇄 루프)

- 찍기: STAMP를 누를 때마다 도장 하나가 늘고 도장판이 실시간으로 채워집니다. 10개가 차면 큰 글자로 무료 교환 가능을 알립니다
- 교환: FREE는 도장 10개가 찼을 때만 동작합니다. 교환 후 도장판은 비워지고 무료 잔 수 +1. 차지 않았을 때는 음성으로 알리기만 하고 교환하지 않습니다
- 정정: UNDO로 마지막 도장을 되돌립니다. 잘못 찍으면 그 자리에서 고칠 수 있습니다. 교환한 무료 잔 수는 판을 비워도 사라지지 않고 따로 남습니다

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(STAMP와 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| (없음) | 이 Agent는 어떤 권한도 신청하지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다(해당하는 경우) |

## 정직한 경계

- 도장 수는 본인이 직접 등록합니다. Agent는 스캔하지 않고 가게 시스템과 연결되지 않습니다. 잘못 찍었으면 교환 전에 UNDO로 고치세요
- "10개에 한 잔"은 이 카드의 기준 수치입니다. 가게마다 규칙이 다르므로 가게 안 고지가 기준이며, 화면에 명시됩니다
- 무료 잔의 실제 교환은 직원 확인이 기준입니다. Agent의 FREE는 교환 의사와 결과 한 번을 기록할 뿐입니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/cafe-stamp
~/tools/bin/aix pack . -o ../dist/cafe-stamp.aix
~/tools/bin/aix list ../dist/cafe-stamp.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Cafe Stamp (가져오기 후 기입 예정) |
| Version / Build | 1.0.0 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | At a Korean cafe: tracks one stamp card toward ten stamps and records each free-drink redemption. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 카페 스탬프 카드: 카드 한 장, 도장 열 개, 무료 한 잔. 커피 한 잔마다 STAMP로 도장을 찍으면 열 칸짜리 카드가 눈앞에서 채워지고, FREE는 도장 열 개에서만 교환되며 카드를 비웁니다. UNDO는 잘못 찍은 도장을 되돌립니다. 스캔도, 가게 시스템 연동도 없습니다. 규칙은 가게의 고지가 정합니다.

### Opening Message

> ## Cafe Stamp
> 
> 스탬프 카드는 두 가지 작은 질문에서 어긋납니다. 도장이 몇 개 찍혔는지, 무료 잔을 받았는지. 저는 카드 한 장만 지킵니다. 열 칸, 커피 한 잔에 도장 하나, 카드가 찼을 때만 무료 한 잔. 잘못 찍은 도장은 바로 되돌립니다. 규칙은 제가 아니라 가게의 고지가 정합니다.

### Preview Media

- `preview-cafe-stamp-index.png` — 초기 상태
- `preview-cafe-stamp-s2.png` — 데모 상태 2
- `preview-cafe-stamp-s3.png` — 데모 상태 3
- `preview-cafe-stamp-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 도장 카드 Stamp Card. 도장 격자판: 10칸 도장 셀 + 교환 행

**Improvements**

- 없음 (첫 버전)

**Fixes**

- 없음 (첫 버전)

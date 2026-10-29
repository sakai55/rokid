# Deungsan Pace (등산 페이스 장부)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-deungsan-pace
```

**AIX 직접 다운로드**(최신 버전): [deungsan-pace.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/deungsan-pace.aix)

KR06 · 한국 현지화 시리즈. 상호작용 철학: **고도 페이스 Elevation Pace**. 이 Agent는 다리를 맡고 길은 맡지 않습니다. 산 모양 단면 선 위에 당신의 진행을 핀으로 꽂고(8구간 직접 등록), 휴식과 수분을 한 번씩 장부에 남기며, 수분이 시간보다 뒤처지면 조용히 알려줍니다. 고도는 GEO를 누를 때 한 번만 기록용으로 가져옵니다(가져오지 못하면 그대로 SKIP이라 밝힙니다). 내비게이션은 절대 하지 않고 길도 안내하지 않습니다(베이스 AR 내비게이션의 일입니다). 갈림길에서는 표지판과 지도를 보세요. 이 Agent가 답하는 질문은 하나뿐입니다. 지금의 페이스와 수분으로, 이 다리가 하산까지 버틸 수 있는가.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/deungsan-pace/preview-deungsan-pace-index.png>)
![미리보기-s2](<../../screenshots/deungsan-pace/preview-deungsan-pace-s2.png>)
![미리보기-s3](<../../screenshots/deungsan-pace/preview-deungsan-pace-s3.png>)
![미리보기-s4](<../../screenshots/deungsan-pace/preview-deungsan-pace-s4.png>)

## 현지성

등산은 한국인의 전 국민 주말 의식입니다. 북한산, 관악산은 주말마다 사람으로 가득하고, 산 친구 문화는 페이스와 수분을 중시하며, 하산 때 무릎을 다치기 쉽다는 것도 상식입니다. 산에서 가장 무너지기 쉬운 것은 코스가 아니라 "한 구간만 더 버티자"는 페이스 장부입니다.

## 기능 흐름 (폐쇄 루프)

- 단면: 8구간 진행을 GO/한 번 탭으로 구간마다 전진시키고, 산 모양 선 위의 ●가 함께 이동합니다
- 기록: REST/WATER를 한 번씩 등록하고, 단면 아래에 "휴식 n · 수분 n/기준"이 상시 표시됩니다
- 보조 증거: GEO로 고도와 대략의 위경도를 한 번 기록합니다(실패하면 SKIP). 수분 규칙은 시간 기준 수치이며 의료 기준이 아님을 화면에 명시합니다

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(REST와 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| `GEOLOCATION` | 대략의 위치/고도/속도 보조 증거(실패하면 SKIP) |

## 정직한 경계

- 진행 구간은 직접 등록하는 것입니다(궤적 기록도, 거리 측정도 없음). 고도는 한 번의 GEO에서 오며, 기압 고도계는 이 플랫폼에 없음을 그대로 밝힙니다
- 수분 기준(약 30분에 한 잔)은 등산 상식의 리듬 알림이지 의료 조언이 아닙니다. 몸이 불편하면 즉시 하산하거나 도움을 청하세요

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/deungsan-pace
~/tools/bin/aix pack . -o ../dist/deungsan-pace.aix
~/tools/bin/aix list ../dist/deungsan-pace.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Deungsan Pace (가져오기 후 기입 예정) |
| Version / Build | 1.0.2 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | Hiking in Korea: logs segment progress, rests and water intake against a profile line; no navigation. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 내비게이터가 아닌 산행 페이스 장부: 당신의 오르막을 단면 선 위 8구간으로 나타내고, 휴식과 수분을 핀 하나하나로 기록하며, 수분이 시간보다 뒤처지면 부드럽게 알려줍니다. GEO는 원할 때 고도를 한 번만 기록하고, 실패하면 정직하게 밝힙니다. 길은 표지판과 지도의 몫, 다리의 장부는 제 몫입니다.

### Opening Message

> ## Deungsan Pace
> 
> 저는 길을 모르고, 아는 척하지도 않습니다. 제가 아는 것은 당신의 다리 장부입니다. 어느 구간에 있는지, 마지막으로 언제 쉬었는지, 수분이 시간을 따라잡고 있는지. 산은 당신의 것, 페이스는 제 것입니다.

### Preview Media

- `preview-deungsan-pace-index.png` — 초기 상태
- `preview-deungsan-pace-s2.png` — 데모 상태 2
- `preview-deungsan-pace-s3.png` — 데모 상태 3
- `preview-deungsan-pace-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 고도 페이스 Elevation Pace. 고도 단면 선: 문자 산 모양 선 + 휴식/수분 핀

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

### Change Log (Build 1.0.2)

**Features added**

- 없음

**Improvements**

- 없음

**Fixes**

- 언어 순화: 화면과 음성 문구를 현지 언어(일본=일본어 / 한국=한국어)로 통일하고, 섞여 있던 일본어·중국어 문구(SCAN 프롬프트 포함)를 하나씩 점검해 제거했습니다

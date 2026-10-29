# Jjimjil Rest (찜질 냉열 순환)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-jjimjil-rest
```

> **퇴역 보존 (2026-10-25, GO 결정)**: 찜질방의 고온방에서는 아무도 스마트 안경을 쓰지 않고, 고온과 증기는 안경을 망가뜨립니다. 이 Agent의 사용 환경은 생활 상식에서 성립하지 않습니다. 오늘부터 한일 시리즈 현역 라인업에서 물러나고, KR09는 `pcbang-session`(PC방 좌석 세션 장부)이 이어받습니다. 프로젝트와 가져오기 주소는 참고용으로 보존하고 삭제하지 않습니다.

KR09 · 한국 현지화 시리즈. 상호작용 철학: **냉열 순환 Thermal Cycle**. 이 Agent는 순환 리듬만 맡습니다. 열 구간 12분, 휴식 구간 8분, 두 링이 번갈아 돌고 현재 링이 가득 밝아지며, 구간이 끝나면 작게 한 번 알리고 자동으로 다음 구간으로 넘어갑니다. "얼마나 더 있어야 하지"를 의지력의 문제에서 두 링을 한 번 보는 문제로 바꿉니다. 먼저 밝혀 둡니다. 어떤 효능 약속도 하지 않고(해독, 치료 같은 말은 일절 하지 않음), 체온과 심박도 재지 않으며(플랫폼에 그 능력이 없음), 찜질방 규칙을 아는 타이머 링일 뿐입니다. 열 구간 시간을 넘겨 나가지 않으면 한 번 더 알려줄 뿐, 그 이상은 없습니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/jjimjil-rest/preview-jjimjil-rest-index.png>)
![미리보기-s2](<../../screenshots/jjimjil-rest/preview-jjimjil-rest-s2.png>)
![미리보기-s3](<../../screenshots/jjimjil-rest/preview-jjimjil-rest-s3.png>)
![미리보기-s4](<../../screenshots/jjimjil-rest/preview-jjimjil-rest-s4.png>)

## 현지성

찜질방의 놀이 방식은 순환입니다. 고온방에서 땀을 한바탕 빼고, 나와서 휴게실에서 식혜와 구운 달걀을 먹고, 회복되면 다시 들어갑니다. 리듬이 맞으면 즐거움이고, 리듬이 어긋나면, 열방에 너무 오래 있으면, 고생이 됩니다.

## 기능 흐름 (폐쇄 루프)

- 두 링: 열 링(12:00)/휴식 링(08:00)이 번갈아 돌고, 현재 링은 큰 글자 카운트다운, 현재가 아닌 링은 전체 길이를 표시합니다
- 전환: 구간이 끝나면 자동 전환 + TTS 한 마디. SWITCH로 수동으로 건너뛸 수 있고, +2MIN은 현재 구간에 시간을 더합니다(연장은 그대로 표시됩니다)
- 마무리: 한 바퀴(열+휴식)를 1순환으로 세고, 순환 수가 상시 표시됩니다. 전 과정에 걸쳐 건강 단정은 전혀 없으며, 화면에는 「节奏だけ」(리듬만이라는 뜻, 화면 문구 그대로)라고 적혀 있습니다

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(START와 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| (없음) | 이 Agent는 어떤 권한도 신청하지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다(해당하는 경우) |

## 정직한 경계

- 시간 길이는 찜질방의 흔한 리듬 기준입니다. 개인마다 견디는 정도가 다르니 언제든 방을 나가세요. 이 Agent는 어떤 의료·효능 판단도 제공하지 않습니다
- 타이머는 페이지가 숨겨지면 멈추고(Ink 라이프사이클), 페이지로 돌아오면 이어서 셉니다. README에 명시합니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/jjimjil-rest
~/tools/bin/aix pack . -o ../dist/jjimjil-rest.aix
~/tools/bin/aix list ../dist/jjimjil-rest.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Jjimjil Rest (가져오기 후 기입 예정) |
| Version / Build | 1.0.1 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | In a Korean jjimjilbang: alternates hot-room and rest timers in a two-ring cycle display. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 찜질방 냉열 순환 링: 열 12분, 휴식 8분, 두 링이 번갈아 돌고 전환 때마다 한 마디씩 알립니다. 찜질방의 리듬을 지켜줄 뿐, 건강에 대한 주장은 전혀 하지 않습니다. 온도도, 해독 이야기도 없이, 원 안에 담긴 시간만 있습니다.

### Opening Message

> ## Jjimjil Rest
> 
> 고온방, 휴게실, 반복. 찜질방은 순환으로 돌아가고, 의지력은 나쁜 타이머입니다. 두 개의 링이 리듬을 대신 지켜줍니다. 열에서 열두 분, 시원한 곳에서 여덟 분, 움직일 때가 되면 조용한 한 마디를 건넵니다.

### Preview Media

- `preview-jjimjil-rest-index.png` — 초기 상태
- `preview-jjimjil-rest-s2.png` — 데모 상태 2
- `preview-jjimjil-rest-s3.png` — 데모 상태 3
- `preview-jjimjil-rest-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 냉열 순환 Thermal Cycle. 두 링: 열 링과 휴식 링이 번갈아 밝아지고, 링 중심이 남은 시간

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

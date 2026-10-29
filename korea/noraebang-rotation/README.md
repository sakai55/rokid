# Noraebang Rotation (노래방 공정 순번)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-noraebang-rotation
```

**AIX 직접 다운로드**(최신 버전): [noraebang-rotation.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/noraebang-rotation.aix)

KR07 · 한국 현지화 시리즈. 상호작용 철학: **공정 순번 Fair Rotation**. 이 Agent가 바로 그 원판입니다. 가수 네 명의 이름이 고리 모양으로 놓이고, 현재 가수는 큰 글자로 가운데에, 이전과 다음 사람은 반쯤 밝게 대기합니다. 곡마다 예약 번호가 가수 이름 아래 등록되고, 다 부르면 DONE으로 자동 순환합니다. PASS는 대놓고 하는 양보입니다(「양보」로 기록되며, 몰래 부른 것으로 세지 않습니다). 노래 실력을 듣지도, 점수를 매기지도, 녹음하지도 않습니다(그건 베이스 전사와 채점기 업체의 일). 지키는 것은 공정함 한 가지뿐입니다. 마이크가 누구 손에 있어야 하는가.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/noraebang-rotation/preview-noraebang-rotation-index.png>)
![미리보기-s2](<../../screenshots/noraebang-rotation/preview-noraebang-rotation-s2.png>)
![미리보기-s3](<../../screenshots/noraebang-rotation/preview-noraebang-rotation-s3.png>)
![미리보기-s4](<../../screenshots/noraebang-rotation/preview-noraebang-rotation-s4.png>)

## 현지성

노래방은 한국 모임의 2차 단골 코스이고, 규칙은 하나뿐입니다. 번갈아 부르고, 누구도 마이크를 독차지할 수 없고, 누구도 빠지면 안 됩니다. 실제 방에서는 세 곡을 내리 부르는 사람도 있고, 밤새 마이크를 잡지 못하는 사람도 있습니다. 부족한 것은 규칙이 아니라 편들지 않는 원판입니다.

## 기능 흐름 (폐쇄 루프)

- 원판: 네 사람의 고리 순서가 상시 유지되고, 현재 가수는 가득 밝은 큰 글자, 앞뒤 자리는 반쯤 밝게 표시됩니다
- 곡 등록: SONG#이 현재 가수에게 예약 번호 프리셋을 번갈아 등록합니다(부르기 전에 노래방 기기에 번호를 알려줌)
- 순환: DONE/고개 끄덕임 = 다 불렀으니 순환. PASS = 이번 라운드 양보(고리에 양보로 표시되고, 다음 라운드에 맨 앞으로 우선 복귀)

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(DONE과 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| (없음) | 이 Agent는 어떤 권한도 신청하지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다(해당하는 경우) |

## 정직한 경계

- 이름은 데모용 네 사람입니다. 인원 증감은 만들지 않았습니다(고리 순서 로직은 지원하며, 등록 UI는 후속 과제)
- 예약 번호는 주류 노래방 기기의 번호 기준 수치입니다. 실제로는 방 안 기기의 곡 목록이 기준이며, 이 Agent는 온라인으로 곡을 찾지 않습니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/noraebang-rotation
~/tools/bin/aix pack . -o ../dist/noraebang-rotation.aix
~/tools/bin/aix list ../dist/noraebang-rotation.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Noraebang Rotation (가져오기 후 기입 예정) |
| Version / Build | 1.0.2 / 가져오기 후 기입 예정 |
| App Category | Entertainment |
| Intent Description | In a Korean noraebang: rotates singing turns fairly and holds song reservation numbers. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 노래방 공정 순번 원판: 가수 네 명이 고리 위에 있고, 현재 차례는 가운데에 크게, 이전과 다음은 반쯤 밝게. 곡 예약 번호는 가수별로 보관되고, DONE이 마이크를 돌리며, PASS는 대놓고 양보하고 다음 라운드에 먼저 돌아옵니다. 채점도, 녹음도 없습니다. 공정함이 기계의 전부입니다.

### Opening Message

> ## Noraebang Rotation
> 
> 어느 방에나 마이크를 독차지하는 사람과 구석에 앉은 사람이 있습니다. 저는 둘 다 고치는 원판입니다. 당신 차례에는 이름이 크게 뜨고, 곡 번호는 준비돼 있으며, 양보는 대놓고 하고 다음 라운드에 먼저 돌아옵니다.

### Preview Media

- `preview-noraebang-rotation-index.png` — 초기 상태
- `preview-noraebang-rotation-s2.png` — 데모 상태 2
- `preview-noraebang-rotation-s3.png` — 데모 상태 3
- `preview-noraebang-rotation-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 공정 순번 Fair Rotation. 원탁 원판: 이전 사람/현재 큰 글자/다음 사람 + 이름 고리

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

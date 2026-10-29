# Hangang Base (한강 베이스캠프 지킴이)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-hangang-base
```

**AIX 직접 다운로드**(최신 버전): [hangang-base.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/hangang-base.aix)

KR05 · 한국 현지화 시리즈. 상호작용 철학: **베이스캠프 지킴이 Basecamp Holder**. 이 Agent는 돗자리에 앉아 있는 그 사람입니다. 배달 지점 코드, 음식 수령 번호, 돗자리 반납 시각, 정리(片付け) 네 가지가 돗자리 면의 네 칸에 모두 고정됩니다. 당신이 놀러 가 있는 동안 대신 앉아서 기억하고, 돌아와 한 번 흘끗 보면 네 칸의 상태가 한눈에 들어옵니다. 배달 지점까지 길 안내를 하지도(베이스 내비게이션의 일), 대신 주문해 주지도 않습니다. 지키는 것은 "베이스캠프 정보" 한 가지뿐입니다. 밖에 나가 놀 때 즐거움에 가장 흩어지기 쉬운 주의가 바로 이것입니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/hangang-base/preview-hangang-base-index.png>)
![미리보기-s2](<../../screenshots/hangang-base/preview-hangang-base-s2.png>)
![미리보기-s3](<../../screenshots/hangang-base/preview-hangang-base-s3.png>)
![미리보기-s4](<../../screenshots/hangang-base/preview-hangang-base-s4.png>)

## 현지성

주말의 한강공원에는 익숙한 놀이 방식이 있습니다. 돗자리로 자리를 잡고, 지정된 배달 지점에서 음식을 받아 오고, 먹고 나면 돗자리와 쓰레기를 규칙대로 치우는 것입니다. 베이스캠프를 펴는 순간 사람들은 흩어집니다. 사진 찍는 사람, 연 날리는 사람, 음식 받으러 가는 사람. 결국 모든 자질구레한 일은 한 사람이 기억하게 됩니다.

## 기능 흐름 (폐쇄 루프)

- 네 칸: 코드(배달 지점 코드)/수령 번호/돗자리 반납 시각/정리 진도가 돗자리 면의 칸에 그대로 들어갑니다
- 순환: CODE로 배달 지점 코드 프리셋을 바꾸고, FOOD#로 수령 번호 +1, CLEAN으로 정리 네 가지를 하나씩 진행합니다
- 알림: GO가 네 칸의 현재 상태를 번갈아 읽어 줍니다. 반납 시각이 되면 이 페이지의 타이머가 알립니다(페이지 메모리 타이머, 명시됨)

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(CODE와 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| (없음) | 이 Agent는 어떤 권한도 신청하지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다(해당하는 경우) |

## 정직한 경계

- 코드와 번호표는 데모 프리셋입니다. 실제로 쓸 때는 CODE/FOOD#에 그때의 실제 값을 등록하세요(등록하면 바로 표시되고, 페이지를 닫으면 잊어버립니다)
- 반납 알림은 이 페이지의 타이머이지 시스템 알람이 아닙니다. 페이지가 닫힌 뒤에는 도달을 보장하지 않으니, 중요한 반납은 휴대폰 알림도 함께 설정하세요

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/hangang-base
~/tools/bin/aix pack . -o ../dist/hangang-base.aix
~/tools/bin/aix list ../dist/hangang-base.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Hangang Base (가져오기 후 기입 예정) |
| Version / Build | 1.0.2 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | At a Hangang park picnic: holds delivery code, pickup number, return time and cleanup progress on a mat grid. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 한강 피크닉 베이스캠프 지킴이: 당신의 돗자리가 네 칸이 됩니다. 배달 지점 코드, 수령 번호, 돗자리 반납 시각, 정리 진도. 당신이 멀리 놀러 가도 베이스캠프는 앉아서 기억합니다. GO를 한 번 탭하면 네 칸을 소리 내어 읽어 줍니다. 길 안내도, 주문도 없습니다. 자리의 정보를 지킬 뿐, 그 이상은 하지 않습니다.

### Opening Message

> ## Hangang Base
> 
> 돗자리는 베이스캠프이고, 베이스캠프는 아무것도 잊지 않습니다. 배달 코드, 수령 번호, 반납 시각, 정리. 원하는 만큼 멀리 다녀오세요. 돗자리를 한 번 흘끗 보거나 한 번 탭하면 캠프 전체가 보고합니다.

### Preview Media

- `preview-hangang-base-index.png` — 초기 상태
- `preview-hangang-base-s2.png` — 데모 상태 2
- `preview-hangang-base-s3.png` — 데모 상태 3
- `preview-hangang-base-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 베이스캠프 지킴이 Basecamp Holder. 위에서 본 피크닉 돗자리: 돗자리 면 네 칸에 각각 코드, 번호표, 반납, 정리(片付け)를 배치

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

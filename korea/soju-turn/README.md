# Soju Turn (소주 예절 고개 돌리기 안무)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-soju-turn
```

**AIX 직접 다운로드**(최신 버전): [soju-turn.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/soju-turn.aix)

KR03 · 한국 현지화 시리즈. 상호작용 철학: **존중 안무 Respect Choreography**. 이 Agent가 안무하는 것은 바로 몸입니다. 네 단계 고정 무대(두 손으로 잔 받기→두 손으로 술 따르기→고개 돌려 마시기→빈 잔 확인) 중 "고개 돌리기" 단계는 머리 편향 센서로 판정합니다. 기준선에서 35° 넘게 돌렸다가 바로 돌아와야 완료로 셉니다. 고개를 돌리는 방향과 크기가 곧 상호작용 자체입니다. 어른이 자리에 없으면(ELDER 전환) 그 단계는 마주 보고 마시기로 자동 바뀌어, 규칙이 자리에 따라 달라집니다. 술자리를 녹음하지도, 건배사를 받아쓰지도 않으며(베이스의 일), 젊은이 몸의 방향만 지킵니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/soju-turn/preview-soju-turn-index.png>)
![미리보기-s2](<../../screenshots/soju-turn/preview-soju-turn-s2.png>)
![미리보기-s3](<../../screenshots/soju-turn/preview-soju-turn-s3.png>)
![미리보기-s4](<../../screenshots/soju-turn/preview-soju-turn-s4.png>)

## 현지성

한국 회식의 소주 예절은 몸으로 하는 것입니다. 어른께 술을 드릴 때는 두 손으로 따르고(두 손으로 따르기), 자기가 마실 때는 고개를 돌려 마시고(고개를 돌려 마시기), 빈 잔이어야 다시 채워집니다. 규칙은 입이 아니라 손과 머리의 방향에 있고, 신입이 가장 두려워하는 것은 몸이 규칙을 따라가지 못하는 것입니다.

## 기능 흐름 (폐쇄 루프)

- 자리 배치: 무대 그림에 "당신 ↔ 어른" 상대 방향이 상시 표시되고, 어른의 참석 상태를 전환할 수 있습니다
- 안무: 네 단계가 순서대로 진행됩니다(잔 받기/따르기/고개 돌리기/빈 잔). 고개 돌리기 단계는 머리 편향 >35°로 자동 판정합니다(센서가 없으면 탭 확인으로 격하)
- 순환: 한 바퀴를 마치면 잔 받기로 돌아오고 순환 수를 셉니다. 빈 잔 상태는 GLASS로 직접 등록합니다(가득/빔/더 따르기 대기)

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(NEXT와 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| (없음) | 이 Agent는 어떤 권한도 신청하지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다(해당하는 경우) |

## 정직한 경계

- 편향 각도는 기준선에 대한 머리 회전이며 예절 점수가 아닙니다. 임계값 35°는 실기기 보정을 기다리는 값입니다
- 센서를 쓸 수 없으면 고개 돌리기 단계는 본인 확인으로 격하하고 화면에 명시합니다. 이 Agent는 음주량에 대한 건강 조언을 하지 않으니, 과음은 스스로 조절하세요

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/soju-turn
~/tools/bin/aix pack . -o ../dist/soju-turn.aix
~/tools/bin/aix list ../dist/soju-turn.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Soju Turn (가져오기 후 기입 예정) |
| Version / Build | 1.0.2 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | At a Korean hoesik dinner: choreographs soju etiquette stages, judging the head-turn by head yaw. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 회식 소주 안무: 두 손으로 받고, 두 손으로 따르고, 어른이 계시면 고개를 돌려 마시고, 빈 잔을 보여줍니다. 고개 돌리기 단계는 실제 머리 편향으로 판정합니다. 당신의 몸 방향이 곧 입력입니다. 어른 참석을 끄면 돌리기 단계가 정중히 비켜섭니다.

### Opening Message

> ## Soju Turn
> 
> 회식에서 존중은 안무입니다. 두 손으로 받고, 두 손으로 따르고, 고개를 돌려 마시기. 제가 네 단계를 무대에 올리고, 돌리기는 당신의 머리로 판정합니다. '어른 참석'을 끄면 돌리기 단계가 옆으로 비켜섭니다.

### Preview Media

- `preview-soju-turn-index.png` — 초기 상태
- `preview-soju-turn-s2.png` — 데모 상태 2
- `preview-soju-turn-s3.png` — 데모 상태 3
- `preview-soju-turn-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 존중 안무 Respect Choreography. 무대 자리 그림: 당신과 어른의 상대 방향 + 가운데 고개 돌리기 호

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

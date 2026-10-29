# Gye Circle (계 순번 장부)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-gye-circle
```

KR12 · 한국 현지화 시리즈. 상호작용 철학: **계 원형 Gye Circle**. 이 Agent는 순번만 기록하는 계 장부입니다. 네 사람이 번갈아 "이번에 받는 사람"이 되고, 원판 중앙이 바로 이번 달 수령인입니다. PAY로 이번 달 납부가 완료됐음을 기록해야 NEXT가 원판을 다음 사람으로 돌립니다. 납부가 끝나지 않았는데 돌리려 하면 음성 알림이 막아섭니다. 한 바퀴를 다 돌면 한 라운드로 셉니다. 돈을 받지도, 이자를 계산하지도, 누구에게 독촉하지도 않으며, 화면에 명시됩니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/gye-circle/preview-gye-circle-index.png>)
![미리보기-s2](<../../screenshots/gye-circle/preview-gye-circle-s2.png>)
![미리보기-s3](<../../screenshots/gye-circle/preview-gye-circle-s3.png>)
![미리보기-s4](<../../screenshots/gye-circle/preview-gye-circle-s4.png>)

## 현지성

계모임(계)은 한국 지인들 사이에서 번갈아 돈을 내고 번갈아 받는 상호부조 제도입니다. 매달 각자 한 몫씩 내고, 차례가 된 한 사람이 한 번에 받습니다. 가장 헷갈리기 쉬운 것은 금액이 아니라 "이번에 누가 받을 차례인지, 이번 달 다들 냈는지"입니다. 안경은 돈을 만지지 않습니다. 순번과 납부 완료 확인만 기록하고, 금액과 주고받음은 여전히 구성원들이 직접 처리합니다.

## 기능 흐름 (폐쇄 루프)

- 원판 유지: 지영→민준→서연→현우 네 사람의 순서, 중앙이 이번 달 수령인이고 앞뒤 두 사람이 위아래에 나뉘어 표시됩니다
- 납부 확인: PAY로 본인이 이번 달 납부 완료를 확인한 뒤에야 원판을 돌릴 수 있습니다. 납부가 안 됐을 때 NEXT는 음성 알림만 하고 돌리지 않습니다
- 라운드 계산: 한 바퀴를 다 돌면 한 라운드로 세고, 라운드 수는 따로 셉니다. 금액과 주고받는 방식은 구성원들이 직접 정하고 Agent는 관여하지 않습니다

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(PAY와 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| (없음) | 이 Agent는 어떤 권한도 신청하지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다(해당하는 경우) |

## 정직한 경계

- Agent는 어떤 돈도 만지지 않습니다. 금액을 기록하지 않고, 이자를 계산하지 않고, 납부를 독촉하지 않습니다. "누구 차례인지"와 "냈는지"만 기록합니다
- 납부 여부는 본인이 확인합니다. Agent는 은행이나 이체 확인을 하지 않습니다. 순서와 금액 규칙은 그 계모임 구성원들의 약속이 기준입니다
- 구성원 이름은 예시 순서입니다. 실제 구성원과 순서는 본인 계모임의 약속이 기준입니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/gye-circle
~/tools/bin/aix pack . -o ../dist/gye-circle.aix
~/tools/bin/aix list ../dist/gye-circle.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Gye Circle (가져오기 후 기입 예정) |
| Version / Build | 1.0.0 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | At a Korean gye gathering: tracks whose turn it is to receive and whether this month is marked paid. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 계 원판: 한국의 순번 저축 모임인 계를 순서대로 지켜줍니다. 네 구성원이 번갈아 받고, 원판에는 이번 달 수령인이 가운데에, 이전과 다음 구성원이 양옆에 표시되며, 원판은 이번 달 납부가 완료로 표시된 뒤에만 돌아갑니다. 돈을 만지지 않고, 금액을 기록하지 않고, 누구도 독촉하지 않습니다.

### Opening Message

> ## Gye Circle
> 
> 계는 모두가 누구 차례인지, 이번 달이 정산됐는지를 알 때만 굴러갑니다. 제가 그 원판을 지킵니다. 네 구성원이 번갈아 서고, 이번 달 수령인이 가운데에 있으며, 원판은 이번 달 납부가 완료로 표시된 뒤에 돌아갑니다. 돈을 만지지 않고 독촉하지 않습니다. 모임은 구성원들의 것입니다.

### Preview Media

- `preview-gye-circle-index.png` — 초기 상태
- `preview-gye-circle-s2.png` — 데모 상태 2
- `preview-gye-circle-s3.png` — 데모 상태 3
- `preview-gye-circle-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 계 원형 Gye Circle. 계 원형 휠: 받을 차례 + 이전/다음 사람 + 납부 여부

**Improvements**

- 없음 (첫 버전)

**Fixes**

- 없음 (첫 버전)

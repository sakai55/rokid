# PCbang Session (PC방 좌석 세션 장부)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-pcbang-session
```

**AIX 직접 다운로드**(최신 버전): [pcbang-session.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/pcbang-session.aix)

KR09 · 한국 현지화 시리즈. 상호작용 철학: **좌석 장부 Seat Ledger**. 이 Agent는 좌석 장부 한 권만 기록합니다. 시스템이 한 시간이 찼다고 알릴 때마다 본인이 +1H를 한 번 누르거나(또는 고개를 끄덕여) 시간 블록 하나를 기록합니다. 음식을 시킬 때는 ORDER로 한 건씩 기록하고(스와이프로 메뉴 후보를 바꿈), 자리를 뜰 때는 END가 예상 정산액(PC 이용료+음식값)을 보여줘 마음의 준비를 하게 합니다. PC방 관리 시스템과 연동되지 않고(요금과 총액은 카운터 정산이 기준), 대신 주문하지 않으며(주문은 여전히 좌석 화면에서), 쉬라고 알리지도 않습니다(건강 앱의 일). 보장하는 것은 딱 하나, 이 좌석의 시간과 먹은 것, 당신이 직접 기록한 장부입니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/pcbang-session/preview-pcbang-session-index.png>)
![미리보기-s2](<../../screenshots/pcbang-session/preview-pcbang-session-s2.png>)
![미리보기-s3](<../../screenshots/pcbang-session/preview-pcbang-session-s3.png>)
![미리보기-s4](<../../screenshots/pcbang-session/preview-pcbang-session-s4.png>)

## 현지성

PC방은 한국의 생활 인프라입니다. 시간제로 요금이 매겨지고, 좌석에서 음식을 주문해 자리까지 가져다주며, 라면과 음료값은 PC 이용료와 함께 정산됩니다. 게임에 몰입한 사람은 가장 정신을 빼앗기기 쉽습니다. 시스템이 「1시간 경과」를 알릴 때 손은 키보드와 마우스 위에 있고, 무엇을 시켰고 얼마나 쌓였는지는 자리를 떠나 계산할 때야 알게 됩니다.

## 기능 흐름 (폐쇄 루프)

- 시간 기록: +1H로 시간 블록을 하나씩 등록합니다(고개 끄덕임 = +1H). 요금은 ₩1,000/h가 기준 단가입니다
- 음식 기록: 스와이프로 메뉴 후보를 고르고, ORDER로 한 건씩 등록하면 음식값이 실시간으로 누적됩니다
- 정산: END가 예상 총액(PC 이용료와 음식값을 나눠 표시)을 보여주고, 다시 누르면 새 세션입니다

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(+1H와 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| (없음) | 이 Agent는 어떤 권한도 신청하지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다(해당하는 경우) |

## 정직한 경계

- 시간 블록은 본인이 하나씩 등록하는 것이지 PC방 관리 시스템과의 실시간 연동이 아닙니다. 요금은 데모 기준(₩1,000/h)이며, 실제로는 가게 가격표와 카운터 정산이 기준입니다
- 주문은 로컬 장부에만 기록되고 실제로 주방에 전송되지 않습니다. 주문은 여전히 좌석 화면에서 합니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/pcbang-session
~/tools/bin/aix pack . -o ../dist/pcbang-session.aix
~/tools/bin/aix list ../dist/pcbang-session.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | PCbang Session (가져오기 후 기입 예정) |
| Version / Build | 1.0.1 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | In a Korean PC cafe: logs hour blocks and seat food orders into a running estimated bill. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> PC방 좌석 장부: 한국 PC방을 위한 자리 장부입니다. 매장 시스템이 알릴 때마다 탭이나 고개 끄덕임으로 시간 블록을 기록하고, 간식과 음료 주문을 자리에서 기록하면, 카운터로 가기 전에 누적된 예상 청구액(PC 시간 + 음식)을 볼 수 있습니다. PC방 자체 과금 시스템과는 연결되지 않습니다. 기준은 카운터 총액입니다.

### Opening Message

> ## PCbang Session
> 
> 게임에 깊이 빠지면 시간과 라면이 조용히 쌓입니다. 제가 당신의 좌석 장부를 지킵니다. 시간 블록마다 한 번 탭, 주문마다 한 번 탭, 그리고 위를 흘끗 볼 때마다 예상 청구액(시간 + 음식)을 보여줍니다. 카운터 총액이 진짜입니다. 제 장부는 당신이 놀라지 않게 해줄 뿐입니다.

### Preview Media

- `preview-pcbang-session-index.png` — 초기 상태
- `preview-pcbang-session-s2.png` — 데모 상태 2
- `preview-pcbang-session-s3.png` — 데모 상태 3
- `preview-pcbang-session-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 좌석 장부 Seat Ledger. 모니터 테두리 화면: 테두리 안 세 줄 장부(시간/주문/후보) + 큰 글자 예상 정산액

**Improvements**

- 없음 (첫 버전)

**Fixes**

- 없음 (첫 버전)

### Change Log (Build 1.0.1)

**Features added**

- 없음

**Improvements**

- 없음

**Fixes**

- 언어 순화: 화면과 음성 문구를 현지 언어(일본=일본어 / 한국=한국어)로 통일하고, 섞여 있던 일본어·중국어 문구(SCAN 프롬프트 포함)를 하나씩 점검해 제거했습니다

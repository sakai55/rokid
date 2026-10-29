# Hanbok Rental (한복 대여 장부)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-hanbok-rental
```

KR11 · 한국 현지화 시리즈. 상호작용 철학: **의류 확인 Garment Check**. 이 Agent는 한복 대여 확인표 한 장입니다. 대여 물품 네 점(상의, 치마, 장신구, 가방)을 한 점씩 확인하고, 포커스 마커가 현재 항목을 가리키며, 남은 시간이 큰 글자로 표시되고, 연장은 30분 단위로 더해집니다. 네 점을 모두 확인하면 GO가 한 번에 "반납 가능"으로 표시하고, 그다음은 당신이 가게에 직접 반납합니다. 촬영으로 시간을 재지도, 옷을 알아보지도 않습니다. 지키는 것은 두 가지뿐입니다. 점수가 다 찼는지, 시간이 얼마나 남았는지.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/hanbok-rental/preview-hanbok-rental-index.png>)
![미리보기-s2](<../../screenshots/hanbok-rental/preview-hanbok-rental-s2.png>)
![미리보기-s3](<../../screenshots/hanbok-rental/preview-hanbok-rental-s3.png>)
![미리보기-s4](<../../screenshots/hanbok-rental/preview-hanbok-rental-s4.png>)

## 현지성

한국의 궁궐 일대에는 한복 대여점이 늘어서 있다. 한복을 입고 궁궐에 들어가고, 정해진 시간 안에 저고리, 치마, 장신구, 가방을 빠짐없이 반납해야 한다. 빠진 물품 하나가 보증금 문제로 이어지기 쉽다.

## 기능 흐름 (폐쇄 루프)

- 한 점씩 확인: 물품 네 점이 각 한 줄, 포커스 줄에 마커가 붙습니다. CHECK로 한 점씩 체크하거나 취소하고, 고개 끄덕임이 현재 항목의 CHECK와 같습니다
- 시간 유지: 남은 시간이 큰 글자로 표시되고, EXTEND로 30분 단위 연장이 됩니다. 시간은 사용자가 등록한 대여 기간으로만 흐릅니다
- 반납 확인: 네 점을 모두 확인하면 GO가 반납 가능으로 표시하고 TTS로 알립니다. 아니면 GO는 몇 점이 부족한지만 알립니다

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

- 대여 기간, 대여료, 보증금 규칙은 가게마다 다릅니다. 이 장부는 사용자가 등록한 시간과 물품으로만 움직이고 가게 시스템과 연동되지 않으며, 화면에 명시됩니다
- 물품이 실제로 손에 있는지, 온전한지는 본인이 눈으로 확인합니다. Agent는 카메라로 확인하지 않습니다
- 궁궐 입장 규칙은 현장 고지가 기준입니다. Agent는 실시간 조회를 하지 않습니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/hanbok-rental
~/tools/bin/aix pack . -o ../dist/hanbok-rental.aix
~/tools/bin/aix list ../dist/hanbok-rental.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Hanbok Rental (가져오기 후 기입 예정) |
| Version / Build | 1.0.0 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | At a hanbok rental shop near a palace: checks four rented pieces and holds the remaining rental time. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 궁궐 일대 대여점을 위한 한복 대여 체크리스트: 대여 물품 네 점(상의, 치마, 장신구, 가방)을 포커스 마커와 함께 한 점씩 확인하고, 남은 대여 시간은 크게 표시되며, 연장은 한 번에 30분씩 더해집니다. 네 점이 모두 확인되면 GO가 반납 준비 완료로 표시합니다. 옷을 촬영하거나 알아보지 않고, 당신이 확인한 것만 셉니다.

### Opening Message

> ## Hanbok Rental
> 
> 빌린 한복은 네 점이고, 한 점이 빠지면 보증금 문제가 됩니다. 제가 체크리스트를 지킵니다. 상의, 치마, 장신구, 가방, 각 한 줄씩, 포커스는 당신이 들고 있는 물품 위에. 남은 시간은 화면에 크게 남아 있고, 연장은 30분씩 더해지며, 네 점이 모두 확인되면 반납 준비가 됐다고 알려드립니다.

### Preview Media

- `preview-hanbok-rental-index.png` — 초기 상태
- `preview-hanbok-rental-s2.png` — 데모 상태 2
- `preview-hanbok-rental-s3.png` — 데모 상태 3
- `preview-hanbok-rental-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 의류 확인 Garment Check. 의류 네 줄 표: 각 물품 한 줄에 포커스 마커 + 큰 글자 남은 시간

**Improvements**

- 없음 (첫 버전)

**Fixes**

- 없음 (첫 버전)

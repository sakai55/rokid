# Samgyeop Flip (삼겹살 뒤집기 박자)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-samgyeop-flip
```

**AIX 직접 다운로드**(최신 버전): [samgyeop-flip.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/samgyeop-flip.aix)

KR01 · 한국 현지화 시리즈. 상호작용 철학: **불판 박자 Grill Metronome**. 이 Agent는 불판 위의 메트로놈입니다. 한 면 45초, 뒤집고, 한 면 40초. 시간이 되면 「뒤집으세요」 한 마디만 외치고, 나머지 시간에는 불판 가운데의 큰 초 숫자만 표시합니다. 익은 정도는 판단하지 않습니다(어떤 센서도 당신 대신 판단할 수 없으며, 화면에 명시됩니다). 지키는 것은 박자와 진행뿐입니다. 몇 면을 뒤집었는지, 몇 번 잘랐는지, 몇 점이 상에 올랐는지. 자르기(CUT) 개수가 "이 배치는 먹어도 된다"는 분명한 지점을 만들고, 굽는 사람은 드디어 불안이 아닌 박자에 맞춰 일할 수 있습니다. 고기를 알아보지도, 불 조절을 평가하지도 않습니다(혜안의 일). 시간만 지킵니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/samgyeop-flip/preview-samgyeop-flip-index.png>)
![미리보기-s2](<../../screenshots/samgyeop-flip/preview-samgyeop-flip-s2.png>)
![미리보기-s3](<../../screenshots/samgyeop-flip/preview-samgyeop-flip-s3.png>)
![미리보기-s4](<../../screenshots/samgyeop-flip/preview-samgyeop-flip-s4.png>)

## 현지성

한국식 고기구이(삼겹살)는 한 상 사람들의 공동 작업입니다. 누가 굽는지, 언제 뒤집는지, 언제 자르는지, 상 전체가 하나의 박자를 기다립니다. 일찍 뒤집으면 노릇한 향이 없고, 늦게 뒤집으면 써집니다. 그리고 굽는 사람은 정작 자기 입에 몇 점 넣지 못하곤 합니다.

## 기능 흐름 (폐쇄 루프)

- 박자: 두 면의 초(45초/40초)가 자동으로 번갈아 돌고, 불판 가운데 큰 글자 카운트다운이 흐르며, 시간이 되면 TTS는 뒤집으라는 말만 합니다
- 수동: 기다릴 수 없으면 FLIP으로 일찍 뒤집을 수 있고, 박자는 그에 맞춰 재설정됩니다. 고개 끄덕임 = FLIP(손에 기름이 묻어도 쓸 수 있음)
- 자르기: CUT으로 자른 횟수를 한 번씩 세고, 점수만큼 다 자르면 「이 배치는 먹어도 돼요」라고 알리고 다음 배치로 들어갑니다

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

- 초 수는 박자 기준입니다(고기 두께와 불 세기에 따라 스스로 가감하세요). 익은 정도는 사람이 색과 탄력으로 판단해야 하며, Agent는 식품 안전에 대한 결론을 내지 않습니다
- 타이머는 페이지가 숨겨지면 멈추고(Ink 라이프사이클), 페이지로 돌아오면 멈췄던 곳부터 이어서 셉니다. README에 명시합니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/samgyeop-flip
~/tools/bin/aix pack . -o ../dist/samgyeop-flip.aix
~/tools/bin/aix list ../dist/samgyeop-flip.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Samgyeop Flip (가져오기 후 기입 예정) |
| Version / Build | 1.0.2 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | At a Korean BBQ table: times meat flips and counts scissor cuts per batch. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 한국식 바비큐 메트로놈: 첫 면 45초, 뒤집고, 둘째 면 40초. 불판 화면에는 큰 카운트다운 하나가 표시되고, 뒤집는 순간에만 말합니다. 가위질 횟수를 세어 배치가 먹을 준비가 될 때까지 셉니다. 지키는 것은 박자와 진행이며, 익은 정도는 절대 판단하지 않습니다. 그 판단은 당신의 눈의 몫이고, 화면에도 그렇게 적혀 있습니다.

### Opening Message

> ## Samgyeop Flip
> 
> 상 전체를 위해 굽는다는 것은 남의 배에 맞춰 사는 일입니다. 대신 제가 박자를 지킵니다. 45초, 뒤집고, 40초, 자르고, 먹기. 불판 가운데 숫자 하나, 뒤집는 순간 한 마디. 두 손은 집게에 그대로 두세요.

### Preview Media

- `preview-samgyeop-flip-index.png` — 초기 상태
- `preview-samgyeop-flip-s2.png` — 데모 상태 2
- `preview-samgyeop-flip-s3.png` — 데모 상태 3
- `preview-samgyeop-flip-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 불판 박자 Grill Metronome. 위에서 본 둥근 불판: 불판 가운데 큰 초 숫자 + 옆 칸 자르기 장부

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

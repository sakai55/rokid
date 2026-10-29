# Yutnori Game

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-yutnori-game
```

한 줄 장면: 가족이 설날이나 추석에 모였을 때, 손을 쓰지 않고 머리 움직임만으로 윷놀이를 하고, 20칸에 먼저 도착하는 사람이 이깁니다.

방향 구성: 한국 현지 × 게임 × 주의. 현지는 설날·추석 가족 윷놀이에 뿌리내리고, 게임은 플레이의 폐쇄 루프 한 고리(시작/윷 던져 말 옮기기/승패 점수)를 맡고, 주의는 말 위치, 점수, 성적 기록을 지키는 고리를 맡습니다.

## 미리보기 스크린샷

![전체 보기](<../../screenshots/yutnori-game/preview-yutnori-game-index.png>)
![윷 던지기](<../../screenshots/yutnori-game/preview-yutnori-game-throw.png>)
![윷 던지기 2](<../../screenshots/yutnori-game/preview-yutnori-game-throw-s2.png>)
![기록](<../../screenshots/yutnori-game/preview-yutnori-game-record.png>)
![기록 2](<../../screenshots/yutnori-game/preview-yutnori-game-record-s2.png>)

## 구조와 기능

- 페이지 목록(3개 페이지): 전체 보기 index(20칸 말판 + 양쪽 말 위치 + 점수) / 윷 던지기 throw(고개 끄덕임/Enter로 윷을 던지고, 결과대로 말을 옮기며, 결승점에 닿으면 정산) / 기록 record(승패·던진 횟수·최고 기록).
- 콘텐츠 집합 수: 윷 결과 5가지(도·개·걸·윷·모, 각 결과에 칸 수와 설명 포함) + 말판 20칸. 윷/모는 한 번 더 던지는 보너스가 있습니다.
- 폐쇄 루프: 전체 보기에 들어와 → 던지기 페이지에서 고개를 끄덕여 윷을 던지고(TTS가 결과와 칸 수를 알림) → 말을 옮기고, 20칸에 닿으면 승패를 정산 → 기록 페이지에서 성적을 보고 읽어줍니다. 승패·던진 횟수·최고 기록은 세션을 넘어 저장되며(저장 키 `yutnoriV1`), 반복해서 판을 열 수 있습니다.

## 제스처 매핑

| 조작 | 효과 |
|---|---|
| 첫 페이지 ArrowUp/ArrowDown | 하위 페이지를 순환 선택(▶ 표시) |
| 첫 페이지 Enter | 선택한 하위 페이지 열기 |
| 던지기 페이지 Enter/고개 끄덕임 | 윷 던지기(주 동작) |
| 던지기 페이지 ArrowUp/ArrowDown | 이전/다음 결과 설명 |
| 기록 페이지 ArrowUp/ArrowDown | 이전/다음 기록 줄 |
| 기록 페이지 Enter/고개 끄덕임 | 기록 읽어주기 |

## 권한

없음. TTS는 호스트 고정 음색을 사용하고, utterance의 `lang`은 설정하지 않습니다.

## 정직한 경계

- 윷 던지기는 데모 난수입니다(5가지 결과 중 하나를 무작위로 선택). 실제 윷 인식이 아니고, 윷 면 표시는 결과의 시각화이며 센서 값이 아닙니다.
- 머리 움직임은 천천히, 작게 하세요. 통증이나 어지러움이 있으면 즉시 멈추고, 어떤 의료 효과도 주장하지 않습니다.

## 기기 테스트 정보

| 항목 | 내용 |
|---|---|
| Studio 이름 | 기입 예정 |
| Version | 1.0.0 |
| App Category | 기입 예정 |
| Intent Description | 기입 예정 |
| Agent ID | 기입 예정 |
| 상태 | 가져오지 않음 / 실기기 검증 전 |

## 심사 자료 (Review Submission)

- Feature Description: 가족 윷놀이: 머리 움직임만으로 윷을 던지고 20칸 말판을 달려, 결승점에 먼저 닿는 사람이 이기며, 승패와 던진 기록은 세션을 넘어 저장됩니다.
- Opening Message: 설날·추석 가족 윷놀이를 머리 움직임만으로 즐기세요. 고개를 끄덕이면 윷이 던져지고, 20칸에 먼저 도착하면 승리합니다.
- Preview Media: 미리보기 스크린샷은 위에 있습니다(스크린샷은 개발 과정 뒤에 추가, 최소 이미지 1개 + 동영상 1개, 동영상 ≤60초).
- Change Log (Build 1.0.0):
  - Features added: 20칸 말판 전체 보기, 결과 5가지 던지기 페이지, 승패 정산, 승패와 던진 기록 저장.
  - Improvements: 없음 (첫 버전).
  - Fixes: 없음 (첫 버전).

# 태권도 게임

**Studio 가져오기 주소**(Global AIUI Studio Import Project 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-taekwondo-game
```

[taekwondo-game.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/taekwondo-game.aix)

## 기능

태권도장에서 가족이 머리 움직임만으로 태권도 기술을 골라 10번 겨루어 승부를 가립니다. 머리를 돌려 고르고 끄덕여 차기를 내며, 최고 기록은 다음에도 남습니다.

## 장면

태권도장이나 가족 연습 시간에 머리만으로 태권도 기술을 겨루어 10번 승부를 가립니다.

## 방향 구성

한국 현지 × 게임 × 방향성. 게임이 태권도 겨루기를, 방향성이 머리 방향으로 기술을 고르는 일을 맡는다.

## 안경 전용 능력

머리 방향으로 기술을 고르고 끄덕임으로 차기를 내는 것: 두 손이 비어 있지 않아도 머리를 돌려 기술을 고르고 끄덕이기만 하면 겨룰 수 있다. 접선: pages/play/index.ink의 _startSensor(AbsoluteOrientationSensor, 존재 여부 확인) + _onYaw(왼쪽／가운데／오른쪽 세 구역, 가운데로 돌아와 다시 무장, 한 번 돌릴 때 한 칸만) + onHeadGesture('nod')가 primaryTap과 같은 주 확인으로 차기를 낸다. 센서가 안 될 때는 버튼으로 기술을 고른다. 차기 판정은 시범 판정이며, 실제 발차기 동작을 알아보는 것이 아니다.

## 페이지

| 페이지 | 페이지 |
|---|---|
| pages/index | 태권도 기술 8가지와 최고 |
| pages/play | 10차례 겨루기, 기술 맞추기, 끄덕이며 차기, 승부 가리기 |
| pages/record | 태권도 게임 기록 |

## 내용 집합

태권도 기술 8가지(앞차기／돌려차기／옆차기／내려차기／안차기／뒤차기／반달차기／뛰어차기 — 모두 실제 태권도 발차기 이름) × 10차례 고정 순서 [2, 5, 0, 7, 1, 4, 6, 3, 2, 5] — 코드에 쓴 고정 순서. 앞차기는 앞 차기, 돌려차기는 돌려 차기, 옆차기는 옆 차기, 내려차기는 내려 차기, 안차기는 안쪽 초승달 차기, 뒤차기는 뒤 차기, 반달차기는 초승달 차기, 뛰어차기는 뛰어 차기이다.

## 세션 간 저장

저장 키 `taekwondoGameV1`(최고, 끝낸 기록, lastError).

## 권한

권한 선언 없음. 음성 읽기는 기기에서 관리하며 선언이 필요 없다. 카메라와 위치 정보는 쓰지 않는다.

## 제스처 대응

| 한 번 누르기 | Enter | 주 확인 |
| 위아래 밀기 | ArrowUp / ArrowDown | 선택 전환 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## 오류 코드

- `E5001` 저장 쓰기 실패
- `E5002` 저장 읽기 실패
- `E3005` 음성 읽기 실패
- `E8001` 페이지 이동 실패
- `E7001` 머리 센서 사용 불가 또는 읽기 실패

- 점수는 실제 끄덕임과 누르기로만 정하며, 지어낸 점수는 없다.
- 차기 판정은 시범 판정이며, 실제 발차기 동작을 알아보는 것이 아니다. 고른 기술이 목표와 맞는지만으로 정한다.
- 한 번 돌릴 때 한 구역만 바뀌며, 가운데로 돌아오지 않으면 다시 바꿀 수 없고, 빙글빙글 돌지 않는다.
- 센서가 안 될 때는 버튼으로 기술을 고른다. 차기 판정은 달라지지 않는다. 센서 실패는 E7001을 남긴다.

## 미리 보기 이미지

![preview-taekwondo-game-index.png](../screenshots/taekwondo-game/preview-taekwondo-game-index.png)
![preview-taekwondo-game-play.png](../screenshots/taekwondo-game/preview-taekwondo-game-play.png)
![preview-taekwondo-game-play-s2.png](../screenshots/taekwondo-game/preview-taekwondo-game-play-s2.png)
![preview-taekwondo-game-record.png](../screenshots/taekwondo-game/preview-taekwondo-game-record.png)

## 심사 자료

### Feature Description

태권도장에서 가족이 머리 움직임만으로 태권도 기술을 골라 10번 겨루어 승부를 가립니다. 머리를 돌려 기술을 고르고 끄덕여 차기를 내며, 최고 기록은 다음에도 남습니다.

### Opening Message

태권도 게임에 오신 것을 환영합니다. 머리를 돌려 기술을 고르고 끄덕여 차기를 내세요. 10번 겨루어 승부를 가립니다.

### Preview Media

[preview-taekwondo-game-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/taekwondo-game/preview-taekwondo-game-video.mp4)
![preview-taekwondo-game-index.png](../screenshots/taekwondo-game/preview-taekwondo-game-index.png)
![preview-taekwondo-game-play.png](../screenshots/taekwondo-game/preview-taekwondo-game-play.png)
![preview-taekwondo-game-play-s2.png](../screenshots/taekwondo-game/preview-taekwondo-game-play-s2.png)

### Change Log

- Features：초판 기능은 위와 같다.
- Improvements：없음.
- Fixes：없음.

## 기기 시험 정보

| Studio 이름 | 미기입 |
|---|---|
| Studio 이름 | 미기입 |
| Version / Build | 미기입 |
| App Category | 미기입 |
| Intent Description | 미기입 |
| Agent ID | 미기입 |
| 상태 | 미기입 |

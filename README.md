# 인사동 차 지킴이

**Studio 가져오기 주소**(Global AIUI Studio Import Project 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-insadong-tea-watch
```

[insadong-tea-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/insadong-tea-watch.aix)

## 기능

인사동 전통 찻집에서 차를 우리는 사람이 양손으로 찻주전자와 찻잔을 든 채 차를 바라보고 끄덕임으로 시간을 재면 때가 되면 알려주어 여러 찻잔을 태우지 않고 따를 수 있다.

## 장면

인사동 전통 찻집에서 차를 우리는 사람이 양손으로 찻주전자와 찻잔을 든 채 차를 바라보고 끄덕임으로 시간을 잰다.

## 방향 구성

한국 현지 × 주의력(여러 차 우리는 시간 지킴이) × 방향성(고개를 돌려 차 자리 바꾸기).

## 안경 전용 능력

시선과 머리 방향의 조화 + 양손이 바쁠 때 끄덕임으로 시간 재기: 양손으로 찻주전자와 찻잔을 들고 휴대전화를 꺼낼 수 없을 때, 고개를 돌린 자리 차를 지키고 끄덕임으로 시간을 잰다. 접선: pages/watch/index.ink의 _startSensor + _onYaw + 끄덕임으로 primaryTap을 눌러 시간을 잰다. 지킴이 페이지는 onLoad에서 저장된 selected를 읽어 처음 자리를 정한다.

## 페이지

| 페이지 | 페이지 |
|---|---|
| pages/index | 차 6종과 우리는 초 |
| pages/watch | 고개를 돌려 차 자리 바꾸기, 끄덕임으로 시간 재기, 때가 되면 알려주기 |
| pages/record | 차 우리기 기록 |

## 내용 집합

차 6종과 우리는 초: 보리차 180초/녹차 120초/유자차 240초/오미자차 300초/국화차 150초/생강차 210초.

## 세션 간 저장

저장 키 `insadongTeaWatchV1`(선택한 차, 각 차의 시간 재기, 차 우리기 기록, lastError).

## 권한

목록 권한이 없다. 음성 읽기는 목록 권한이 필요 없으며, 카메라와 위치를 쓰지 않는다.

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

- 시간이 되기 전에 누르면 남은 시간만 알려주고 기록을 남기지 않는다.
- 때가 되면 한 차마다 한 번만 알려주며, 차 우리기 기록은 시간이 된 뒤의 확인으로만 남긴다.
- 센서가 없어도 단추로 차 자리를 바꿀 수 있으며, 시간 재기 자체는 센서에 기대지 않는다.

## 미리 보기 이미지

![preview-insadong-tea-watch-index.png](../screenshots/insadong-tea-watch/preview-insadong-tea-watch-index.png)
![preview-insadong-tea-watch-watch.png](../screenshots/insadong-tea-watch/preview-insadong-tea-watch-watch.png)
![preview-insadong-tea-watch-watch-s2.png](../screenshots/insadong-tea-watch/preview-insadong-tea-watch-watch-s2.png)
![preview-insadong-tea-watch-record.png](../screenshots/insadong-tea-watch/preview-insadong-tea-watch-record.png)

## 심사 자료

### Feature Description

인사동 전통 찻집에서 차를 우리는 사람이 양손으로 찻주전자와 찻잔을 든 채 차를 바라보고 끄덕임으로 시간을 재면 때가 되면 알려주어 여러 찻잔을 태우지 않고 따를 수 있다.

### Opening Message

인사동 찻집에서 양손이 바빠도 괜찮다. 차를 바라보고 끄덕이면 시간을 재어 줄게.

### Preview Media

[preview-insadong-tea-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/insadong-tea-watch/preview-insadong-tea-watch-video.mp4)
![preview-insadong-tea-watch-index.png](../screenshots/insadong-tea-watch/preview-insadong-tea-watch-index.png)
![preview-insadong-tea-watch-watch.png](../screenshots/insadong-tea-watch/preview-insadong-tea-watch-watch.png)
![preview-insadong-tea-watch-watch-s2.png](../screenshots/insadong-tea-watch/preview-insadong-tea-watch-watch-s2.png)

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

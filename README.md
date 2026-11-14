# 부산 어묵 끓이기

**Studio 가져오기 주소**(Global AIUI Studio Import Project 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-busan-eomuk-watch
```

[busan-eomuk-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/busan-eomuk-watch.aix)

## 개요

부산 어묵 가게에서 어묵을 끓이는 사람이 두 손이 바쁜 채 고개를 돌려 냄비를 고르고, 끄덕여 타이머를 시작한 뒤, 시간이 되면 음성으로 듣고 다 끓인 어묵을 꺼내 기록한다. 어묵 6가지마다 시간이 다르다.

## 장면

부산 어묵 가게에서 어묵을 끓이는 사람이 두 손이 바쁜 채 고개를 돌려 냄비를 고르고, 끄덕여 타이머를 시작한 뒤, 시간이 되면 음성으로 듣고 다 끓인 어묵을 꺼내 기록한다.

## 방향 구성

한국 현지 × 주의력(어묵 끓이기 지켜보기) × 방향성(고개를 돌려 냄비 고르기). 주의력은 타이머를 지키는 일을 맡고, 방향성은 고개 방향으로 냄비를 바꾸는 일을 맡는다.

## 안경 전용 기능

시선과 머리 방향 맞추기: 두 손이 바빠 어묵을 끓이는 중에는 휴대전화를 꺼낼 수 없지만, 고개를 돌리면 그 냄비가 골라지고 끄덕이면 타이머가 시작되며, 시간이 되면 음성으로 알려준다. 접선: pages/watch/index.ink의 _startSensor(AbsoluteOrientationSensor, 존재 여부 확인)와 _onYaw(왼쪽/정면/오른쪽 세 구역으로 냄비 바꾸기, 정면으로 돌아오면 다시 준비) + onHeadGesture('nod')가 주 확인과 같다. 지키기 페이지는 onLoad에서 저장된 selected를 읽어 처음 자리를 정한다. 센서를 쓸 수 없을 때는 버튼으로 냄비를 고를 수 있고, 센서 읽기 실패는 E7001을 남긴다.

## 솔직한 경계

- 익힘 정도를 재지 않으며, 시간만으로 알려준다. 시간은 기준이며, 어묵 두께와 불 세기에 따라 달라진다.
- 센서를 쓸 수 없을 때는 버튼으로 냄비를 고를 수 있다.
- 기록은 다 끓인 어묵을 꺼냈을 때만 남는다.

## 페이지

| 페이지 | 페이지 |
|---|---|
| pages/index | 어묵 6가지 목록, 냄비마다 시간 |
| pages/watch | 고개로 냄비 바꾸기, 끄덕여 타이머 시작, 시간이 되면 음성 알림 |
| pages/record | 최근 6건의 끓이기 기록과 합계 |

## 내용 집합

어묵 6가지와 초: 어묵 꼬치 180／매운 어묵 240／치즈 어묵 300／야채 어묵 210／김말이 어묵 270／새우 어묵 150. 기록은 건수로 센다.

## 저장

저장 키 `busanEomukWatchV1`. 고른 냄비, 냄비마다 타이머, 끓이기 기록 배열, lastError를 저장한다.

## 권한

권한 없음. 음성 읽기는 권한이 필요 없고, 카메라와 위치 정보는 사용하지 않는다.

## 제스처

| 한 번 누르기 | Enter | 주 확인(냄비 고르기·타이머 시작) |
| 위아래 밀기 | ArrowUp / ArrowDown | 냄비 선택 바꾸기 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## 오류 코드

- `E5001` 저장 쓰기 실패
- `E5002` 저장 읽기 실패
- `E3005` 음성 읽기 실패
- `E8001` 페이지 이동 실패
- `E7001` 머리 센서를 쓸 수 없거나 읽기 실패

실패하면 화면에 있는 그대로의 코드를 보여주고, lastError에는 코드와 slug, 버전, 원래 문구를 함께 남긴다.

## 미리보기 스크린샷

![preview-busan-eomuk-watch-index.png](../screenshots/busan-eomuk-watch/preview-busan-eomuk-watch-index.png)
![preview-busan-eomuk-watch-watch.png](../screenshots/busan-eomuk-watch/preview-busan-eomuk-watch-watch.png)
![preview-busan-eomuk-watch-watch-s2.png](../screenshots/busan-eomuk-watch/preview-busan-eomuk-watch-watch-s2.png)
![preview-busan-eomuk-watch-record.png](../screenshots/busan-eomuk-watch/preview-busan-eomuk-watch-record.png)

## 제출 자료

### Feature Description

부산 어묵 가게에서 어묵을 끓이는 사람이 두 손이 바쁜 채 고개를 돌려 냄비를 고르고, 끄덕여 타이머를 시작한 뒤, 시간이 되면 음성으로 듣고 다 끓인 어묵을 꺼내 기록한다. 어묵 6가지마다 시간이 다르다.

### Opening Message

부산 어묵 가게에서 두 손이 바빠도 괜찮아요. 고개를 돌려 냄비를 고르고, 끄덕여 타이머를 시작해요.

### Preview Media

[preview-busan-eomuk-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/busan-eomuk-watch/preview-busan-eomuk-watch-video.mp4)
![preview-busan-eomuk-watch-index.png](../screenshots/busan-eomuk-watch/preview-busan-eomuk-watch-index.png)
![preview-busan-eomuk-watch-watch.png](../screenshots/busan-eomuk-watch/preview-busan-eomuk-watch-watch.png)
![preview-busan-eomuk-watch-record.png](../screenshots/busan-eomuk-watch/preview-busan-eomuk-watch-record.png)

### Change Log

- Features：초판 기능은 위와 같다.
- Improvements：없음.
- Fixes：없음.

## 기기 테스트 정보

| 항목 | 내용 |
|---|---|
| Studio 이름 | 미기입 |
| Version / Build | 미기입 |
| App Category | 미기입 |
| Intent Description | 미기입 |
| Agent ID | 미기입 |
| 상태 | 미기입 |

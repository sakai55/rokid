# 강릉 여행 수첩

**Studio 가져오기 주소**(Global AIUI Studio Import Project 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-gangneung-trip-hub
```

[gangneung-trip-hub.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/gangneung-trip-hub.aix)

## 기능

강릉을 여행하는 사람이 한 권의 수첩으로 20가지 여행 도구를 끝까지 돌린다. 경포해변 사진 확인, 안목해변 커피거리, 오죽헌, 강릉중앙시장, 정동진 방위 안내 등 강릉의 진짜 장소를 머리 움직임과 끄덕임, 사진으로 확인하며 쓰고, 끝낸 기록은 다음에도 남는다.

## 장면

강릉을 여행하는 사람이 한 권의 수첩으로 20가지 여행 도구를 끝까지 돌린다.

## 방향 구성

한국 현지 × 집합 총괄 × 주의력. 한국 현지가 강릉이라는 장소를, 집합 총괄이 20가지 여행 도구를 한 권의 수첩으로 묶는 일을, 주의력이 사진 확인과 순서, 퀴즈, 세기로 각 장소를 가려내는 일을 맡는다.

## 안경 전용 능력

안경 전용 능력으로 수첩의 중심 고리를 묶는다. 두 손이 짐으로 바쁠 때는 끄덕임으로 단계를 넘기고, 바라보는 것으로 도구를 고르고, 사진 페이지에서는 눈앞의 장소를 직접 찍어 확인해야 끝낼 수 있으며, 정동진 페이지에서는 GPS 방위와 거리로 역까지 안내한다. 접선: 사진 페이지 t01／t04／t17의 photoTap(ImageCapture.takePhoto, blob.arrayBuffer()와 나눈 btoa로 바꾼다)과 confirmTap(사진이 없으면 끝낼 수 없다), 방향 페이지 t08／t13의 _startSensor(AbsoluteOrientationSensor, 존재 여부 확인)＋_onYaw(왼쪽／가운데／오른쪽 세 구역, 가운데로 돌아와 다시 무장), 정동진 페이지 t06의 navigator.geolocation.getCurrentPosition＋8방향 방위 계산(_calc)＋거리 계산, 전 페이지의 onHeadGesture('nod')가 primaryTap과 같은 주 확인으로 진행한다. 사진은 본인 확인에만 쓰고, 위치를 쓸 수 없거나 등록하지 않았을 때는 지어내지 않는다.

## 페이지

| 페이지 | 내용 |
|---|---|
| pages/index | 강릉 여행 도구 20가지 목록 |
| pages/t01 | 경포해변 |
| pages/t02 | 안목해변 커피거리 |
| pages/t03 | 오죽헌 |
| pages/t04 | 강릉중앙시장 |
| pages/t05 | 초당순두부 |
| pages/t06 | 정동진 |
| pages/t07 | 선교장 |
| pages/t08 | 경포호 |
| pages/t09 | 강릉역 환승 |
| pages/t10 | 대관령 |
| pages/t11 | 강릉단오제 |
| pages/t12 | 아르떼뮤지엄 강릉 |
| pages/t13 | 하슬라아트월드 |
| pages/t14 | 주문진항 |
| pages/t15 | 강릉 올림픽파크 |
| pages/t16 | 커피박물관 |
| pages/t17 | 강릉 사진 명소 |
| pages/t18 | 강릉 기념품 목록 |
| pages/t19 | 강릉 날씨 옷차림 |
| pages/t20 | 강릉 여행 기록 |

## 내용 집합

20가지 여행 도구: 사진 확인 3가지(경포해변／강릉중앙시장／강릉 사진 명소, 네 곳씩 표시)＋순서 5가지(안목해변 커피거리／초당순두부／강릉역 환승／커피박물관／강릉 기념품 목록, 5단계씩)＋퀴즈 5가지(오죽헌／선교장／강릉단오제／강릉 올림픽파크／강릉 날씨 옷차림)＋세기 2가지(대관령 10마리／주문진항 12척)＋방향 맞추기 2가지(경포호／하슬라아트월드, 1회에 6차례)＋방위 안내 1가지(정동진)＋계산 1가지(아르떼뮤지엄 강릉 9＋5)＋강릉 여행 기록 1가지. 퀴즈의 답은 진짜 강릉 사실이다(오죽헌은 신사임당과 율곡 이이의 생가／선교장은 99칸 고택／강릉단오제는 유네스코 인류무형문화유산／강릉 올림픽파크는 2018 평창 동계올림픽 빙상 경기장). 강릉단오제는 단오 시기에만 여는 계절 축제라서 정보만 본다고 적었다.

## 세션 간 저장

저장 키 `gangneungTripHubV1`(고른 도구, 도구별 최고, 끝낸 기록, 정동진역 등록 위치, 사진 기록, lastError).

## 권한

`CAMERA`(사진 페이지에서 눈앞의 장소를 찍어 확인한다), `GEOLOCATION`(정동진 페이지에서 지금 위치를 재어 방위와 거리를 낸다). 음성 읽기는 기기에서 관리하며 선언이 필요 없다.

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
- `E7002` 위치 측정 실패
- `E7003` 위치 권한을 주지 않음
- `E1001` 카메라 열기 실패
- `E1009` 촬영 실패
- `E2013` 사진 부호 바꾸기 실패
- `E8004` 카메라 기능 없음

- 점수와 기록은 실제 끄덕임과 누르기, 사진으로만 정하며, 지어낸 기록은 없다.
- 세기 도구의 수는 눈앞에 보이는 것을 직접 세어 넣은 수이며, 카메라가 세는 것이 아니다.
- 사진은 본인 확인에만 쓰며, 찍지 않았거나 네 곳에 표시가 없으면 끝낼 수 없다.
- 방위와 거리는 추정치이며, 등록하지 않았거나 위치를 쓸 수 없을 때는 지어내지 않는다. 정동진역 위치는 사용자가 도착해 직접 등록한 위치이다.
- 강릉단오제는 계절 축제라서 정보만 본다고 적었으며, 지금 열린다고 말하지 않는다.
- 한 번 돌릴 때 한 구역만 바뀌며, 가운데로 돌아오지 않으면 다시 바꿀 수 없고, 빙글빙글 돌지 않는다.
- 센서가 안 될 때는 버튼으로 고른다. 판정은 달라지지 않는다. 센서 실패는 E7001을 남긴다.

## 미리 보기 이미지

![preview-gangneung-trip-hub-index.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-index.png)
![preview-gangneung-trip-hub-t01.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t01.png)
![preview-gangneung-trip-hub-t02.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t02.png)
![preview-gangneung-trip-hub-t03.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t03.png)
![preview-gangneung-trip-hub-t04.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t04.png)
![preview-gangneung-trip-hub-t05.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t05.png)
![preview-gangneung-trip-hub-t06.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t06.png)
![preview-gangneung-trip-hub-t07.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t07.png)
![preview-gangneung-trip-hub-t08.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t08.png)
![preview-gangneung-trip-hub-t09.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t09.png)
![preview-gangneung-trip-hub-t10.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t10.png)
![preview-gangneung-trip-hub-t11.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t11.png)
![preview-gangneung-trip-hub-t12.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t12.png)
![preview-gangneung-trip-hub-t13.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t13.png)
![preview-gangneung-trip-hub-t14.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t14.png)
![preview-gangneung-trip-hub-t15.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t15.png)
![preview-gangneung-trip-hub-t16.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t16.png)
![preview-gangneung-trip-hub-t17.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t17.png)
![preview-gangneung-trip-hub-t18.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t18.png)
![preview-gangneung-trip-hub-t19.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t19.png)
![preview-gangneung-trip-hub-t20.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t20.png)
![preview-gangneung-trip-hub-t01-s2.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t01-s2.png)

## 심사 자료

### Feature Description

강릉을 여행하는 사람이 한 권의 수첩으로 20가지 여행 도구를 끝까지 돌린다. 경포해변 사진 확인, 안목해변 커피거리, 오죽헌, 강릉중앙시장, 정동진 방위 안내 등 강릉의 진짜 장소를 머리 움직임과 끄덕임, 사진으로 확인하며 쓰고, 끝낸 기록은 다음에도 남는다.

### Opening Message

강릉 여행 수첩에 오신 것을 환영합니다. 머리를 돌려 도구를 고르고 끄덕이며 강릉 20곳을 끝까지 돌려 보세요.

### Preview Media

[preview-gangneung-trip-hub-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-video.mp4)
![preview-gangneung-trip-hub-index.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-index.png)
![preview-gangneung-trip-hub-t01.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t01.png)
![preview-gangneung-trip-hub-t06.png](../../screenshots/gangneung-trip-hub/preview-gangneung-trip-hub-t06.png)

### Change Log

- Features：초판 기능은 위와 같다.
- Improvements：없음.
- Fixes：없음.

## 기기 시험 정보

| 항목 | 내용 |
|---|---|
| Studio 이름 | 미기입 |
| Version / Build | 미기입 |
| App Category | 미기입 |
| Intent Description | 미기입 |
| Agent ID | 미기입 |
| 상태 | 미기입 |

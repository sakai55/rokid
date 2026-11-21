# 전주 여행 수첩

**Studio 가져오기 주소**(Global AIUI Studio Import Project 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-jeonju-trip-hub
```

[jeonju-trip-hub.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/jeonju-trip-hub.aix)

## 기능

전주를 여행하는 사람이 한 권의 수첩으로 20가지 여행 도구를 끝까지 돌립니다. 머리를 돌려 고르고 끄덕이며 진행하고, 끝낸 기록은 다음에도 남습니다.

## 장면

전주를 여행하는 사람이 한 권의 수첩으로 20가지 여행 도구를 끝까지 돌린다.

## 방향 구성

한국 현지 × 여행 수첩 × 주의력 × 방향성. 수첩이 20가지 도구를 모으고, 방향성이 머리 방향으로 고르는 일을 맡는다.

## 안경 전용 능력

안경 전용 능력은 끄덕임으로 단계를 넘기는 것과 눈앞의 실제 장소를 보고 확인하는 것이다. 손에 시장 짐과 카메라가 가득해도, 머리를 돌려 도구를 고르고 끄덕이기만 하면 진행할 수 있다. 접선: 모든 도구 페이지의 onHeadGesture('nod')가 primaryTap과 같은 주 확인으로 단계를 넘기고, 한옥마을 산책 페이지(t01)는 눈앞의 한옥마을을 직접 보고 끄덕여 확인하는 5단계이며, 방향 페이지 t10／t12／t16의 _startSensor(AbsoluteOrientationSensor, 존재 여부 확인) + _onYaw로 방향을 고른다. 센서가 안 될 때는 버튼으로 방향을 고른다.

## 페이지

| 페이지 | 페이지 |
|---|---|
| pages/index | 20가지 전주 여행 도구 목록 |
| pages/t01 | 한옥마을 산책 |
| pages/t02 | 경기전 |
| pages/t03 | 오목대 |
| pages/t04 | 전주향교 |
| pages/t05 | 한지박물관 |
| pages/t06 | 비빔밥 주문 |
| pages/t07 | 한옥스테이 체크 |
| pages/t08 | 남부시장 |
| pages/t09 | 전주천 산책 |
| pages/t10 | 덕진공원 |
| pages/t11 | 국립무형유산원 |
| pages/t12 | 풍남문 |
| pages/t13 | 전동성당 |
| pages/t14 | 막걸리 체험 |
| pages/t15 | 전주 기념품 목록 |
| pages/t16 | 전주 사진 명소 |
| pages/t17 | 전주화폐 계산 |
| pages/t18 | 전주 날씨 옷차림 |
| pages/t19 | 전주 분실물 체크 |
| pages/t20 | 전주 여행 기록 |

## 내용 집합

20가지 도구: 한옥마을 산책(직접 보고 확인 5단계) + 경기전·전주향교·한옥스테이 체크·전주천 산책(5단계씩) + 퀴즈 6가지(오목대·한지박물관·비빔밥 주문·국립무형유산원·전동성당·전주 날씨 옷차림) + 방향 맞히기 3가지(덕진공원·풍남문·전주 사진 명소, 1번에 6차례) + 수 세기 3가지(남부시장 6·전주 기념품 목록 6·전주 분실물 체크 5) + 돈 계산 2가지(막걸리 체험·전주화폐 계산) + 전주 여행 기록 1가지.

## 세션 간 저장

저장 키 `jeonjuTripHubV1`(고른 도구, 도구별 최고, 끝낸 기록, lastError).

## 권한

선언한 권한 없음. 음성 읽기는 숙주 관리이며 선언이 필요 없다. 카메라와 위치 정보는 쓰지 않는다.

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
- 한옥마을 산책의 확인은 눈으로 직접 보고 끄덕이는 것이며, 사진을 찍어 알아보는 것이 아니다.
- 센서가 안 될 때는 버튼으로 방향을 고른다. 방향 맞히기 판정은 달라지지 않는다. 센서 실패는 E7001을 남긴다.

## 미리 보기 이미지

![preview-jeonju-trip-hub-index.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-index.png)
![preview-jeonju-trip-hub-t01.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t01.png)
![preview-jeonju-trip-hub-t02.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t02.png)
![preview-jeonju-trip-hub-t03.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t03.png)
![preview-jeonju-trip-hub-t04.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t04.png)
![preview-jeonju-trip-hub-t05.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t05.png)
![preview-jeonju-trip-hub-t06.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t06.png)
![preview-jeonju-trip-hub-t07.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t07.png)
![preview-jeonju-trip-hub-t08.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t08.png)
![preview-jeonju-trip-hub-t09.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t09.png)
![preview-jeonju-trip-hub-t10.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t10.png)
![preview-jeonju-trip-hub-t11.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t11.png)
![preview-jeonju-trip-hub-t12.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t12.png)
![preview-jeonju-trip-hub-t13.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t13.png)
![preview-jeonju-trip-hub-t14.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t14.png)
![preview-jeonju-trip-hub-t15.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t15.png)
![preview-jeonju-trip-hub-t16.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t16.png)
![preview-jeonju-trip-hub-t17.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t17.png)
![preview-jeonju-trip-hub-t18.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t18.png)
![preview-jeonju-trip-hub-t19.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t19.png)
![preview-jeonju-trip-hub-t20.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t20.png)
![preview-jeonju-trip-hub-t01-s2.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t01-s2.png)

## 심사 자료

### Feature Description

전주를 여행하는 사람이 한 권의 수첩으로 20가지 여행 도구를 끝까지 돌립니다. 머리를 돌려 고르고 끄덕이며 진행하고, 끝낸 기록은 다음에도 남습니다.

### Opening Message

전주 여행 수첩에 오신 것을 환영합니다. 도구를 골라 끄덕이며 끝까지 돌려 보세요. 끝낸 기록은 남습니다.

### Preview Media

[preview-jeonju-trip-hub-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-video.mp4)
![preview-jeonju-trip-hub-index.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-index.png)
![preview-jeonju-trip-hub-t01.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t01.png)
![preview-jeonju-trip-hub-t02.png](../../screenshots/jeonju-trip-hub/preview-jeonju-trip-hub-t02.png)

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

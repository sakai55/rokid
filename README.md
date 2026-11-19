# 북한산 만남

**Studio 가져오기 주소**(Global AIUI Studio Import Project 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-bukhansan-hike-meet
```

[bukhansan-hike-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/bukhansan-hike-meet.aix)

## 기능

북한산에서 등산하는 사람이 두 손에 등산 지팡이를 쥐고 동행과 헤어졌을 때, 휴대전화를 꺼내지 않고 GPS 방위와 거리로 등록한 만남 장소까지 돌아가 도착을 기록합니다.

## 장면

북한산에서 등산하는 사람이 동행과 헤어졌을 때, 두 손에 지팡이를 쥔 채 GPS 방위와 거리로 만남 장소까지 돌아갑니다.

## 방향 구성

한국 현지 × 방향성(GPS 방위 거리) × 커브컷(두 손에 지팡이를 쥔 등산객이 동행과 헤어졌을 때 휴대전화를 꺼내지 않고 돌아간다). 방향성은 방위 거리 안내를 맡고, 커브컷은 손에 들고 있지 않아도 되는 등록과 도착 과정을 맡는다.

## 안경 전용 능력

만남 장소에 고정된 방향(GPS 방위 + 거리로 돌아가기): 등록과 안내는 눈앞에서 끝나고, 두 손에 지팡이를 쥔 채로는 휴대전화를 꺼내 만남 장소까지 걸어갈 수 없다. 접선: app.json에 GEOLOCATION 선언, pages/guide/index.ink의 saveTap이 navigator.geolocation.getCurrentPosition으로 등록하고, 같은 페이지의 primaryTap이 다시 위치를 재서 _calc(위경도 차이 → 방위각 → 8방향 변환 + haversine 거리, 10 m 단위)로 방위와 거리를 낸다. 등록하지 않았거나 위치를 쓸 수 없을 때는 솔직히 낮춰서 알리고 지어내지 않는다.

## 페이지

| 페이지 | 페이지 |
|---|---|
| pages/index | 만남 장소 6곳 |
| pages/guide | GPS 등록 + 방위 거리 |
| pages/record | 도착 기록 |

## 내용 집합

만남 장소 6곳: 백운대, 인수봉, 만경대, 대성문, 북한산성, 우이동 — 모두 북한산 실제 장소(백운대는 최고봉 836 m, 대성문은 북한산성 성문, 우이동은 등산로 들머리).

## 세션 간 저장

저장 키 `bukhansanHikeMeetV1`(고른 만남 장소, 등록한 위치, 도착 기록, lastError).

## 권한

GEOLOCATION 선언. 카메라와 미디어 권한은 사용하지 않는다.

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
- `E7002` 위치 정보를 가져올 수 없음
- `E7003` 위치 정보 이용이 거부됨

- 등록하지 않았을 때는 안내 페이지에 등록하지 않았다고 밝히고 방위 안내를 지어내지 않는다.
- 위치를 거부당하면 E7003, 그 밖의 위치 실패는 E7002를 남긴다. 거리는 추정치이며 10 m 단위로 끊는다.
- 등록한 만남 장소는 이용자 본인의 위치이지, 찾아낸 장소가 아니다.
- 미리 보기는 실시간 GPS를 보여줄 수 없습니다: 심사 영상은 미리 보기가 보여줄 수 있는 등록·안내 흐름만 보여주며, 위치를 지어내지 않습니다.

## 미리 보기 이미지

![preview-bukhansan-hike-meet-index.png](../screenshots/bukhansan-hike-meet/preview-bukhansan-hike-meet-index.png)
![preview-bukhansan-hike-meet-guide.png](../screenshots/bukhansan-hike-meet/preview-bukhansan-hike-meet-guide.png)
![preview-bukhansan-hike-meet-record.png](../screenshots/bukhansan-hike-meet/preview-bukhansan-hike-meet-record.png)

## 심사 자료

### Feature Description

북한산에서 등산하는 사람이 두 손에 등산 지팡이를 쥐고 동행과 헤어졌을 때, 휴대전화를 꺼내지 않고 GPS 방위와 거리로 등록한 만남 장소까지 돌아가 도착을 기록합니다.

### Opening Message

북한산 만남에 오신 것을 환영합니다. 만남 장소를 골라 등록하고, 방위와 거리로 돌아오세요.

### Preview Media

[preview-bukhansan-hike-meet-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/bukhansan-hike-meet/preview-bukhansan-hike-meet-video.mp4)
![preview-bukhansan-hike-meet-index.png](../screenshots/bukhansan-hike-meet/preview-bukhansan-hike-meet-index.png)
![preview-bukhansan-hike-meet-guide.png](../screenshots/bukhansan-hike-meet/preview-bukhansan-hike-meet-guide.png)
![preview-bukhansan-hike-meet-record.png](../screenshots/bukhansan-hike-meet/preview-bukhansan-hike-meet-record.png)

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

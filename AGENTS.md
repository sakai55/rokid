# 남산 만남 - Agent Notes

KR30. 한국 현지 × 방향성(GPS) × 배려 설계.

## Design contract

서울 남산타워 아래에서 가족과 헤어진 관광객이 휴대전화를 꺼내지 않고 GPS 방위와 거리로 등록한 만남 장소까지 돌아간다.

## Counts

내용 집합: 만남 장소 6곳. 도착 기록은 실제 수로 센다.

## Storage

저장 키 `namsanMeetV1`(고른 만남 장소, 등록한 만남 장소 이름과 위경도 및 등록 시각, 도착 기록 배열, lastError).

## Gesture map

| 한 번 누르기 | Enter | 주 확인(안내 페이지에서는 위치 측정) |
| 위아래 밀기 | ArrowUp / ArrowDown | 만남 장소 전환 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## Honest boundaries

- 등록하지 않았을 때는 안내 페이지에 등록하지 않았다고 밝히고 방위 안내를 지어내지 않는다.
- 위치를 거부당하면 E7003, 그 밖의 위치 실패는 E7002를 남긴다. 거리는 추정치이며 10 m 단위로 끊는다.
- 등록한 만남 장소는 이용자 본인의 위치이지, 찾아낸 장소가 아니다.

## Validation

- 언어 순도: 가나 0, CJK 한자 0(정적 기계 검사).
- 금지 목록 grep: 0건.
- GPS 세 가지: app.json에 GEOLOCATION 선언, pages/guide/index.ink의 saveTap 등록, primaryTap 위치 측정, _calc 8방향 변환과 거리 계산.

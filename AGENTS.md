# 경주 여행 수첩 — Agent Notes

KR23。한국 현지 × 집합 총괄 × 주의

## Design contract

경주를 여행하는 사람이 수첩 한 권으로 여행 도구 20가지를 끝까지 사용합니다

## Counts

내용집 개수: 여행 도구 20개; 체크리스트 11개 페이지 44항목; 세기 3개 페이지 목표 4곳과 4곳과 5곳; 문구 6개 페이지 24문장; 사용 기록은 실제 건수대로 셉니다. 세션을 넘는 지속성: 저장 키 `gyeongjuTripHubV1`(선택 도구, 체크 상태, 완료 기록 배열, `lastError`).

## Storage

저장 키 `gyeongjuTripHubV1`。

## Gesture map

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 주 확인(각 페이지의 주 버튼) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 옵션 전환 / 위아래 항목 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 주 확인과 동등 |
| 두 번 탭 | Backspace | 이전 페이지로 돌아가기(하위 페이지) |

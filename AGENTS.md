# 딱지치기 — Agent Notes

KR24。한국 현지 × 게임 × 지향성

## Design contract

가족이 모인 명절에 머리 방향만으로 딱지치기를 즐깁니다

## Counts

내용집 개수: 딱지 6장; 놀이는 6번 치기로 한 판; 기록은 실제 건수대로 셉니다. 세션을 넘는 지속성: 저장 키 `ddakjiGameV1`(기록 배열, `lastError`).

## Storage

저장 키 `ddakjiGameV1`。

## Gesture map

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 주 확인(각 페이지의 주 버튼) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 옵션 전환 / 위아래 항목 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 주 확인과 동등 |
| 두 번 탭 | Backspace | 이전 페이지로 돌아가기(하위 페이지) |

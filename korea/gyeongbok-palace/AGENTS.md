# 경복궁 관람 — Agent Notes

KR25。한국 현지 × 주의 × 길잡이

## Design contract

경복궁을 처음 찾는 관람객이 여섯 곳을 차례로 확인하며 관람을 마친다

## Counts

내용집 개수: 장소 6곳; 체크 항목 5개; 기록은 실제 건수대로 셉니다. 세션을 넘는 지속성: 저장 키 `gyeongbokPalaceV1`(선택 장소, 체크 상태, 기록 배열, `lastError`).

## Storage

저장 키 `gyeongbokPalaceV1`。

## Gesture map

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 주 확인(각 페이지의 주 버튼) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 옵션 전환 / 위아래 항목 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 주 확인과 동등 |
| 두 번 탭 | Backspace | 이전 페이지로 돌아가기(하위 페이지) |

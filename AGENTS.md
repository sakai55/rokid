# 자갈치 안내 - Agent Notes

KR29. 한국 현지 × 방향성(머리 방향 코너 선택) × 주의력(확인 항목 지킴).

## Design contract

부산 자갈치시장에서 장을 보는 사람이 양손으로 짐을 든 채 머리 방향으로 코너를 고르고 확인을 마친다.

## Counts

코너 6곳 × 확인 항목 4개 = 24개 확인 항목.

## Storage

저장 키 `jagalchiGuideV1`(선택 코너, 마친 코너 기록, lastError).

## Gesture map

| 한 번 누르기 | Enter | 주 확인 |
| 위아래 밀기 | ArrowUp / ArrowDown | 선택 전환 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## Honest boundaries

- 가격과 재고는 현장 간판이 기준이며, 내장 목록은 예시이다.
- 센서가 없을 때는 버튼으로 코너를 고를 수 있다.

## Validation

- 한국어 순도: 가나 0, CJK 한자 0(정적 검사).
- 금지 목록 grep: 0건.
- 독점 접선: pages/index/index.ink의 _startSensor와 _onYaw.

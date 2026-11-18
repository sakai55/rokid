# 한국민속놀이집 - Agent Notes

KR43. 한국 현지 × 게임 × 방향성 × 주의력.

## Design contract

명절 기다리는 시간, 온 가족이 안경 한 대로 한국 민속놀이로 놀고 점수를 정합니다.

## Counts

20가지: 놀이 19가지(세기 4, 퀴즈 4, 방향 4, 순서 4, 계산 3) + 기록 1가지. 세기 목표 10／12／8／15, 방향은 한 판 6번, 순서는 한 판 5단계.

## Storage

저장 키 `koreaFolkGamesV1`(고른 놀이, 놀이마다 최고 기록, 마친 기록, lastError).

## Gesture map

| 한 번 누르기 | Enter | 주 확인 |
| 위아래 밀기 | ArrowUp / ArrowDown | 선택 전환 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## Honest boundaries

- 점수는 진짜 끄덕임과 누르기로만 정하며, 만든 점수는 없습니다.
- 센서를 쓸 수 없을 때는 버튼으로 방향을 고를 수 있고, 방향 놀이의 노는 법은 그대로입니다.

## Validation

- 언어 순도: 가나 0, CJK 한자 0(정적 기계 검사).
- 금지 목록 grep: 0건.
- 독점 접선: 모든 놀이 페이지의 onHeadGesture 끄덕임이 주 확인, 방향 페이지 t05／t08／t13／t18의 _startSensor.
- 방향 맞힘 판정: _zone(0／1／2)을 ZONES.indexOf(목표)와 비교하며, 방향 글자와 직접 비교하지 않습니다.

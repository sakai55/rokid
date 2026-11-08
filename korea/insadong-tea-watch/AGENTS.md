# 인사동 차 지킴이 - Agent Notes

KR33. 한국 현지 × 주의력(여러 차 우리는 시간 지킴이) × 방향성(고개를 돌려 차 자리 바꾸기).

## Design contract

인사동 전통 찻집에서 차를 우리는 사람이 양손으로 찻주전자와 찻잔을 든 채 차를 바라보고 끄덕임으로 시간을 잰다.

## Counts

차 6종과 우리는 초: 보리차 180초/녹차 120초/유자차 240초/오미자차 300초/국화차 150초/생강차 210초.

## Storage

저장 키 `insadongTeaWatchV1`(선택한 차, 각 차의 시간 재기, 차 우리기 기록, lastError).

## Gesture map

| 한 번 누르기 | Enter | 주 확인 |
| 위아래 밀기 | ArrowUp / ArrowDown | 선택 전환 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## Honest boundaries

- 시간이 되기 전에 누르면 남은 시간만 알려주고 기록을 남기지 않는다.
- 때가 되면 한 차마다 한 번만 알려주며, 차 우리기 기록은 시간이 된 뒤의 확인으로만 남긴다.
- 센서가 없어도 단추로 차 자리를 바꿀 수 있으며, 시간 재기 자체는 센서에 기대지 않는다.

## Validation

- 한국어 순도: 가나 0, CJK 한자 0(정적 검사).
- 금지 목록 grep: 0건.
- 독점 접선: pages/watch/index.ink의 _startSensor + _onYaw + 끄덕임으로 시간 재기.

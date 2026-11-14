# 부산 어묵 끓이기 - Agent Notes

KR39. 한국 현지 × 주의력 × 방향성.

## Design contract

부산 어묵 가게에서 어묵을 끓이는 사람이 두 손이 바쁜 채 고개를 돌려 냄비를 고르고, 끄덕여 타이머를 시작한 뒤, 시간이 되면 음성으로 듣고 다 끓인 어묵을 꺼내 기록한다.

## Counts

내용 집합: 어묵 6가지와 초(어묵 꼬치 180／매운 어묵 240／치즈 어묵 300／야채 어묵 210／김말이 어묵 270／새우 어묵 150). 기록은 건수로 센다.

## Storage

저장 키 `busanEomukWatchV1`(고른 냄비, 냄비마다 타이머, 끓이기 기록 배열, lastError).

## Gesture map

| 한 번 누르기 | Enter | 주 확인(냄비 고르기·타이머 시작) |
| 위아래 밀기 | ArrowUp / ArrowDown | 냄비 선택 바꾸기 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## Honest boundaries

- 익힘 정도를 재지 않으며, 시간만으로 알려준다. 시간은 기준이며, 어묵 두께와 불 세기에 따라 달라진다.
- 센서를 쓸 수 없을 때는 버튼으로 냄비를 고를 수 있다.
- 기록은 다 끓인 어묵을 꺼냈을 때만 남는다.

## Validation

- 언어 순도: 가나 0, CJK 한자 0(정적 기계 검사).
- 금지 목록 grep: 0건.
- 독점 접선: pages/watch/index.ink의 _startSensor(존재 여부 확인) + _onYaw(±0.35에서 냄비 바꾸기, 정면으로 돌아오면 다시 준비) + onHeadGesture('nod')가 주 확인과 같다. 지키기 페이지는 onLoad에서 저장된 selected를 읽어 처음 자리를 정한다(busanEomukWatchV1).
- 센서 읽기 실패는 E7001.

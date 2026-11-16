# 템플스테이 안내 - Agent Notes

KR41. 한국 현지 × 커브컷 × 주의력.

## Design contract

템플스테이에 처음 온 사람이 양손에 짐을 든 채 휴대전화를 꺼내지 않고, 끄덕임으로 6단계 24걸음의 체험 과정을 하나씩 나아가며, 단계를 마치면 체험을 기록한다.

## Counts

내용 집합: 체험 6단계 × 각 4걸음, 모두 24걸음이다. 기록은 건수로 센다.

## Storage

저장 키 `templestayGuideV1`(고른 단계, 단계마다 마친 걸음 수, 체험 기록 배열, lastError).

## Gesture map

| 한 번 누르기 | Enter | 주 확인(단계 고르기·걸음 나아가기) |
| 위아래 밀기 | ArrowUp / ArrowDown | 단계 선택 바꾸기 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## Honest boundaries

- 체험 과정은 일반적인 템플스테이 흐름이며, 사찰마다 순서가 다를 수 있어 현장 안내가 기준이다.
- 수행 정도를 재지 않으며, 체험은 본인이 마치는 대로 기록한다.
- 4걸음을 마치지 않은 단계는 기록하지 않는다.
- 끄덕임을 쓸 수 없을 때는 버튼으로 나아갈 수 있다.

## Validation

- 언어 순도: 가나 0, CJK 한자 0(정적 기계 검사).
- 금지 목록 grep: 0건.
- 독점 접선: pages/guide/index.ink의 onHeadGesture('nod')가 primaryTap과 같은 한 걸음 나아가기이며, primaryTap은 다음 걸음을 음성으로 읽어준다. 단계 고르기는 버튼과 위아래 밀기로만 하며, 머리 센서는 쓰지 않는다.

# 노량진 수산시장 장보기 - Agent Notes

KR36. 한국 현지 × 방향성 × 주의력.

## Design contract

서울 노량진 수산시장에서 해산물을 사는 사람이 두 손에 봉지를 들고, 고개를 돌려 코너를 고르고 끄덕이며 4가지를 하나씩 확인한 뒤 구매를 기록한다.

## Counts

내용 집합: 코너 6곳 × 확인 4가지, 모두 24가지 확인 항목. 기록은 실제 수로 센다.

## Storage

저장 키 `noryangjinGuideV1`(고른 코너, 코너마다 확인한 항목 수, 구매 기록 배열, lastError).

## Gesture map

| 한 번 누르기 | Enter | 주 확인(상세 페이지에서는 한 가지 확인) |
| 위아래 밀기 | ArrowUp / ArrowDown | 코너 선택 바꾸기 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## Honest boundaries

- 가격과 신선도는 현장 매대가 정답이며, 안에 든 목록은 보기용이다.
- 4가지를 모두 확인하지 않은 코너는 기록하지 않는다.
- 센서를 쓸 수 없을 때는 버튼으로 코너를 고를 수 있다.

## Validation

- 언어 순도: 가나 0, CJK 한자 0(정적 기계 검사).
- 금지 목록 grep: 0건.
- 독점 접선: pages/index/index.ink의 _startSensor(존재 여부 확인) + _onYaw(±0.35로 코너 바꾸기, 정면으로 돌아오면 다시 준비) + onHeadGesture('nod')가 주 확인과 같다. 확인은 4가지를 모두 마쳤을 때만 구매 기록을 쓴다(noryangjinGuideV1).
- 센서 읽기 실패는 E7001.

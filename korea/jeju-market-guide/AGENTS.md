# 제주시장 안내 - Agent Notes

KR42. 한국 현지 × 방향성 × 주의력.

## Design contract

제주시장에서 장보는 사람이 양손에 장바구니를 든 채 고개를 돌려 가게를 고르고, 끄덕임으로 확인 항목을 하나씩 마친 뒤, 장보기가 끝나면 기록을 남긴다.

## Counts

내용 집합: 가게 6곳 × 확인 4가지, 모두 24가지 확인 항목이다. 기록은 건수로 센다.

## Storage

저장 키 `jejuMarketGuideV1`(고른 가게, 가게마다 확인한 항목 수, 장보기 기록 배열, lastError).

## Gesture map

| 한 번 누르기 | Enter | 주 확인(가게 고르기·확인하기) |
| 위아래 밀기 | ArrowUp / ArrowDown | 가게 선택 바꾸기 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## Honest boundaries

- 가격과 분량은 현장 가게 간판이 기준이며, 안에 있는 목록은 보기이다.
- 4가지를 확인하지 않은 가게는 기록하지 않는다.
- 센서를 쓸 수 없을 때는 버튼으로 가게를 고를 수 있다.

## Validation

- 언어 순도: 가나 0, CJK 한자 0(정적 기계 검사).
- 금지 목록 grep: 0건.
- 독점 접선: pages/index/index.ink의 _startSensor(존재 여부 확인) + _onYaw(±0.35에서 가게 바꾸기, 정면으로 돌아오면 다시 준비) + onHeadGesture('nod')가 주 확인과 같다. 확인은 4가지를 마쳤을 때만 장보기 기록을 쓴다(jejuMarketGuideV1).
- 센서 읽기 실패는 E7001.

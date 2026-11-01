# 한강 자전거 길 - Agent Notes

KR26. 한국 현지 x 지향성 x 주의

## Design contract

한강 자전거 길에서 자전거를 타는 사람이 양손으로 손잡이를 잡은 채로 갈래길을 고르고 GPS로 쉼터를 찾아 도착을 기록합니다.

## Counts

내용집 개수: 갈래길과 쉼터 8곳(뚝섬 갈래길, 잠실대교 갈래길, 반포대교 쉼터, 동작대교 갈래길, 여의도 쉼터, 양화대교 갈래길, 난지 쉼터, 망원 쉼터). 도착 기록은 실제 건수대로 셉니다.

## Storage

저장 키 `hangangCycleV1`(선택 갈래길, 등록한 쉼터의 위도와 경도와 등록 시각, 도착 기록 배열, lastError).

## Gesture map

| 제스처(관자놀이 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 두드리기 | Enter | 주 확인(각 페이지의 주 버튼) |
| 위로 밀기 / 아래로 밀기 | ArrowUp / ArrowDown | 선택 바꾸기 |
| 고개 끄덕임(머리가 멈췄을 때) | onHeadGesture nod | 주 확인과 같음 |
| 두 번 두드리기 | Backspace | 앞 페이지로 돌아가기 |

## Honest boundaries

- 거리는 오차를 포함한 어림값이며 정확한 길 거리가 아닙니다. 실내에서는 GPS가 약해 잴 수 없는 경우가 있습니다.
- 미등록 상태에서는 안내하지 않습니다. 등록하지 않은 장소를 만들어내지 않습니다.
- 머리 센서가 없을 때는 버튼으로 갈래길을 바꿉니다. 센서 값을 읽은 척하지 않습니다.

## Validation

- 언어 순도: ink 파일 안의 가나 0, 한자 0(정적 기계 검사).
- 금지 목록 검사: 코드 파일에서 0건.
- GPS 세 가지: app.json의 GEOLOCATION 선언, pages/index와 pages/guide의 getCurrentPosition 호출, pages/guide의 _calc 8방위 환산과 거리 계산.

# 감천 사진 확인 - Agent Notes

KR32. 한국 현지 × 방향성(시선 사진 확인) × 주의력.

## Design contract

부산 감천문화마을을 찾는 관광객이 양손으로 안내 책자를 든 채 명소를 바라보고 끄덕임으로 사진을 찍어 12곳의 사진 지점을 확인한다.

## Counts

명소 6곳 × 사진 지점 2곳 = 12곳의 사진 지점(감천문화마을 입구: 입구 안내판／마을 지도 앞; 작은 왕자 전망대: 작은 왕자 조형물／부산 항구 전망; 물고기 계단: 물고기 벽화／계단 전망; 감천 언덕길: 언덕길 벽화／골목길 풍경; 감천문화마을 박물관: 박물관 입구／마을 모형 앞; 감천 전망대: 전망대 전경／마을 지붕 풍경).

## Storage

저장 키 `gamcheonPhotoV1`(선택 명소, 확인한 사진 지점, 사진 시간과 바이트 수, 마친 산책 기록, lastError). 사진 자체는 세션 안에서만 보관하고 저장하지 않는다.

## Gesture map

| 한 번 누르기 | Enter | 주 확인 |
| 위아래 밀기 | ArrowUp / ArrowDown | 선택 전환 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## Honest boundaries

- 사진은 본인 확인용으로만 쓰며, 다른 사람의 얼굴을 인식하지 않고 명소를 자동으로 인식한다고 주장하지 않는다.
- 사진이 없으면 마칠 수 없고, 확인하지 않은 사진 지점은 알림만 하고 기록을 남기지 않는다.
- 미리 보기에는 카메라가 없어 사진이 정직하게 실패하며, 성공한 것처럼 꾸미지 않는다.

## Validation

- 한국어 순도: 가나 0, CJK 한자 0(정적 검사).
- 금지 목록 grep: 0건.
- 사진 접선: pages/photo/index.ink의 photoTap(getUserMedia + ImageCapture.takePhoto); Blob을 data URL로 바꾸는 데 arrayBuffer + 분할 btoa를 쓰며, FileReader = 0.

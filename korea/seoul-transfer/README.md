# Seoul Transfer

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-seoul-transfer
```

**AIX 직접 다운로드**(최신 버전): [seoul-transfer.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/seoul-transfer.aix)

한 줄 장면: 서울 지하철을 처음 타는 사람이 환승역에서 머리 방향으로 승강장 방향을 확인해 고정하고, 카운트다운으로 막차를 지킵니다.

방향 구성: 한국 현지 × 지향성 × 주의. 지향성은 환승 승강장 방향 확인 고리를 맡고(머리 yaw 좌우 확인 + 고개 끄덕임 고정), 주의는 막차 카운트다운 대기와 환승 기록 유지 고리를 맡으며, 현지는 서울 지하철의 실제 환승역 8곳과 노선에 뿌리내립니다.

## 미리보기 스크린샷

![전체 보기](<../../screenshots/seoul-transfer/preview-seoul-transfer-index.png>)
![환승 확인](<../../screenshots/seoul-transfer/preview-seoul-transfer-transfer.png>)
![환승 확인 2](<../../screenshots/seoul-transfer/preview-seoul-transfer-transfer-s2.png>)
![막차 대기](<../../screenshots/seoul-transfer/preview-seoul-transfer-lasttrain.png>)
![막차 대기 2](<../../screenshots/seoul-transfer/preview-seoul-transfer-lasttrain-s2.png>)

## 구조와 기능

- 페이지 목록(3개 페이지): 전체 보기 index(환승역 8곳 노선 띠 + 오늘 상태) / 환승 확인 transfer(역마다 방향 확인과 고정) / 막차 대기 lasttrain(수동 카운트다운 + 기록 표시).
- 콘텐츠 집합 수: 환승역 8곳(서울역·시청·종로3가·동대문역사문화공원·강남·잠실·홍대입구·고속터미널), 각 역에 환승 노선과 승강장 방향 한 문장 포함. 카운트다운 단계 5단계(5/10/15/20/30분).
- 폐쇄 루프: 전체 보기에 들어와 → 환승 페이지에서 역을 고르고, 방향 문장을 보고, 머리로 확인하고, 고개를 끄덕여 고정(TTS가 결론을 알리고 기록을 저장) → 막차 페이지에서 분을 고르고, 카운트다운을 시작하고, 시간이 되면 알리고 한 번 기록합니다. 기록은 세션을 넘어 저장되며(저장 키 `seoulTransferV1`), 반복해서 쓸 수 있습니다.

## 제스처 매핑

| 조작 | 효과 |
|---|---|
| 첫 페이지 ArrowUp/ArrowDown | 하위 페이지를 순환 선택(▶ 표시) |
| 첫 페이지 Enter | 선택한 하위 페이지 열기 |
| 하위 페이지 ArrowUp/ArrowDown | 이전/다음 항목(환승 페이지는 역 바꾸기, 막차 페이지는 분 바꾸기) |
| 하위 페이지 Enter | 주 동작(방향 고정 / 카운트다운 시작) |
| 고개 끄덕임 | 주 동작(Enter와 동일) |
| 머리 좌우 돌리기 | 환승 페이지에서 승강장 방향 확인 |

## 권한

없음. TTS는 호스트 고정 음색을 사용하고, utterance의 `lang`은 설정하지 않습니다.

## 정직한 경계

- 승강장 방향 문장은 내장 콘텐츠 집합이며, 온라인 연결이 없고 실시간 열차 시각과 승강장 변경 정보를 담지 않습니다. 막차 카운트다운은 사용자가 직접 설정한 알림이지 공식 시간표가 아닙니다.
- 센서를 쓸 수 없으면 페이지에 그대로 표시하고, 방향 고정은 Enter/고개 끄덕임으로도 완료할 수 있으며, 센서 값을 읽은 척하지 않습니다.

## 기기 테스트 정보

| 항목 | 내용 |
|---|---|
| Studio 이름 | 기입 예정 |
| Version | 1.0.0 |
| App Category | 기입 예정 |
| Intent Description | 기입 예정 |
| Agent ID | 기입 예정 |
| 상태 | 가져오지 않음 / 실기기 검증 전 |

## 심사 자료 (Review Submission)

- Feature Description: 서울 지하철 환승 도우미: 환승역 8곳의 노선과 승강장 방향 안내, 머리 방향으로 확인하고 고정, 막차 카운트다운 대기, 환승 기록을 세션을 넘어 저장합니다.
- Opening Message: 서울 지하철 환승역에서 방향을 확인하고 막차를 지키세요. 환승역 8곳의 방향 안내와 막차 카운트다운이 함께합니다.
- Preview Media: 미리보기 스크린샷은 위에 있습니다(스크린샷은 개발 과정 뒤에 추가, 최소 이미지 1개 + 동영상 1개, 동영상 ≤60초).
- Change Log (Build 1.0.0):
  - Features added: 환승역 8곳 방향 확인 페이지, 머리 yaw 방향 확인과 고개 끄덕임 고정, 막차 카운트다운 대기, 환승 기록 저장.
  - Improvements: 없음 (첫 버전).
  - Fixes: 없음 (첫 버전).

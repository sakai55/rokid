# 제주 여행 수첩

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-jeju-trip-hub
```

**AIX 직접 다운로드**(최신 버전): [jeju-trip-hub.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/jeju-trip-hub.aix)

KR22 · 한국 현지 × 집합 총괄 × 주의. 제주를 여행하는 사람이 수첩 한 권으로 여행 도구 20가지를 끝까지 사용합니다

## 미리보기 스크린샷

![preview-jeju-trip-hub-index.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-index.png)
![preview-jeju-trip-hub-t01.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t01.png)
![preview-jeju-trip-hub-t02.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t02.png)
![preview-jeju-trip-hub-t03.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t03.png)
![preview-jeju-trip-hub-t04.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t04.png)
![preview-jeju-trip-hub-t05.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t05.png)
![preview-jeju-trip-hub-t06.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t06.png)
![preview-jeju-trip-hub-t07.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t07.png)
![preview-jeju-trip-hub-t08.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t08.png)
![preview-jeju-trip-hub-t09.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t09.png)
![preview-jeju-trip-hub-t10.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t10.png)
![preview-jeju-trip-hub-t11.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t11.png)
![preview-jeju-trip-hub-t12.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t12.png)
![preview-jeju-trip-hub-t13.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t13.png)
![preview-jeju-trip-hub-t14.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t14.png)
![preview-jeju-trip-hub-t15.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t15.png)
![preview-jeju-trip-hub-t16.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t16.png)
![preview-jeju-trip-hub-t17.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t17.png)
![preview-jeju-trip-hub-t18.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t18.png)
![preview-jeju-trip-hub-t19.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t19.png)
![preview-jeju-trip-hub-t20.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t20.png)
![preview-jeju-trip-hub-t01-s2.png](../../screenshots/jeju-trip-hub/preview-jeju-trip-hub-t01-s2.png)

## 방향 구성

- 이 Agent의 방향 구성: 한국 현지 × 집합 총괄 × 주의. 각 방향은 장면 안에서 대체할 수 없는 한 고리를 맡으며, 기능 짜깁기가 아닙니다.
- 한 줄 장면: 제주를 여행하는 사람이 수첩 한 권으로 여행 도구 20가지를 끝까지 사용합니다.

## 구조와 기능

21개 페이지: `pages/index/` 여행 수첩 목록(도구 이름 20개를 다섯 개씩 창에 표시, 위아래로 고르고 Enter로 열기, 각 도구의 완료 수와 전체 진행과 기록 건수 표시). 도구 페이지는 각 하나의 기능입니다. 확인 체크리스트 10개 페이지(고개 끄덕임으로 항목마다 체크, 다 되면 완료 기록), 선택형 퀴즈 2개 페이지(각 3문항, 3지선다, 정오 TTS + 해설, 다 풀면 새로 시작), 대신 말하기 문구 4개 페이지(각 고정 문구 4개, 주 확인 즉시 TTS가 대신 말하고 기록), 세기 3개 페이지(목표에 닿으면 완료 기록, 목표 달성 뒤 다시 세면 새로 시작), 여행 기록 1개 페이지(최근 6건과 전체 건수). 각 도구 페이지의 기능과 콘텐츠 집합은 서로 다르고, 상태 변형을 페이지 수로 세지 않습니다.

| 도구 | 종류 | 항목 수 |
|---|---|---|
| t01 공항 도착 | 확인 체크리스트 | 4 |
| t02 렌터카 | 확인 체크리스트 | 5 |
| t03 버스 노선 | 확인 체크리스트 | 4 |
| t04 한라산 등산 | 확인 체크리스트 | 5 |
| t05 해변 산책 | 세기 | 목표 5곳 |
| t06 시장 | 확인 체크리스트 | 4 |
| t07 카페 주문 | 대신 말하기 | 문구 4개 |
| t08 박물관 | 확인 체크리스트 | 4 |
| t09 감귤 따기 | 세기 | 목표 10개 |
| t10 숙박 체크 | 확인 체크리스트 | 5 |
| t11 사진 명소 | 확인 체크리스트 | 4 |
| t12 기념품 목록 | 확인 체크리스트 | 6 |
| t13 환전 계산 | 선택형 퀴즈 | 3문항 |
| t14 날씨 옷차림 | 선택형 퀴즈 | 3문항 |
| t15 분실물 체크 | 확인 체크리스트 | 5 |
| t16 긴급 전화 | 대신 말하기 | 문구 4개 |
| t17 한국어 인사 | 대신 말하기 | 문구 4개 |
| t18 음식 주문 | 대신 말하기 | 문구 4개 |
| t19 환승 시간 | 세기 | 목표 4번 |
| t20 여행 기록 | 기록 보기 | 최근 6건 |

내용집 개수: 여행 도구 20개, 체크리스트 10개 페이지 46항목, 퀴즈 2개 페이지 6문항, 문구 4개 페이지 16문장, 세기 3개 페이지 목표 5곳과 10개와 4번, 사용 기록은 실제 건수대로 셉니다. 전체 진행 분모 93은 체크리스트 46 + 퀴즈 6 + 문구 16 + 세기 19 + 여행 기록 6의 합이며, 여행 기록 페이지는 최근 6건을 보여주는 것을 목표로 삼아 6으로 셉니다. 세션을 넘는 지속성: 저장 키 `jejuTripHubV1`(선택 도구, 체크 상태, 도구별 완료 수, 완료 기록 배열, `lastError`).

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 주 확인(각 페이지의 주 버튼) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 옵션 전환 / 위아래 항목 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 주 확인과 동등 |
| 두 번 탭 | Backspace | 이전 페이지로 돌아가기(하위 페이지) |

## 권한

없음. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다.

## 정직한 경계

- 각 도구의 안내와 문장은 수록된 정형 내용입니다. 실제 교통과 가게와 기관의 안내가 기준입니다.
- 실시간 시간표와 재고 정보는 없습니다. 버스 막차와 반납 시간 같은 항목은 사용자가 직접 확인하는 체크 항목입니다.
- 대신 말하기는 본인이 고른 정형 문장만을 읽습니다. 현장에서 새로 만든 말이 아닙니다.

## 오류 코드

실패하면 안경 화면에 코드만 표시되고, TTS는 코드만 읽으며, 가장 최근 오류는 지속 데이터의 `lastError`에 기록됩니다(코드, 이 기기의 slug, 버전, 원문 포함). 이 기기에서 나타날 수 있는 코드:

- `E5001` 기록 저장 실패(스토리지 쓰기 중 예외 발생)
- `E5002` 기록 읽기 실패(읽기/파싱 중 예외 발생)
- `E3005` 음성 안내 실패(TTS speak 중 예외 발생)
- `E8001` 페이지 전환 실패(navigateTo/navigateBack 중 예외 발생)

## 기기 테스트 정보

| 항목 | 내용 |
|---|---|
| Studio 이름 | 기입 예정 |
| Version | 1.0.0 |
| App Category | 기입 예정 |
| Intent Description | 기입 예정 |
| Agent ID | 기입 예정 |
| 상태 | 실기기 검증 전 |

## 심사 자료 (Review Submission)

Feature Description: 제주 여행 수첩: 제주를 여행하는 사람이 수첩 한 권으로 여행 도구 스무 가지를 끝까지 사용합니다. 체크리스트, 퀴즈, 대신 말하기 문구, 세기, 여행 기록이 각자의 집합을 갖추고 사용 기록이 저장됩니다.

Opening Message: 제주 여행을 떠나시나요. 여행 도구 스무 가지를 한 권의 수첩으로 써 보세요.

Preview Media:
- `preview-jeju-trip-hub-index.png`
- `preview-jeju-trip-hub-t01.png`
- `preview-jeju-trip-hub-t02.png`
- `preview-jeju-trip-hub-t03.png`
- `preview-jeju-trip-hub-t04.png`
- `preview-jeju-trip-hub-t05.png`
- `preview-jeju-trip-hub-t06.png`
- `preview-jeju-trip-hub-t07.png`
- `preview-jeju-trip-hub-t08.png`
- `preview-jeju-trip-hub-t09.png`
- `preview-jeju-trip-hub-t10.png`
- `preview-jeju-trip-hub-t11.png`
- `preview-jeju-trip-hub-t12.png`
- `preview-jeju-trip-hub-t13.png`
- `preview-jeju-trip-hub-t14.png`
- `preview-jeju-trip-hub-t15.png`
- `preview-jeju-trip-hub-t16.png`
- `preview-jeju-trip-hub-t17.png`
- `preview-jeju-trip-hub-t18.png`
- `preview-jeju-trip-hub-t19.png`
- `preview-jeju-trip-hub-t20.png`
- `preview-jeju-trip-hub-t01-s2.png`

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 녹화한 뒤 추가합니다.

Change Log — Build 1.0.0:

- Features added: 첫 버전. 제주를 여행하는 사람이 수첩 한 권으로 여행 도구 20가지를 끝까지 사용합니다
- Improvements: 없음 (첫 버전)
- Fixes: 없음 (첫 버전)

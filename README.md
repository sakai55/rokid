# 부산 여행 수첩

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-busan-trip-hub
```

**AIX 직접 다운로드**(최신 버전): [busan-trip-hub.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/busan-trip-hub.aix)

KR20 · 한국 현지 × 집합 총괄 × 주의 × 지향성. 부산을 여행하는 방문객이 수첩 한 권으로 여행 도구 20가지를 끝까지 사용하고, 등록한 장소에서 일행과 만납니다

## 미리보기 스크린샷

![preview-busan-trip-hub-index.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-index.png)
![preview-busan-trip-hub-t01.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t01.png)
![preview-busan-trip-hub-t02.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t02.png)
![preview-busan-trip-hub-t03.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t03.png)
![preview-busan-trip-hub-t04.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t04.png)
![preview-busan-trip-hub-t05.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t05.png)
![preview-busan-trip-hub-t06.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t06.png)
![preview-busan-trip-hub-t07.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t07.png)
![preview-busan-trip-hub-t08.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t08.png)
![preview-busan-trip-hub-t09.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t09.png)
![preview-busan-trip-hub-t10.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t10.png)
![preview-busan-trip-hub-t11.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t11.png)
![preview-busan-trip-hub-t12.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t12.png)
![preview-busan-trip-hub-t13.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t13.png)
![preview-busan-trip-hub-t14.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t14.png)
![preview-busan-trip-hub-t15.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t15.png)
![preview-busan-trip-hub-t16.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t16.png)
![preview-busan-trip-hub-t17.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t17.png)
![preview-busan-trip-hub-t18.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t18.png)
![preview-busan-trip-hub-t19.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t19.png)
![preview-busan-trip-hub-t20.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t20.png)
![preview-busan-trip-hub-t01-s2.png](../screenshots/busan-trip-hub/preview-busan-trip-hub-t01-s2.png)

## 방향 구성

- 이 Agent의 방향 구성: 한국 현지 × 집합 총괄 × 주의 × 지향성. 각 방향은 장면 안에서 대체할 수 없는 한 고리를 맡으며, 기능 짜깁기가 아닙니다. 한국 현지는 부산의 실제 장소와 생활 장면을, 집합 총괄은 도구 20개를 한 권의 수첩으로 묶는 허브를, 주의는 체크하고 챙기는 머무름을, 지향성은 집합 장소 안내의 방향과 거리 안내를 맡습니다.
- 한 줄 장면: 부산을 여행하는 방문객이 수첩 한 권으로 여행 도구 20가지를 끝까지 사용하고, 등록한 장소에서 일행과 만납니다.

## 구조와 기능

21개 페이지: `pages/index/` 여행 수첩 목록(도구 이름 20개를 다섯 개씩 창에 표시, 위아래로 고르고 열기로 열기, 각 도구 사용 건수와 전체 사용 건수 표시). 도구 페이지는 각 하나의 기능입니다. 확인 체크리스트 12개 페이지, 단계 목록 2개 페이지(각 4단계, 단계마다 확인), 대신 말하기 문구 2개 페이지(각 6문장, 고른 문장을 음성으로 대신 말하고 완료 기록), 환전 계산 1개 페이지(외화 금액과 환율을 버튼으로 바꾸고 곱해서 원으로 계산), 선택형 복장 1개 페이지(4가지 선택, 고르고 기록), 기록 목록 1개 페이지(긴급 전화 5개 번호, 듣고 기록 남기기), 집합 장소 안내 1개 페이지(위치 등록과 방향·거리 안내). 각 도구 페이지의 기능과 콘텐츠 집합은 서로 다르고, 상태 변형을 페이지 수로 세지 않습니다.

콘텐츠 집합 수: 여행 도구 20개, 지하철 노선 6항목, 버스 노선 5항목, 해운대 해수욕장 6항목, 감천문화마을 6항목, 자갈치시장 8항목, 음식 주문 문구 6문장, 환전 계산 1개(금액·환율 조절), 날씨 복장 4가지 선택, 숙박 체크 5항목, 사진 명소 6곳, 박물관 5곳, 부산타워 4단계, 용두산공원 5곳, 범어사 4단계, 영도 드라이브 5곳, 기념품 목록 8항목, 분실물 체크 6항목, 긴급 전화 5개 번호, 한국어 인사 6문장, 집합 장소 안내 1개(등록·길 안내). 사용 기록은 실제 건수대로 셉니다. 세션을 넘는 지속성: 저장 키 `busanTripHubV1`(선택 도구, 체크·단계·기록 상태, 완료 기록 배열, 집합 장소 등록 위치, `lastError`).

## 지피에스 연결 증거

- 권한 선언: `app.json`의 `permissions`에 `GEOLOCATION`만 포함됩니다.
- 위치 호출: `pages/t20/index.ink`의 `saveTap`(장소 등록)과 `guideTap`(길 안내)에서 `navigator.geolocation.getCurrentPosition`을 호출하며, 호출 전에 `typeof navigator`와 `navigator.geolocation` 존재 여부를 확인합니다.
- 방위 환산: 같은 파일의 `_calc`에서 위도와 경도 차이로 방위를 구하고 8방위(북·북동·동·남동·남·남서·서·북서)로 바꾸며, 하버사인 거리 계산을 10미터 단위로 반올림합니다.
- 오류 매핑: 같은 파일의 두 콜백에서 오류 코드 1(권한 거부)은 `E7003`, 그 밖의 오류는 `E7002`로 표시합니다.
- 미등록 처리: 등록된 장소가 없으면 `미등록`을 표시하고 위치를 지어내지 않습니다.

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 주 확인(각 페이지의 주 버튼) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 옵션 전환 / 위아래 항목 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 주 확인과 동등 |
| 두 번 탭 | Backspace | 이전 페이지로 돌아가기(하위 페이지) |

## 권한

`GEOLOCATION`만 선언합니다. 집합 장소 등록과 길 안내에만 쓰이며, 다른 페이지에서는 위치를 부르지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다.

## 정직한 경계

- 각 도구의 안내와 문장은 수록된 정형 내용입니다. 실제 가게와 기관의 안내가 기준입니다.
- 대신 말하기는 본인이 고른 정형 문장만을 읽습니다. 현장에서 새로 만든 말이 아닙니다.
- 집합 장소 안내의 방향과 거리는 대략적인 값입니다. 지피에스 신호가 약한 곳에서는 정확도가 떨어지며, 등록된 장소가 없으면 위치를 지어내지 않고 `미등록`을 표시합니다.

## 오류 코드

실패하면 안경 화면에 코드만 표시되고, TTS는 코드만 읽으며, 가장 최근 오류는 지속 데이터의 `lastError`에 기록됩니다(코드, 이 기기의 slug, 버전, 원문 포함). 이 기기에서 나타날 수 있는 코드:

- `E5001` 기록 저장 실패(스토리지 쓰기 중 예외 발생)
- `E5002` 기록 읽기 실패(읽기/파싱 중 예외 발생)
- `E3005` 음성 안내 실패(TTS speak 중 예외 발생)
- `E8001` 페이지 전환 실패(navigateTo/navigateBack 중 예외 발생)
- `E7002` 위치 찾기 실패(위치 오류 코드 2번·3번 및 위치 기능 없음)
- `E7003` 위치 권한 없음(위치 오류 코드 1번, 권한 거부)

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

Feature Description: 부산 여행 수첩: 부산 여행을 위한 수첩 한 권. 여행 도구 스무 가지(체크리스트, 단계 목록, 대신 말하기 문구, 환전 계산, 복장 선택, 긴급 전화 기록)가 각자의 집합을 갖추고 사용 기록이 저장되며, 집합 장소는 방향과 거리로 안내합니다.

Opening Message: 부산 여행을 떠나시나요. 여행 도구 스무 개를 한 권의 수첩으로 써 보고, 등록한 장소에서 일행과 만나세요.

Preview Media:
- `preview-busan-trip-hub-index.png`
- `preview-busan-trip-hub-t01.png`
- `preview-busan-trip-hub-t02.png`
- `preview-busan-trip-hub-t03.png`
- `preview-busan-trip-hub-t04.png`
- `preview-busan-trip-hub-t05.png`
- `preview-busan-trip-hub-t06.png`
- `preview-busan-trip-hub-t07.png`
- `preview-busan-trip-hub-t08.png`
- `preview-busan-trip-hub-t09.png`
- `preview-busan-trip-hub-t10.png`
- `preview-busan-trip-hub-t11.png`
- `preview-busan-trip-hub-t12.png`
- `preview-busan-trip-hub-t13.png`
- `preview-busan-trip-hub-t14.png`
- `preview-busan-trip-hub-t15.png`
- `preview-busan-trip-hub-t16.png`
- `preview-busan-trip-hub-t17.png`
- `preview-busan-trip-hub-t18.png`
- `preview-busan-trip-hub-t19.png`
- `preview-busan-trip-hub-t20.png`
- `preview-busan-trip-hub-t01-s2.png`

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 녹화한 뒤 추가합니다.

Change Log — Build 1.0.0:

- Features added: 첫 버전. 부산을 여행하는 방문객이 수첩 한 권으로 여행 도구 20가지를 끝까지 사용하고, 등록한 장소에서 일행과 만납니다
- Improvements: 없음 (첫 버전)
- Fixes: 없음 (첫 버전)

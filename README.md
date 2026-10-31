# 경주 여행 수첩

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-gyeongju-trip-hub
```

**AIX 직접 다운로드**(최신 버전): [gyeongju-trip-hub.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/gyeongju-trip-hub.aix)

KR23・한국 현지 × 집합 총괄 × 주의。경주를 여행하는 사람이 수첩 한 권으로 여행 도구 20가지를 끝까지 사용합니다

## 미리보기 스크린샷

![preview-gyeongju-trip-hub-index.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-index.png)
![preview-gyeongju-trip-hub-t01.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t01.png)
![preview-gyeongju-trip-hub-t02.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t02.png)
![preview-gyeongju-trip-hub-t03.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t03.png)
![preview-gyeongju-trip-hub-t04.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t04.png)
![preview-gyeongju-trip-hub-t05.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t05.png)
![preview-gyeongju-trip-hub-t06.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t06.png)
![preview-gyeongju-trip-hub-t07.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t07.png)
![preview-gyeongju-trip-hub-t08.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t08.png)
![preview-gyeongju-trip-hub-t09.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t09.png)
![preview-gyeongju-trip-hub-t10.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t10.png)
![preview-gyeongju-trip-hub-t11.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t11.png)
![preview-gyeongju-trip-hub-t12.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t12.png)
![preview-gyeongju-trip-hub-t13.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t13.png)
![preview-gyeongju-trip-hub-t14.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t14.png)
![preview-gyeongju-trip-hub-t15.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t15.png)
![preview-gyeongju-trip-hub-t16.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t16.png)
![preview-gyeongju-trip-hub-t17.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t17.png)
![preview-gyeongju-trip-hub-t18.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t18.png)
![preview-gyeongju-trip-hub-t19.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t19.png)
![preview-gyeongju-trip-hub-t20.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t20.png)
![preview-gyeongju-trip-hub-t01-s2.png](../screenshots/gyeongju-trip-hub/preview-gyeongju-trip-hub-t01-s2.png)

## 방향 구성

한국 현지 × 집합 총괄 × 주의。

## 구조와 기능

21개 페이지: `pages/index/` 여행 수첩 목록(도구 20개를 다섯 개씩 창에 표시, 위아래로 고르고 Enter로 열기, 기록 건수 표시). 도구 페이지는 각 하나의 기능입니다. 확인 체크리스트 11개 페이지(항목마다 체크, 다 되면 완료 기록), 세기 3개 페이지(목표에 닿으면 완료 기록), 문구 6개 페이지(고른 문장을 음성으로 대신 말하고 기록). 각 도구 페이지의 기능과 콘텐츠 집합은 서로 다르고, 상태 변형을 페이지 수로 세지 않습니다.

내용집 개수: 여행 도구 20개; 체크리스트 11개 페이지 44항목; 세기 3개 페이지 목표 4곳과 4곳과 5곳; 문구 6개 페이지 24문장; 사용 기록은 실제 건수대로 셉니다. 세션을 넘는 지속성: 저장 키 `gyeongjuTripHubV1`(선택 도구, 체크 상태, 완료 기록 배열, `lastError`).

| 도구 | 종류 | 항목 수 |
|---|---|---|
| t01 경주역 도착 | 확인 체크리스트 | 4 |
| t02 버스 노선 | 확인 체크리스트 | 4 |
| t03 불국사 | 확인 체크리스트 | 4 |
| t04 석굴암 | 확인 체크리스트 | 4 |
| t05 첨성대 | 세기 | 4 |
| t06 동궁과 월지 | 확인 체크리스트 | 4 |
| t07 황리단길 카페 | 문구 | 4 |
| t08 한옥 숙박 | 확인 체크리스트 | 4 |
| t09 시장 먹거리 | 확인 체크리스트 | 4 |
| t10 박물관 | 확인 체크리스트 | 4 |
| t11 자전거 대여 | 세기 | 4 |
| t12 사진 명소 | 확인 체크리스트 | 4 |
| t13 기념품 목록 | 확인 체크리스트 | 4 |
| t14 환전 계산 | 문구 | 4 |
| t15 날씨 옷차림 | 문구 | 4 |
| t16 분실물 체크 | 확인 체크리스트 | 4 |
| t17 긴급 전화 | 문구 | 4 |
| t18 한국어 인사 | 문구 | 4 |
| t19 음식 주문 | 문구 | 4 |
| t20 여행 기록 | 세기 | 5 |

제스처 매핑

## | 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 주 확인(각 페이지의 주 버튼) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 옵션 전환 / 위아래 항목 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 주 확인과 동등 |
| 두 번 탭 | Backspace | 이전 페이지로 돌아가기(하위 페이지) |

권한

## 없음. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다.

정직한 경계

## - 각 도구의 안내와 문장은 수록된 정형 내용입니다. 실제 교통과 가게와 기관의 안내가 기준입니다.
- 문구 대신 말하기는 본인이 고른 정형 문장만을 읽습니다. 현장에서 새로 만든 말이 아닙니다.

오류 코드

실패하면 안경 화면에 코드만 표시되고, TTS는 코드만 읽으며, 가장 최근 오류는 지속 데이터의 `lastError`에 기록됩니다(코드, 이 기기의 slug, 버전, 원문 포함). 이 기기에서 나타날 수 있는 코드:

- `E5001` 기록 저장 실패(스토리지 쓰기 중 예외 발생)
- `E5002` 기록 읽기 실패(읽기/파싱 중 예외 발생)
- `E3005` 음성 안내 실패(TTS speak 중 예외 발생)
- `E8001` 페이지 전환 실패(navigateTo/navigateBack 중 예외 발생)

## 기기 테스트 정보

| Studio 이름 | 미기입 |
| Version | 1.0.0 |
| App Category | 미기입 |
| Intent Description | 미기입 |
| Agent ID | 미기입 |
| 상태 | 실기기 미검증 |

## 심사 제출 자료

Feature Description: 경주를 여행하는 사람을 위한 수첩입니다. 여행 도구 20가지를 한 권에 모아, 체크와 세기와 문구 도구를 끝까지 쓰고 기록합니다.

Opening Message: 경주 여행을 확인합시다. 도구를 하나씩, 빠짐없이 챙깁니다.

Preview Media:
- `preview-gyeongju-trip-hub-index.png`
- `preview-gyeongju-trip-hub-t01.png`
- `preview-gyeongju-trip-hub-t02.png`
- `preview-gyeongju-trip-hub-t03.png`
- `preview-gyeongju-trip-hub-t04.png`
- `preview-gyeongju-trip-hub-t05.png`
- `preview-gyeongju-trip-hub-t06.png`
- `preview-gyeongju-trip-hub-t07.png`
- `preview-gyeongju-trip-hub-t08.png`
- `preview-gyeongju-trip-hub-t09.png`
- `preview-gyeongju-trip-hub-t10.png`
- `preview-gyeongju-trip-hub-t11.png`
- `preview-gyeongju-trip-hub-t12.png`
- `preview-gyeongju-trip-hub-t13.png`
- `preview-gyeongju-trip-hub-t14.png`
- `preview-gyeongju-trip-hub-t15.png`
- `preview-gyeongju-trip-hub-t16.png`
- `preview-gyeongju-trip-hub-t17.png`
- `preview-gyeongju-trip-hub-t18.png`
- `preview-gyeongju-trip-hub-t19.png`
- `preview-gyeongju-trip-hub-t20.png`
- `preview-gyeongju-trip-hub-t01-s2.png`

> 정식 심사 제출에는 미디어 파일 3~5점(그중 동영상 1점 이상, 60초 이하)이 필요합니다. 동영상은 GO가 실기기에서 녹화한 뒤에 추가합니다.

Change Log — Build 1.0.0:

- Features added: 초판
- Improvements: 없음(초판)
- Fixes: 없음(초판)

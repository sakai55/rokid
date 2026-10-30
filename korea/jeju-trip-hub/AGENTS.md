# 제주 여행 수첩 — Agent Notes

KR22 · 한국 현지 × 집합 총괄 × 주의. 한 줄 장면: 제주를 여행하는 사람이 수첩 한 권으로 여행 도구 20가지를 끝까지 사용합니다.

## Design contract

README의 구조와 기능 절을 따른다: 진입→과정→결과, 반복 사용 가능; 콘텐츠 집합은 항목 단위로 셀 수 있다; 세션을 넘는 지속성은 저장 키 `jejuTripHubV1`이다.

저장 키 `jejuTripHubV1`의 필드:

- `selected`: 목록에서 고른 도구 번호. 목록은 들어가기 전에 이 값을 저장하고, 돌아오면 이 값을 중심으로 다섯 개 창을 다시 그린다.
- `checked`: 도구별 체크 배열 (체크리스트 페이지).
- `tools`: 도구별 `{done, total}`. 목록은 이 값을 읽어 각 도구의 완료 수를 보여준다. 여행 기록 페이지(t20)는 이 값을 쓰지 않고, 목록이 기록 건수에서 최근 6건 기준으로 완료 수를 계산한다.
- `records`: 완료 기록 배열. 체크리스트와 퀴즈와 세기는 완료될 때 한 번만 쌓고, 대신 말하기는 말을 읽을 때마다 쌓는다. 같은 완료를 반복해 쌓지 않도록 `completed` 표시로 막는다.
- `completed`: 도구별 완료 표시. 완료 수가 전체에 못 미치면 풀린다.
- `spoken`: 도구별 이미 읽은 문구 배열 (대신 말하기 페이지, 겹치지 않게 센다).
- `counts`: 도구별 세기 값 (세기 페이지, 다시 열어도 이어진다).
- `quiz`: 도구별 `{qi, score, answered}` (퀴즈 페이지).
- `lastError`: `{code, slug: 'jeju-trip-hub', version: '1.0.0', orig}`.

## 21개 페이지

| 페이지 | 이름 | 종류 | 항목 수 |
|---|---|---|---|
| pages/index/ | 제주 여행 수첩 | 목록 (5개 창) | 도구 20개 |
| pages/t01/ | 공항 도착 | 확인 체크리스트 | 4 |
| pages/t02/ | 렌터카 | 확인 체크리스트 | 5 |
| pages/t03/ | 버스 노선 | 확인 체크리스트 | 4 |
| pages/t04/ | 한라산 등산 | 확인 체크리스트 | 5 |
| pages/t05/ | 해변 산책 | 세기 | 목표 5곳 |
| pages/t06/ | 시장 | 확인 체크리스트 | 4 |
| pages/t07/ | 카페 주문 | 대신 말하기 | 문구 4개 |
| pages/t08/ | 박물관 | 확인 체크리스트 | 4 |
| pages/t09/ | 감귤 따기 | 세기 | 목표 10개 |
| pages/t10/ | 숙박 체크 | 확인 체크리스트 | 5 |
| pages/t11/ | 사진 명소 | 확인 체크리스트 | 4 |
| pages/t12/ | 기념품 목록 | 확인 체크리스트 | 6 |
| pages/t13/ | 환전 계산 | 선택형 퀴즈 | 3문항 × 3지선다 |
| pages/t14/ | 날씨 옷차림 | 선택형 퀴즈 | 3문항 × 3지선다 |
| pages/t15/ | 분실물 체크 | 확인 체크리스트 | 5 |
| pages/t16/ | 긴급 전화 | 대신 말하기 | 문구 4개 |
| pages/t17/ | 한국어 인사 | 대신 말하기 | 문구 4개 |
| pages/t18/ | 음식 주문 | 대신 말하기 | 문구 4개 |
| pages/t19/ | 환승 시간 | 세기 | 목표 4번 |
| pages/t20/ | 여행 기록 | 기록 보기 | 최근 6건 + 전체 건수 |

전체 진행 분모 93 = 체크리스트 46 + 퀴즈 6 + 문구 16 + 세기 19 + 여행 기록 6.

동작 차이: 퀴즈는 마지막 문항까지 답하면 완료 기록을 쌓고, 다음 주 확인부터 새 판으로 다시 시작한다. 세기는 목표에 닿은 뒤 다시 세면 0부터 새로 시작한다. 세기 페이지에서 위로는 빼기, 아래로는 더하기이다. 여행 기록 페이지는 위아래로 기록을 고르고 주 확인으로 고른 기록을 읽는다.

## 제스처 매핑

| 제스처 | 키 이벤트 | 역할 |
|---|---|---|
| 한 번 탭 | Enter | 주 확인 |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 옵션 전환 / 위아래 항목 (세기: 빼기 / 더하기) |
| 고개 끄덕임 | `onHeadGesture('nod')` | 주 확인과 동등 |
| 두 번 탭 | Backspace | 이전 페이지로 돌아가기(하위 페이지) |

## Permissions

없음. `app.json`의 `permissions`는 빈 배열이다. TTS는 `typeof speechSynthesis`와 `typeof SpeechSynthesisUtterance` 수호 뒤에 부르고, `lang`을 설정하지 않는다.

## Validation

- `app.json` pages 21개와 `pages/` 디렉토리 21개가 일치한다.
- `node --check`로 `app.js`와 21개 페이지의 `<script setup>` 블록을 전부 통과했다.
- 페이지 파일 md5 중복 없음.
- 금지 API grep 전수 무적중: FileReader, sessionStorage, XMLHttpRequest, URL.createObjectURL, DOMParser, structuredClone, queueMicrotask, Notification, clipboard, Observer류, ServiceWorker, new Worker(, canvas.toDataURL, captureStream, getDisplayMedia, applyConstraints, TextDetector, onclick=, Page(, App(, Widget(, require(, workers.
- 색상: 순백 `#ffffff`과 흰색 rgba 무적중, 녹색 계열만 사용했다.
- 언어 순도 (`.ink` 파일 전수): 가나 0자, 한자 0자.
- 양식: 목록 / 체크리스트 / 퀴즈 / 대신 말하기 / 세기 / 기록 보기 6종 양식으로 나누었고, 띠와 버튼 스타일을 종류마다 다르게 했다.
- 미리보기 스크린샷과 aix 팩과 git 푸시는 이 작업 범위가 아니며, 부모 run에서 이어서 한다.

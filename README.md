# 김장 단계

**Studio 가져오기 주소**(Global AIUI Studio 가져오기 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-kimjang-steps
```

**최신 AIX 내려받기:** [kimjang-steps.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/kimjang-steps.aix)

## 개요

KR28 kimjang-steps — 한국 현지 × 배려 설계 × 주의력. 겨울에 온 가족이 김장을 담글 때, 양념 묻은 손으로 휴대폰을 꺼내지 않고 고개 끄덕임으로 단계를 넘깁니다.

## 장면

김장을 담그는 사람이 양손이 양념으로 바쁜 채로 안경을 쓰고 단계를 넘깁니다. 눈앞 안내가 지금 단계를 보여주고 음성 안내가 다음 단계를 읽어줍니다. 스물네 단계를 마치면 한 통이 기록됩니다.

## 방향 구성

한국 현지(겨울 김장) × 배려 설계(손이 바쁜 사람을 먼저 배려하는 설계) × 주의력(스물네 단계를 하나씩 확인하며 끝까지 따라가기). 단계 안내가 없으면 김장 순서가 흐트러지고, 고개 끄덕임이 없으면 양념 묻은 손으로 휴대폰을 만져야 합니다.

## 안경 전용 기능

양손이 양념으로 바쁠 때 고개 끄덕임으로 단계를 넘기는 눈앞 단계 안내. 고개 끄덕임이 없으면 이 장면은 성립하지 않습니다. 휴대폰을 꺼내면 손을 씻어야 하고 흐름이 끊깁니다.

연결 증거: 모든 페이지의 `onHeadGesture`가 `nod`를 `primaryTap`으로 넘기고, 단계 페이지 `pages/steps/index.ink`의 `nextTap`이 고개 끄덕임 한 번마다 다음 단계로 진행하며 음성 안내로 읽어줍니다. 스물네 단계를 마치면 같은 함수가 한 통 완성 기록을 씁니다.

## 솔직한 경계

소금 농도를 재지 않고 발효 정도를 재지 않습니다. 익음은 날짜와 본인 확인으로만 적습니다. 이 안내는 순서 안내일 뿐, 김장 맛을 보장하지 않습니다.

## 페이지

| 페이지 | 역할 |
|---|---|
| pages/index | 6개 단계 목록과 완성한 통 수 |
| pages/steps | 지금 단계와 다음 단계 안내, 고개 끄덕임으로 진행, 24단계 완성 시 기록 |
| pages/record | 최근 6건 완성 기록과 전체 건수 |

## 내용 집합

6개 단계 × 4단계씩, 모두 24단계: 배추 절이기(배추 가르기부터 헹구기까지), 양념 만들기, 버무리기, 통에 담기, 숙성 확인, 나눔 기록. 각 단계 문장은 단계 페이지 코드에 들어 있습니다.

## 저장

세션 간 저장 키 `kimjangStepsV1`. 진행 중인 단계 위치, 완성한 통 수, 완성 기록 배열, lastError를 저장합니다. 다음에 열면 이어서 진행합니다.

## 권한

권한을 사용하지 않습니다. 위치와 카메라는 사용하지 않습니다.

## 제스처

| 제스처 | 키 | 역할 |
|---|---|---|
| 한 번 누르기 | Enter | 주 동작(단계 시작, 다음 단계) |
| 위아래 밀기 | ArrowUp / ArrowDown | 단계 고르기 |
| 고개 끄덕이기 | `onHeadGesture('nod')` | 주 동작과 같음 |
| 두 번 누르기 | Backspace | 이전 페이지로 돌아가기 |

## 오류 코드

- `E5001` 저장 쓰기 실패
- `E5002` 저장 읽기 실패
- `E3005` 음성 안내 실패
- `E8001` 페이지 이동 실패

실패하면 화면에 코드만 표시하고, lastError에 코드와 slug, 버전, 원문을 남깁니다.

## 미리보기 스크린샷

![preview-kimjang-steps-index.png](../screenshots/kimjang-steps/preview-kimjang-steps-index.png)
![preview-kimjang-steps-steps.png](../screenshots/kimjang-steps/preview-kimjang-steps-steps.png)
![preview-kimjang-steps-steps-s2.png](../screenshots/kimjang-steps/preview-kimjang-steps-steps-s2.png)
![preview-kimjang-steps-record.png](../screenshots/kimjang-steps/preview-kimjang-steps-record.png)

## 제출 자료

### 기능 설명

손이 양념으로 바쁠 때 김장 단계를 눈앞에서 안내합니다. 여섯 단계 스물네 단계를 고개 끄덕임으로 넘기며 음성 안내를 듣고, 스물네 단계를 마치면 한 통이 기록됩니다. 소금 농도나 발효 정도를 재지 않으며, 익음은 날짜와 본인 확인으로만 적습니다.

### 시작 메시지

김장 단계 안내입니다. 단계를 고르고 고개를 끄덕이면 다음 단계로 넘어갑니다. 손이 바빠도 눈앞 안내와 음성 안내로 스물네 단계를 마칠 수 있습니다.

### 미리보기 미디어

[preview-kimjang-steps-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/kimjang-steps/preview-kimjang-steps-video.mp4) + 이미지 3장(preview-kimjang-steps-index.png, preview-kimjang-steps-steps-s2.png, preview-kimjang-steps-record.png), 모두 4개 파일.

### 변경 기록

- Features added: 6개 단계 24단계 안내, 고개 끄덕임 진행과 음성 안내, 한 통 완성 기록.
- Improvements: 없음(초판).
- Fixes: 없음(초판).

## 기기 테스트 정보

| 항목 | 값 |
|---|---|
| Studio 이름 | 입력 전 |
| 버전 | 1.0.0 |
| 분류 | 입력 전 |
| 의도 설명 | 입력 전 |
| Agent ID | 입력 전 |
| 상태 | 가져오지 않음 |

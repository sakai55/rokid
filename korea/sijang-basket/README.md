# Sijang Basket (시장 장바구니 Market Basket)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-sijang-basket
```

**AIX 직접 다운로드**(최신 버전): [sijang-basket.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/sijang-basket.aix)

KR14 · 한국 현지 × 주의(HOLD). 한국 전통시장(시장) 쇼핑객이 가판대별로 장바구니를 항목마다 확인하고, 한 가지라도 빠지면 계산하지 않습니다. 상호작용 철학: **시장 장바구니 Market Basket**.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/sijang-basket/preview-sijang-basket-index.png>)
![미리보기-s2](<../../screenshots/sijang-basket/preview-sijang-basket-s2.png>)
![미리보기-s3](<../../screenshots/sijang-basket/preview-sijang-basket-s3.png>)
![미리보기-s4](<../../screenshots/sijang-basket/preview-sijang-basket-s4.png>)

## 방향 구성

- 이 Agent의 방향 구성: 한국 현지 × 주의(HOLD). 각 방향은 장면 안에서 대체할 수 없는 한 고리를 맡으며, 기능 짜깁기가 아닙니다(일본 그룹 개념은 부티크 라인의 조합 통칙으로 판정하고, 자유 그룹 개념은 장면의 핵심에 따라 주 방향 번호를 정합니다).
- 한 줄 장면: 한국 전통시장(시장) 쇼핑객이 가판대별로 장바구니를 항목마다 확인하고, 한 가지라도 빠지면 계산하지 않습니다.

## 기능 흐름 (폐쇄 루프)

- 진입: 열면 바로 현재 항목과 진행도가 표시되고, 현재 항목이 큰 글자로 시선 중앙에 옵니다.
- 과정: NEXT로 다음 항목 선택, CHECK로 현재 항목 확인, PREV로 이전 항목으로 돌아갑니다. 고개 끄덕임(머리가 안정됐을 때)은 주 확인과 동등합니다. SPEAK는 언제든 현재 상태를 읽어줍니다.
- 결과: 모든 항목을 확인하면 한 바퀴로 셉니다(순회/완료 수 +1). 반복해서 쓸 수 있습니다. DEMO는 데모 상태 머신이며, 종료하면 실제 상태가 그대로 복원됩니다.

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(현재 항목 확인 / 음성 안내) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(CHECK와 동등) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| (없음) | 이 Agent는 어떤 권한도 신청하지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다 |

## 정직한 경계

- 구매 여부는 본인의 확인만 기록한다. 가게 시스템과 연결되지 않는다.
- 가격과 흥정은 가게 안내가 기준이다. Agent는 가격을 정하지 않는다.

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).
- 녹색 계조: CSS는 녹색 계조만 사용하고 순백과 흰색 rgba는 금지합니다. 버튼 스타일은 이 Agent의 UI 형태에 맞춰 정하고 기본 버튼을 공유하지 않습니다.

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/git-rokid/korea/sijang-basket
~/tools/bin/aix pack . -o ../../aix/sijang-basket.aix
~/tools/bin/aix list ../../aix/sijang-basket.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Sijang Basket (가져오기 후 기입 예정) |
| Version / Build | 1.0.0 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | Sijang basket: a traditional-market basket ledger. Register stalls in order, check each purchase off as it is bought, and never settle with a missing item. It holds the basket, not the money, and it never scans anything. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 시장 장바구니: 전통시장 장바구니 장부. 가판대를 순서대로 등록하고, 사는 대로 각 구매를 체크하며, 한 가지라도 빠지면 절대 계산하지 않습니다. 돈이 아닌 장바구니를 지키고, 아무것도 스캔하지 않습니다.

### Opening Message

> ## Sijang Basket
>
> 시장 장바구니: 전통시장 장바구니 장부. 가판대를 순서대로 등록하고, 사는 대로 각 구매를 체크하며, 한 가지라도 빠지면 절대 계산하지 않습니다. 돈이 아닌 장바구니를 지키고, 아무것도 스캔하지 않습니다.

### Preview Media

- `preview-sijang-basket-index.png` — 초기 상태
- `preview-sijang-basket-s2.png` — 데모 상태 2
- `preview-sijang-basket-s3.png` — 데모 상태 3
- `preview-sijang-basket-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 시장 장바구니 Market Basket. 한국 전통시장(시장) 쇼핑객이 가판대별로 장바구니를 항목마다 확인하고, 한 가지라도 빠지면 계산하지 않습니다

**Improvements**

- 없음 (첫 버전)

**Fixes**

- 없음 (첫 버전)

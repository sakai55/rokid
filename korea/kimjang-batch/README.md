# Kimjang Batch (김장철 대량 배치 카운터)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-kimjang-batch
```

**AIX 직접 다운로드**(최신 버전): [kimjang-batch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/kimjang-batch.aix)

KR08 · 한국 현지화 시리즈. 상호작용 철학: **배치 큰 숫자 Batch Counter**. 이 Agent는 양념 묻은 손을 위해 설계됐습니다. 화면에는 62px 큰 숫자 하나뿐입니다. 현재 단계의 배추 포기입니다. 세는 방법은 고개 끄덕임(+1)과 음성 명령(호스트 인식이 「다음」을 들으면 +1, 인식을 못 쓰면 자동으로 격하하고 명시함)이라 손은 거의 아무것도 만질 필요가 없습니다. +10은 한 바구니 통째로 셀 때, 아래로 스와이프하면 -1로 정정합니다. 세 단계 공정이 각자 세고, 단계 목표에 닿아야 다음 단계를 열어줍니다. 배추 품질을 알아보지도, 레시피를 제공하지도 않습니다(그건 요리책과 혜안의 일). 당신이 두 손이 가장 바쁠 때, "몇까지 셌지"를 단단히 붙잡아 줄 뿐입니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/kimjang-batch/preview-kimjang-batch-index.png>)
![미리보기-s2](<../../screenshots/kimjang-batch/preview-kimjang-batch-s2.png>)
![미리보기-s3](<../../screenshots/kimjang-batch/preview-kimjang-batch-s3.png>)
![미리보기-s4](<../../screenshots/kimjang-batch/preview-kimjang-batch-s4.png>)

## 현지성

김장은 한국 초겨울의 가족 단위 대작업입니다. 배추 수십에서 백 포기가 절이기→헹구기→양념 바르기 세 단계 공정을 거치고, 손에는 고춧가루가 묻어 있어, 한 번 잘못 세면 소금과 양념의 비율이 전부 어긋납니다.

## 기능 흐름 (폐쇄 루프)

- 큰 숫자: 한 화면에 거대한 숫자 하나로 세고, 단계 띠에 절이기/헹구기/양념 바르기 중 현재 단계와 단계 목표를 표시합니다
- 손 안 쓰기: 고개 끄덕임 +1, 음성 「다음」 +1(ASR 가드 방식, 실패하면 격하를 명시), +10은 바구니 단위, 아래로 스와이프 -1 정정
- 단계 전진: STAGE는 단계 목표에 닿은 뒤에야 다음 단계를 열어줍니다(닿지 않았으면 거부하고 몇 포기 부족한지 알립니다)

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(+1과 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| `RECORD_AUDIO` | 마이크/음성 경로(강도 분석 또는 ASR. 저장하지 않음) |

## 정직한 경계

- 음성 세기는 호스트 ASR(한국어 명령 다음)에 의존합니다. 주변이 시끄러우면 빠뜨릴 수 있습니다. 세는 기준은 화면의 큰 숫자이며, 빠뜨린 것은 +10/아래 스와이프로 그 자리에서 고치세요
- 포기 수 목표는 데모용 60포기입니다. 소금과 양념 비율은 이 Agent의 범위가 아니니 집안 레시피를 따르세요

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/kimjang-batch
~/tools/bin/aix pack . -o ../dist/kimjang-batch.aix
~/tools/bin/aix list ../dist/kimjang-batch.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Kimjang Batch (가져오기 후 기입 예정) |
| Version / Build | 1.0.2 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | During kimjang in Korea: counts cabbage batches per stage by nod and voice, hands-free. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 고춧가루 묻은 손을 위한 김장 배치 카운터: 단계마다 62픽셀 숫자 하나. 절이기, 헹구기, 양념 바르기. 고개를 끄덕이면 하나, '다음'이라 말하면 하나(가드가 붙은 음성 인식, 정직한 폴백), 바구니마다 +10, 아래로 스와이프해 정정. 단계 목표가 공정의 문을 지킵니다. 세는 것은 제 일, 레시피는 당신의 것입니다.

### Opening Message

> ## Kimjang Batch
> 
> 배추 예순 포기, 세 단계, 그리고 아무것도 만질 수 없는 두 손. 그래서 거대한 숫자 하나를, 고개 끄덕임과 목소리로 셉니다. 절이기, 헹구기, 양념 바르기를 지나며 개수를 단단히 지켜드립니다. 가족 레시피는 당신이 지켜주세요.

### Preview Media

- `preview-kimjang-batch-index.png` — 초기 상태
- `preview-kimjang-batch-s2.png` — 데모 상태 2
- `preview-kimjang-batch-s3.png` — 데모 상태 3
- `preview-kimjang-batch-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 배치 큰 숫자 Batch Counter. 거대한 숫자 세는 화면: 한 화면에 큰 숫자 하나 + 단계 띠

**Improvements**

- 없음 (첫 버전)

**Fixes**

- 없음 (첫 버전)

### Change Log (Build 1.0.1)

**Features added**

- 없음

**Improvements**

- 버튼을 이 Agent의 UI 형태에 맞게 개별 스타일링했습니다(형태는 설계 계약 참조). 더 이상 시리즈 전체가 같은 버튼 세트를 공유하지 않습니다

**Fixes**

- 실제 기기의 단색 녹색 패널에 맞춘 색상 조정: 기존 순백 #ffffff를 녹색 계조로 바꿨고(가장 밝은 녹색 #7dff9e), 명암은 녹색만으로 표현합니다

### Change Log (Build 1.0.2)

**Features added**

- 없음

**Improvements**

- 없음

**Fixes**

- 언어 순화: 화면과 음성 문구를 현지 언어(일본=일본어 / 한국=한국어)로 통일하고, 섞여 있던 일본어·중국어 문구(SCAN 프롬프트 포함)를 하나씩 점검해 제거했습니다

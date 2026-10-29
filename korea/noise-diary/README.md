# Noise Diary (층간소음 야간 일기)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-noise-diary
```

**AIX 직접 다운로드**(최신 버전): [noise-diary.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/noise-diary.aix)

KR02 · 한국 현지화 시리즈. 상호작용 철학: **야간 일기 Night Diary**. 이 Agent는 자기 집의 장부만 기록합니다. 밤에 자기 집 가까운 곳의 소리를 지키고 서서, 임계값을 넘은 순간을 22:00→06:00 호 위에 핀으로 꽂고, 아침에 일어나 한 번 되짚어 읽어줍니다. 어젯밤 몇 번 울렸는지, 가장 컸던 건 몇 시였는지. 녹음하지 않고, 받아쓰지 않고, 이웃을 가리키지 않습니다(착용자 가까운 곳만 재고 방향은 그대로 밝힙니다). 밤중에 실시간으로 당신을 탓하지도 않습니다. 밤에는 조용히 기록하고, 아침에 당신이 일기를 봅니다. 베이스 자막/전사와 근본적으로 다른 점은 이것입니다. 소리의 내용이 무엇인지조차 모르고, "몇 시에, 집에서 한 번 울렸다"는 것만 압니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/noise-diary/preview-noise-diary-index.png>)
![미리보기-s2](<../../screenshots/noise-diary/preview-noise-diary-s2.png>)
![미리보기-s3](<../../screenshots/noise-diary/preview-noise-diary-s3.png>)
![미리보기-s4](<../../screenshots/noise-diary/preview-noise-diary-s4.png>)

## 현지성

층간소음은 한국 아파트 생활의 가장 큰 이웃 갈등이며, 전문 조정 기관과 「이웃사이센터」까지 있을 정도입니다. 갈등의 다른 면도 있습니다. 자기 집 아이가 뛰어다니는 소리, 세탁기를 밤에 돌리는 소리, 의자 끄는 소리가 아래층에서 얼마나 크게 들리는지 모르는 사람이 많다는 것입니다.

## 기능 흐름 (폐쇄 루프)

- 지키기: 밤에 ARM한 뒤에는 음압 피크 사건만 셉니다(녹음해 저장하지 않음). 사건은 시각대로 야간 호 위에 핀으로 꽂힙니다
- 일기: 피크 사건은 시각과 상대 강도를 남기고(앞 3건), 나머지는 개수만 셉니다
- 되짚기: REVIEW가 어젯밤 요약(횟수/가장 컸던 시각/조용했던 구간)을 읽어주고, 고개를 끄덕이면 어젯밤 기록을 비우며, 페이지를 닫으면 잊어버립니다

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(ARM과 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| `RECORD_AUDIO` | 마이크/음성 경로(강도 분석 또는 ASR. 저장하지 않음) |

## 정직한 경계

- 가까운 곳의 음압으로는 소리의 출처(우리 집/위층/창밖)를 구분할 수 없습니다. 일기가 증명하는 것은 "이 근처에서 울렸다"는 것뿐이고, 원인의 판단은 사람이 시각과 함께 내려야 하며, 화면에 명시됩니다
- 음압은 상대 강도이며 보정된 데시벨이 아닙니다. 마이크를 쓸 수 없으면 SKIP이라 알리고 일기를 지어내지 않습니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/noise-diary
~/tools/bin/aix pack . -o ../dist/noise-diary.aix
~/tools/bin/aix list ../dist/noise-diary.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Noise Diary (가져오기 후 기입 예정) |
| Version / Build | 1.0.2 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | In a Korean apartment at night: logs the wearer home loud-moment times for a morning self-review. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 한국 아파트를 위한 층간소음 야간 일기: 지키는 것은 당신 집의 장부뿐입니다. 밤에 무장하면 큰 소리가 난 순간을 22:00~06:00 호 위에 핀으로 꽂습니다. 시각과 상대 강도만 남기고, 녹음도 내용도 없습니다. 아침에는 일기를 한 번 읽어줍니다. 피크가 몇 번이었는지, 가장 컸던 건 몇 시였는지. 이웃을 가리키는 일은 절대 없습니다.

### Opening Message

> ## Noise Diary
> 
> 자기가 내는 줄도 몰랐던 소음은 고칠 수 없습니다. 밤에 저를 무장시키면, 저는 이 집의 큰 소리 순간들을 조용히 일기로 남깁니다. 녹음도, 말도 없이, 밤의 호 위에 핀만 꽂습니다. 아침에 함께 한 번 읽어봅시다.

### Preview Media

- `preview-noise-diary-index.png` — 초기 상태
- `preview-noise-diary-s2.png` — 데모 상태 2
- `preview-noise-diary-s3.png` — 데모 상태 3
- `preview-noise-diary-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 야간 일기 Night Diary. 시계 호: 밤 8시간 호 + 피크 시각 점, 아침 되짚기

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

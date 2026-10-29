# Baedal Code (배달 암호 금고)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-baedal-code
```

KR10 · 한국 현지화 시리즈. 상호작용 철학: **한 글자씩 여는 금고 Digit Vault**. 이 Agent는 한 줄기 틈만 열리는 금고입니다. 네 자리 암호가 네 개의 숫자 칸에 나뉘어 살고, REVEAL은 한 번에 한 자리만 열어 보이며 8초 뒤 자동으로 닫습니다. GO는 숫자 자체를 절대 말하지 않고(소리 내어 말하면 새어 나가므로) 조작 안내만 말합니다. 주문번호는 다른 칸에 있습니다(ORDER로 전환 표시). WIPE 한 번이면 전부 파기되고, 모든 상태는 페이지 메모리에만 살아 있습니다. 저장 호출이 전혀 없어 페이지를 닫으면 잊어버립니다. 이것이 프라이버시 설계이자 정직한 경계입니다. 잃어버리면 그걸로 끝이니, 본인의 비밀번호는 따로 기억해 두세요. 이 Agent는 배달 절차 자체는 다루지 않습니다(플랫폼 앱의 일입니다). 라이더가 전화하는 그 10초 동안, 암호를 안전하게 눈앞에 건네는 것만 합니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/baedal-code/preview-baedal-code-index.png>)
![미리보기-s2](<../../screenshots/baedal-code/preview-baedal-code-s2.png>)
![미리보기-s3](<../../screenshots/baedal-code/preview-baedal-code-s3.png>)
![미리보기-s4](<../../screenshots/baedal-code/preview-baedal-code-s4.png>)

## 현지성

한국의 배달 문화와 아파트 생활이 맞물려 생기는 잦은 작은 번거로움: 공동현관 비밀번호, 세대 현관 코드, 주문번호. 라이더가 아래층에 도착해 전화로 물어볼 때, 당신은 휴대폰을 뒤질 손이 없고, 비밀번호를 옆 사람 앞에서 소리 내어 말할 수도 없습니다.

## 기능 흐름 (폐쇄 루프)

- 등록: 암호는 데모용 4자리입니다(실사용 시 그때의 주문 코드로 교체해 등록, 방법은 README 참조). 평소에는 전부 ●로 가려집니다
- 공개: REVEAL이 한 번에 한 자리씩 엽니다(1회 1자리). 8초 타이머가 지나면 자동으로 가려집니다. GO는 안내만 말하고 숫자는 절대 읽지 않습니다
- 파기: WIPE가 암호와 주문 표시를 비웁니다. 전 과정 저장 API 호출이 전혀 없고, 페이지를 닫으면 잊어버립니다(코드로 확인 가능)

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 상황별 GO(README 기능 흐름과 화면 guide 줄 참조) |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 화면 guide 줄에 적힌 이 Agent 전용 정의 참조 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 이 Agent의 주 확인(REVEAL과 동등, guide 줄 참조) |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(가로채지 않음) |

화면 버튼은 모두 위 제스처의 미러링이며, SPEAK(언제든 현재 상태 듣기)와 DEMO(데모 상태 머신, 종료하면 실제 상태가 그대로 복원됨)가 추가됩니다.

## 권한

| 권한 | 용도 |
|---|---|
| (없음) | 이 Agent는 어떤 권한도 신청하지 않습니다. TTS와 센서는 매니페스트 권한이 필요 없고, 카메라는 호출하지 않습니다(해당하는 경우) |

## 정직한 경계

- 데모 암호는 가짜 코드입니다. 실제 암호는 어떤 저장소 파일에도 적지 말고, 기기 페이지 안에서만 등록하세요(이 페이지의 메모리)
- 자동 가림은 이 페이지의 타이머에 의존합니다. 페이지를 닫으면 암호는 바로 사라집니다(설계가 그렇습니다). 이 Agent는 배달 플랫폼과 연동되지 않습니다

- TTS는 호스트 고정 음색을 사용하며, utterance의 `lang`은 절대 설정하지 않습니다(공식 문서에 효과가 없다고 명시됨).

## 패키징과 미리보기

```bash
cd ~/workspace/rokid/baedal-code
~/tools/bin/aix pack . -o ../dist/baedal-code.aix
~/tools/bin/aix list ../dist/baedal-code.aix
```

## 실기기 테스트 정보

| 필드 | 값 |
|---|---|
| Studio 이름 | Baedal Code (가져오기 후 기입 예정) |
| Version / Build | 1.0.2 / 가져오기 후 기입 예정 |
| App Category | Life |
| Intent Description | When a delivery rider calls in Korea: reveals a gate/order code one digit at a time, auto-masking, zero storage. |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 로컬 빌드 완료, Studio 가져오기 대기 중 |

## 심사 자료 (Review Submission)

### Feature Description

> 한국 아파트 생활을 위한 배달 코드 금고: 현관 코드는 네 개의 숫자 칸 뒤에 살고, 한 번에 한 자리씩 열리며 8초 뒤 자동으로 가려집니다. GO는 안내만 말하고 숫자는 절대 말하지 않습니다. WIPE로 지우면 끝, 저장되는 것은 없습니다. 페이지를 닫으면 코드는 설계상 사라집니다.

### Opening Message

> ## Baedal Code
> 
> 라이더는 아래층에 있고, 두 손은 가득 차 있으며, 현관 코드는 소리 내어 말할 수 없습니다. 저는 한 번에 숫자 칸 하나씩, 여덟 초씩 열고, 숫자를 입 밖에 내지 않습니다. 저를 지우든 닫든, 저는 아무것도 남기지 않습니다.

### Preview Media

- `preview-baedal-code-index.png` — 초기 상태
- `preview-baedal-code-s2.png` — 데모 상태 2
- `preview-baedal-code-s3.png` — 데모 상태 3
- `preview-baedal-code-s4.png` — 데모 상태 4

> 정식 심사 제출에는 미디어 파일 3~5개가 필요하고 동영상(≤60초) 1개 이상이 포함되어야 합니다. 동영상은 GO가 실기기로 직접 테스트할 때 추가로 녹화합니다.

### Change Log (Build 1.0.0)

**Features added**

- 첫 버전: 한 글자씩 여는 금고 Digit Vault. 금고 숫자판: 네 개의 숫자 칸, 한 번에 한 자리만 열림

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

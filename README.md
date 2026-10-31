# 경복궁 관람

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-gyeongbok-palace
```

**AIX 직접 다운로드**(최신 버전): [gyeongbok-palace.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/gyeongbok-palace.aix)

KR25・한국 현지 × 주의 × 길잡이。경복궁을 처음 찾는 관람객이 여섯 곳을 차례로 확인하며 관람을 마친다

## 미리보기 스크린샷

![preview-gyeongbok-palace-index.png](../screenshots/gyeongbok-palace/preview-gyeongbok-palace-index.png)
![preview-gyeongbok-palace-check.png](../screenshots/gyeongbok-palace/preview-gyeongbok-palace-check.png)
![preview-gyeongbok-palace-record.png](../screenshots/gyeongbok-palace/preview-gyeongbok-palace-record.png)
![preview-gyeongbok-palace-check-s2.png](../screenshots/gyeongbok-palace/preview-gyeongbok-palace-check-s2.png)

## 방향 구성

한국 현지 × 주의 × 길잡이。

## 구조와 기능

3개 페이지: `pages/index/` 관람 장소 목록(장소 6곳: 광화문 보기, 근정전 보기, 경회루 보기, 향원정 보기, 고궁박물관 보기, 민속박물관 보기); `pages/check/` 관람 체크(5개 항목: 입장 확인하기, 관람 순서 확인하기, 설명 읽기, 사진 찍기, 소감 적기——항목마다 바꾸고, 5개가 모이면 음성으로 알리고 기록에 남긴다); `pages/record/` 기록(최근 6건과 합계).

내용집 개수: 장소 6곳; 체크 항목 5개; 기록은 실제 건수대로 셉니다. 세션을 넘는 지속성: 저장 키 `gyeongbokPalaceV1`(선택 장소, 체크 상태, 기록 배열, `lastError`).

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

## - 개관 시간과 입장 여부는 Agent가 알지 못합니다. 현장 안내가 정확합니다.
- 완료 기록은 본인 확인으로만 남습니다. 관람을 대신하지 않습니다.

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

Feature Description: 경복궁을 처음 찾는 사람을 위한 안내입니다. 장소 6곳과 확인 항목을 차례로 확인하고, 5개가 모이면 완료 기록을 남깁니다.

Opening Message: 경복궁 관람을 확인합시다. 장소와 확인 항목을 하나씩, 빠짐없이 챙깁니다.

Preview Media:
- `preview-gyeongbok-palace-index.png`
- `preview-gyeongbok-palace-check.png`
- `preview-gyeongbok-palace-record.png`
- `preview-gyeongbok-palace-check-s2.png`

> 정식 심사 제출에는 미디어 파일 3~5점(그중 동영상 1점 이상, 60초 이하)이 필요합니다. 동영상은 GO가 실기기에서 녹화한 뒤에 추가합니다.

Change Log — Build 1.0.0:

- Features added: 초판
- Improvements: 없음(초판)
- Fixes: 없음(초판)

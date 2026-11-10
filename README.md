# 광장시장 장보기

**Studio 가져오기 주소**(Global AIUI Studio Import Project 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-gwangjang-market
```

[gwangjang-market.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/gwangjang-market.aix)

## 개요

서울 광장시장에서 간식을 사는 사람이 두 손에 봉지를 들고, 고개를 돌려 가게를 고르고 끄덕이며 4가지를 하나씩 확인한 뒤 구매를 기록한다.

## 장면

서울 광장시장에서 간식을 사는 사람이 두 손에 봉지를 들고, 고개를 돌려 가게를 고르고 끄덕이며 4가지를 하나씩 확인한 뒤 구매를 기록한다.

## 방향 구성

한국 현지 × 방향성(고개를 돌려 가게 고르기) × 주의력(4가지 항목 확인). 방향성은 고개 방향으로 가게를 바꾸는 일을 맡고, 주의력은 4가지 항목을 하나씩 확인하는 일을 맡는다.

## 안경 전용 기능

시선과 머리 방향 맞추기: 두 손에 봉지를 들고 있을 때는 휴대전화를 꺼낼 수 없지만, 고개를 돌리면 그 가게가 골라지고 끄덕이면 확인이 된다. 접선: pages/index/index.ink의 _startSensor(AbsoluteOrientationSensor, 존재 여부 확인)와 _onYaw(±0.35로 가게 바꾸기, 정면으로 돌아오면 다시 준비) + onHeadGesture('nod')가 주 확인과 같다. 센서를 쓸 수 없을 때는 버튼으로 가게를 고를 수 있고, 센서 읽기 실패는 E7001을 남긴다.

## 솔직한 경계

- 가격과 신선도는 현장 매대가 정답이며, 안에 든 목록은 보기용이다.
- 4가지를 모두 확인하지 않은 가게는 기록하지 않는다.
- 센서를 쓸 수 없을 때는 버튼으로 가게를 고를 수 있다.

## 페이지

| 페이지 | 페이지 |
|---|---|
| pages/index | 가게 6곳 목록, 머리 방향으로 고르기 |
| pages/detail | 고른 가게에서 4가지를 끄덕이며 하나씩 확인하고 구매 기록 |
| pages/record | 최근 6건의 구매 기록과 합계 |

## 내용 집합

가게 6곳(빈대떡／마약김밥／육회／순대／어묵／떡볶이)×확인 4가지(샀다／가격을 확인했다／포장했다／가방에 넣었다), 모두 24가지 확인 항목. 기록은 실제 수로 센다.

## 저장

저장 키 `gwangjangMarketV1`. 고른 가게, 가게마다 확인한 항목 수, 구매 기록 배열, lastError를 저장한다.

## 권한

권한 없음. 음성 읽기는 권한이 필요 없고, 카메라와 위치 정보는 사용하지 않는다.

## 제스처

| 한 번 누르기 | Enter | 주 확인(상세 페이지에서는 한 가지 확인) |
| 위아래 밀기 | ArrowUp / ArrowDown | 가게 선택 바꾸기 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## 오류 코드

- `E5001` 저장 쓰기 실패
- `E5002` 저장 읽기 실패
- `E3005` 음성 읽기 실패
- `E8001` 페이지 이동 실패
- `E7001` 머리 센서를 쓸 수 없거나 읽기 실패

실패하면 화면에 있는 그대로의 코드를 보여주고, lastError에는 코드와 slug, 버전, 원래 문구를 함께 남긴다.

## 미리보기 스크린샷

![preview-gwangjang-market-index.png](../screenshots/gwangjang-market/preview-gwangjang-market-index.png)
![preview-gwangjang-market-detail.png](../screenshots/gwangjang-market/preview-gwangjang-market-detail.png)
![preview-gwangjang-market-detail-s2.png](../screenshots/gwangjang-market/preview-gwangjang-market-detail-s2.png)
![preview-gwangjang-market-record.png](../screenshots/gwangjang-market/preview-gwangjang-market-record.png)

## 제출 자료

### Feature Description

서울 광장시장에서 간식을 사는 사람이 두 손에 봉지를 들고, 고개를 돌려 가게를 고르고 끄덕이며 4가지를 하나씩 확인한 뒤 구매를 기록한다.

### Opening Message

광장시장에서 두 손이 바빠도 괜찮아요. 고개를 돌려 가게를 고르고, 끄덕이며 확인해요.

### Preview Media

[preview-gwangjang-market-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/gwangjang-market/preview-gwangjang-market-video.mp4)
![preview-gwangjang-market-index.png](../screenshots/gwangjang-market/preview-gwangjang-market-index.png)
![preview-gwangjang-market-detail.png](../screenshots/gwangjang-market/preview-gwangjang-market-detail.png)
![preview-gwangjang-market-record.png](../screenshots/gwangjang-market/preview-gwangjang-market-record.png)

### Change Log

- Features：초판 기능은 위와 같다.
- Improvements：없음.
- Fixes：없음.

## 기기 테스트 정보

| 항목 | 내용 |
|---|---|
| Studio 이름 | 미기입 |
| Version / Build | 미기입 |
| App Category | 미기입 |
| Intent Description | 미기입 |
| Agent ID | 미기입 |
| 상태 | 미기입 |

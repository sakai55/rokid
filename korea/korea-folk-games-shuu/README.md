# 한국민속놀이집

**Studio 가져오기 주소**(Global AIUI Studio Import Project 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-korea-folk-games-shuu
```

[korea-folk-games-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/korea-folk-games-shuu.aix)

## 기능

명절 기다리는 시간, 온 가족이 안경 한 대로 한국 민속놀이 20가지로 놀고, 놀이마다 점수를 정해 다음에도 남깁니다.

## 장면

명절 기다리는 시간, 온 가족이 안경 한 대로 한국 민속놀이로 놀고 점수를 정합니다.

## 방향 구성

한국 현지 × 게임 × 방향성 × 주의력.

## 안경 전용 능력

머리 방향 맞추기와 끄덕임이 주 확인입니다: 양손이 바빠도 고개를 돌려 방향을 고르고 끄덕임만으로 놀 수 있습니다. 접선: 모든 놀이 페이지의 onHeadGesture('nod')가 주 확인과 같고, 방향 놀이 페이지 t05／t08／t13／t18의 _startSensor(AbsoluteOrientationSensor, 존재 여부 확인) + _onYaw. 센서를 쓸 수 없을 때는 버튼으로 방향을 고를 수 있고, 센서 읽기 실패는 E7001을 남깁니다.

## 페이지

| 페이지 | 페이지 |
|---|---|
| pages/index | 민속놀이 20가지 목록 |
| pages/t01 | 공기세기 |
| pages/t02 | 구슬세기 |
| pages/t03 | 연날리기순서 |
| pages/t04 | 민속퀴즈 |
| pages/t05 | 팽이방향맞히기 |
| pages/t06 | 연세기 |
| pages/t07 | 강강술래순서 |
| pages/t08 | 술래방향맞히기 |
| pages/t09 | 널뛰기순서 |
| pages/t10 | 연색맞히기 |
| pages/t11 | 공기색맞히기 |
| pages/t12 | 팽이색맞히기 |
| pages/t13 | 그네방향맞히기 |
| pages/t14 | 공기계산 |
| pages/t15 | 씨름순서 |
| pages/t16 | 구슬계산 |
| pages/t17 | 비석세기 |
| pages/t18 | 연방향맞히기 |
| pages/t19 | 연계산 |
| pages/t20 | 민속놀이기록 |

## 내용 집합

20가지: 놀이 19가지(세기 4, 퀴즈 4, 방향 4, 순서 4, 계산 3) + 기록 1가지. 세기 목표 10／12／8／15, 방향은 한 판 6번, 순서는 한 판 5단계.

## 세션 간 저장

저장 키 `koreaFolkGamesV1`(고른 놀이, 놀이마다 최고 기록, 마친 기록, lastError).

## 권한

권한 없음. 음성 읽기는 권한이 필요 없고, 카메라와 위치 정보는 사용하지 않는다.

## 제스처 대응

| 한 번 누르기 | Enter | 주 확인 |
| 위아래 밀기 | ArrowUp / ArrowDown | 선택 전환 |
| 끄덕임 | onHeadGesture('nod') | 주 확인과 동일 |
| 두 번 누르기 | Backspace | 돌아가기 |

## 오류 코드

- `E5001` 저장 쓰기 실패
- `E5002` 저장 읽기 실패
- `E3005` 음성 읽기 실패
- `E8001` 페이지 이동 실패
- `E7001` 머리 센서 사용 불가 또는 읽기 실패

- 점수는 진짜 끄덕임과 누르기로만 정하며, 만든 점수는 없습니다.
- 센서를 쓸 수 없을 때는 버튼으로 방향을 고를 수 있고, 방향 놀이의 노는 법은 그대로입니다.

## 미리 보기 이미지

![preview-korea-folk-games-shuu-index.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-index.png)
![preview-korea-folk-games-shuu-t01.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t01.png)
![preview-korea-folk-games-shuu-t02.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t02.png)
![preview-korea-folk-games-shuu-t03.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t03.png)
![preview-korea-folk-games-shuu-t04.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t04.png)
![preview-korea-folk-games-shuu-t05.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t05.png)
![preview-korea-folk-games-shuu-t06.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t06.png)
![preview-korea-folk-games-shuu-t07.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t07.png)
![preview-korea-folk-games-shuu-t08.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t08.png)
![preview-korea-folk-games-shuu-t09.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t09.png)
![preview-korea-folk-games-shuu-t10.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t10.png)
![preview-korea-folk-games-shuu-t11.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t11.png)
![preview-korea-folk-games-shuu-t12.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t12.png)
![preview-korea-folk-games-shuu-t13.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t13.png)
![preview-korea-folk-games-shuu-t14.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t14.png)
![preview-korea-folk-games-shuu-t15.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t15.png)
![preview-korea-folk-games-shuu-t16.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t16.png)
![preview-korea-folk-games-shuu-t17.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t17.png)
![preview-korea-folk-games-shuu-t18.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t18.png)
![preview-korea-folk-games-shuu-t19.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t19.png)
![preview-korea-folk-games-shuu-t20.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t20.png)
![preview-korea-folk-games-shuu-t01-s2.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t01-s2.png)

## 심사 자료

### Feature Description

명절 기다리는 시간, 온 가족이 안경 한 대로 한국 민속놀이 20가지로 놀고, 놀이마다 점수를 정해 다음에도 남깁니다.

### Opening Message

한국 민속놀이에 오신 것을 환영합니다. 놀이를 골라 끄덕이며 놀아요. 점수는 잘 남습니다.

### Preview Media

[preview-korea-folk-games-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-video.mp4)
![preview-korea-folk-games-shuu-index.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-index.png)
![preview-korea-folk-games-shuu-t01.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t01.png)
![preview-korea-folk-games-shuu-t02.png](../../screenshots/korea-folk-games-shuu/preview-korea-folk-games-shuu-t02.png)

### Change Log

- Features：초판 기능은 위와 같다.
- Improvements：없음.
- Fixes：없음.

## 기기 시험 정보

| Studio 이름 | 미기입 |
|---|---|
| Studio 이름 | 미기입 |
| Version / Build | 미기입 |
| App Category | 미기입 |
| Intent Description | 미기입 |
| Agent ID | 미기입 |
| 상태 | 미기입 |

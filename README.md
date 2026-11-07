# 감천 사진 확인

**Studio 가져오기 주소**(Global AIUI Studio Import Project 입력란에 복사):

```
https://github.com/sakai55/rokid/tree/agent-gamcheon-photo
```

[gamcheon-photo.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/gamcheon-photo.aix)

## 기능

부산 감천문화마을을 찾는 관광객이 양손으로 안내 책자를 든 채 명소를 바라보고 끄덕임으로 사진을 찍어 12곳의 사진 지점을 확인하며, 한 곳이라도 빠지면 산책이 끝나지 않는다.

## 장면

부산 감천문화마을을 찾는 관광객이 양손으로 안내 책자를 든 채 명소를 바라보고 끄덕임으로 사진을 찍어 12곳의 사진 지점을 확인한다.

## 방향 구성

한국 현지 × 방향성(시선 사진 확인) × 주의력.

## 안경 전용 능력

두 손이 자유로운 1인칭 즉시 촬영: 양손으로 안내 책자를 든 채 휴대전화를 꺼낼 수 없을 때, 명소를 바라보고 끄덕이면 사진이 찍히며, 사진은 산책을 마치는 데 반드시 필요한 단계이다. 접선: pages/photo/index.ink의 photoTap(getUserMedia + ImageCapture.takePhoto), 끄덕임은 primaryTap이며, confirmTap은 사진이 없으면 마무리를 거부한다.

## 페이지

| 페이지 | 페이지 |
|---|---|
| pages/index | 명소 6곳 |
| pages/photo | 바라보고 잠그기, 끄덕임으로 사진 찍기, 12곳 확인 |
| pages/record | 마친 산책 기록 |

## 내용 집합

명소 6곳 × 사진 지점 2곳 = 12곳의 사진 지점(감천문화마을 입구: 입구 안내판／마을 지도 앞; 작은 왕자 전망대: 작은 왕자 조형물／부산 항구 전망; 물고기 계단: 물고기 벽화／계단 전망; 감천 언덕길: 언덕길 벽화／골목길 풍경; 감천문화마을 박물관: 박물관 입구／마을 모형 앞; 감천 전망대: 전망대 전경／마을 지붕 풍경).

## 세션 간 저장

저장 키 `gamcheonPhotoV1`(선택 명소, 확인한 사진 지점, 사진 시간과 바이트 수, 마친 산책 기록, lastError). 사진 자체는 세션 안에서만 보관하고 저장하지 않는다.

## 권한

CAMERA를 선언한다. 위치와 미디어 권한은 쓰지 않는다.

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
- `E8004` 카메라 인터페이스 없음
- `E2001` 사진 촬영 실패
- `E2013` 사진 인코딩 실패

- 사진은 본인 확인용으로만 쓰며, 다른 사람의 얼굴을 인식하지 않고 명소를 자동으로 인식한다고 주장하지 않는다.
- 사진이 없으면 마칠 수 없고, 확인하지 않은 사진 지점은 알림만 하고 기록을 남기지 않는다.
- 미리 보기에는 카메라가 없어 사진이 정직하게 실패하며, 성공한 것처럼 꾸미지 않는다.

## 미리 보기 이미지

![preview-gamcheon-photo-index.png](../screenshots/gamcheon-photo/preview-gamcheon-photo-index.png)
![preview-gamcheon-photo-photo.png](../screenshots/gamcheon-photo/preview-gamcheon-photo-photo.png)
![preview-gamcheon-photo-photo-s2.png](../screenshots/gamcheon-photo/preview-gamcheon-photo-photo-s2.png)
![preview-gamcheon-photo-record.png](../screenshots/gamcheon-photo/preview-gamcheon-photo-record.png)

## 심사 자료

### Feature Description

부산 감천문화마을을 찾는 관광객이 양손으로 안내 책자를 든 채 명소를 바라보고 끄덕임으로 사진을 찍어 12곳의 사진 지점을 확인하며, 한 곳이라도 빠지면 산책이 끝나지 않는다.

### Opening Message

부산 감천문화마을을 찾는 관광객이 양손으로 안내 책자를 든 채 명소를 바라보고 끄덕임으로 사진을 찍어 12곳의 사진 지점을 확인하며, 한 곳이라도 빠지면 산책이 끝나지 않는다.

### Preview Media

[preview-gamcheon-photo-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/gamcheon-photo/preview-gamcheon-photo-video.mp4)
![preview-gamcheon-photo-index.png](../screenshots/gamcheon-photo/preview-gamcheon-photo-index.png)
![preview-gamcheon-photo-photo.png](../screenshots/gamcheon-photo/preview-gamcheon-photo-photo.png)
![preview-gamcheon-photo-photo-s2.png](../screenshots/gamcheon-photo/preview-gamcheon-photo-photo-s2.png)

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

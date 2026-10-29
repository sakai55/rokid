# Sijang Shopping (시장 장보기)

**Studio 가져오기 주소**(Global AIUI Studio의 Import Project 입력란에 붙여 넣으세요):

```
https://github.com/sakai55/rokid/tree/agent-sijang-shopping
```

**AIX 직접 다운로드**(최신 버전): [sijang-shopping.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/sijang-shopping.aix)

KR15 · 한국 현지 × 커브 컷 × 주의. 부티크 라인 통합 재제작: CC09 `high-shelf-ask`(슈퍼마켓 높은 진열대 도움 요청 문구)와 KR14 `sijang-basket`(시장 바구니 확인)을 같은 장면(한국 전통시장 쇼핑)으로 합쳐 만들었고, 원래 두 Agent는 그대로 봉인해 삭제도 수정도 하지 않습니다. 한 줄 장면: 휠체어를 타거나 앉아서 한국 전통시장을 도는 사람이 높은 가판대 앞에서 정확한 도움 요청 문구를 만들고(TTS가 대신 말하거나 큰 글자로 보여줌), 가판대별로 장바구니를 항목마다 확인하며, 한 가지라도 빠지면 계산하지 않습니다.

## 미리보기 스크린샷

![미리보기-index](<../../screenshots/sijang-shopping/preview-sijang-shopping-index.png>)
![미리보기-ask](<../../screenshots/sijang-shopping/preview-sijang-shopping-ask.png>)
![미리보기-ask-s2](<../../screenshots/sijang-shopping/preview-sijang-shopping-ask-s2.png>)
![미리보기-basket](<../../screenshots/sijang-shopping/preview-sijang-shopping-basket.png>)

## 구조와 기능 (폐쇄 루프)

세 페이지 구조(시장 가판대 간판 그리드 / 큰 글자 도움 카드 / 장바구니 확인 목록), 상태는 세션을 넘어 저장됩니다(wx storage `sijangShoppingV1`):

- **전체 보기(pages/index)**: 가판대 6곳(채소가게/생선가게/과일가게/반찬가게/잡화가게/떡집) × 가판대마다 상품 2개의 진행 그리드. 전체 진행도(담은 개수/도움 완료 수/완료한 장보기 수)가 한눈에 들어옵니다.
- **도움 카드(pages/ask)**: 높은 곳 상품 콘텐츠 집합 4개(사과/수세미/멸치볶음/송편) × 도움 요청 문구 템플릿 4문장. 보고 고정하면 큰 글자 카드가 한국어 문장 전체를 보여주고, SPEAK는 TTS가 대신 말합니다. 고개 끄덕임(머리가 안정됐을 때)이나 CONFIRM이 「요청 완료」를 저장소에 기록합니다. 도움 요청 문구는 만들고 보여주거나 대신 말할 뿐이며, 도움을 받았는지는 Agent가 대신 판단하지 않습니다.
- **장바구니 확인(pages/basket)**: 상품 12개를 가판대별로 하나씩 체크하고, 빠진 항목 목록이 실시간으로 표시됩니다. 12개가 차지 않으면 CHECKOUT이 잠기고 음성으로 설명하며, 다 차면 계산하고 완료를 한 번 기록한 뒤 목록을 비워 다음을 준비합니다.

방향 분담: 커브 컷(휠체어/앉은 자세의 쇼핑객 우선)이 본체이며 일반 쇼핑 편의로 희석하지 않습니다. 주의는 항목마다의 확인과 빠진 항목 대기를 맡고, 한국 현지는 시장 가판대와 정중한 도움 요청 문구의 실제 장면을 맡습니다.

## 제스처 매핑

| 제스처 (안경다리 터치패드) | 키 이벤트 | 이 Agent에서의 역할 |
|---|---|---|
| 한 번 탭 | Enter | 장바구니 페이지에서 현재 가판대의 첫 항목 체크 / 도움 페이지에서 요청 확인 |
| 위로 / 아래로 스와이프 | ArrowUp / ArrowDown | 가판대 또는 높은 곳 상품 전환 |
| 고개 끄덕임 (머리가 안정됐을 때) | `onHeadGesture('nod')` | 도움 페이지에 「요청 완료」 기록 |
| 두 번 탭 | Backspace | 시스템 뒤로 가기(하위 페이지 BACK 키도 가능) |

## 권한

없음. TTS는 호스트 고정 음색을 사용하고, utterance의 `lang`은 절대 설정하지 않습니다.

## 정직한 경계

- 가판대와 상품은 내장 콘텐츠 집합이며, 온라인 연결이 없고 실시간 가격/재고가 없습니다.
- 언어 순도 기계 검사: 전체 .ink 일본어 가나 = 0, CJK 한자 = 0.

## 기기 테스트 정보

| 항목 | 값 |
|---|---|
| Studio name | Sijang Shopping (가져오기 후 기입 예정) |
| Version / Build | 1.0.0 |
| App Category | Life (가져올 때 확인) |
| Intent Description | 시장에서 높은 선반 도움 요청과 장바구니 확인 |
| Agent ID | 가져오기 후 기입 예정 |
| 상태 | 패키징 완료, 푸시 완료. Studio로 가져오지 않았고, 실기기 테스트 전, 심사 제출 전 |

## 심사 자료 (Review Submission)

### Feature Description (≤500 chars)

휠체어와 앉은 자세의 쇼핑객을 위한 전통시장 장보기 전체 여정: 가판대 여섯 곳과 상품 열두 개가 하나의 체크리스트에 있고, 한 가지라도 빠지면 계산을 거부합니다. 여기에 높은 가판대를 위한 큰 글자 도움 문구 카드(정중한 한국어 문구 네 가지, TTS가 말하거나 크게 표시, 요청은 고개 끄덕임으로 기록)가 더해집니다.

### Opening Message (≤500, Markdown)

**시장 장보기에 오신 것을 환영합니다.** 높은 선반에서는 도움 카드를, 장바구니에서는 빠진 물건을 확인하세요.

### Preview Media

이미지 4장(이 페이지의 미리보기 스크린샷). 동영상은 실기기 단계에서 추가합니다(심사 요건: 파일 3~5개, 이미지 1개 이상, 동영상 1개 이상).

### Change Log

#### Build 1.0.0
- Features added: 세 페이지 신작(전체 보기/도움 카드/장바구니 확인). CC09+KR14 통합 재제작, 가판대 6곳, 상품 12개, 높은 곳 도움 상품 4개 × 문형 4가지, 상태의 세션을 넘는 저장.
- Improvements: 없음 (첫 버전).
- Fixes: 없음 (첫 버전).

## 패키징과 미리보기

- 패키징: `~/tools/bin/aix pack . -o sijang-shopping.aix`(저장소 사본은 `aix/sijang-shopping.aix`에 있음)
- 미리보기: `~/tools/bin/aix preview . --html-out artifacts/preview.html` 실행 후 로컬 스크린샷 파이프라인 이용(포트 8902)

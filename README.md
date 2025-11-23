# 로또 당첨번호 확인 앱 🎰

한국 동행복권 로또 6/45의 당첨번호를 확인할 수 있는 iOS 앱입니다.

## 📱 주요 기능

- ✅ 최신 회차 당첨번호 자동 조회
- ✅ 이전/다음 회차 네비게이션
- ✅ 특정 회차 검색 기능
- ✅ 당첨금 및 당첨자 정보 표시
- ✅ 번호별 색상 구분
- ✅ 깔끔하고 직관적인 UI

## 🌐 사용된 API

동행복권 공식 API를 사용합니다:
```
https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo={회차번호}
```

## 🎨 번호 색상 규칙

- 1-10: 노란색 🟡
- 11-20: 파란색 🔵
- 21-30: 빨간색 🔴
- 31-40: 회색 ⚫
- 41-45: 초록색 🟢
- 보너스: 주황색 🟠

## 🛠 기술 스택

- **언어**: Swift 5.9+
- **프레임워크**: SwiftUI
- **아키텍처**: MVVM
- **비동기 처리**: Async/Await
- **네트워크**: URLSession

## 📋 요구사항

- iOS 17.0 이상
- Xcode 15.0 이상
- Swift 5.9 이상

## 🚀 설치 및 실행 방법

1. 압축 파일을 다운로드하고 압축을 해제합니다
2. `LottoChecker.xcodeproj` 파일을 더블클릭하여 Xcode에서 프로젝트를 엽니다
3. 시뮬레이터 또는 실제 기기를 선택합니다
4. `Command + R` 을 눌러 빌드 및 실행합니다

## 📁 프로젝트 구조

```
LottoChecker/
├── LottoChecker/
│   ├── LottoCheckerApp.swift      # 앱 진입점
│   ├── ContentView.swift           # 메인 화면 UI
│   ├── LottoModel.swift            # 데이터 모델
│   ├── LottoService.swift          # API 통신 서비스
│   ├── LottoViewModel.swift        # 뷰모델 (비즈니스 로직)
│   └── Assets.xcassets/            # 리소스 파일
└── LottoChecker.xcodeproj/         # Xcode 프로젝트 파일
```

## 📝 주요 파일 설명

### LottoModel.swift
- API 응답 데이터 구조 정의
- 데이터 포맷팅 헬퍼 함수 제공

### LottoService.swift
- 동행복권 API 호출 로직
- 최신 회차 자동 계산
- 에러 핸들링

### LottoViewModel.swift
- 앱의 상태 관리 (MVVM 패턴)
- API 데이터 로딩 및 캐싱
- 회차 네비게이션 로직

### ContentView.swift
- SwiftUI 기반 메인 UI 구현
- 당첨번호 시각화
- 회차 검색 기능

## 🎯 사용 방법

1. **앱 실행**: 자동으로 최신 회차의 당첨번호가 표시됩니다
2. **회차 이동**: 하단의 "이전 회차" / "다음 회차" 버튼으로 이동
3. **회차 검색**: 상단 오른쪽의 숫자 아이콘을 탭하여 원하는 회차 직접 입력

## 📊 API 응답 예시

```json
{
  "returnValue": "success",
  "drwNoDate": "2024-11-23",
  "drwNo": 1199,
  "drwtNo1": 16,
  "drwtNo2": 24,
  "drwtNo3": 25,
  "drwtNo4": 30,
  "drwtNo5": 31,
  "drwtNo6": 32,
  "bnusNo": 7,
  "firstWinamnt": 1695609839,
  "firstPrzwnerCo": 17,
  "totSellamnt": 115445320000
}
```

## ⚠️ 주의사항

- 인터넷 연결이 필요합니다
- 동행복권 서버 상태에 따라 응답이 지연될 수 있습니다
- 아직 추첨되지 않은 회차는 조회할 수 없습니다

## 📄 라이선스

이 프로젝트는 개인 학습 및 포트폴리오 목적으로 제작되었습니다.

## 🤝 기여

버그 리포트나 개선 제안은 언제든지 환영합니다!

## 📧 문의

문제가 발생하거나 질문이 있으시면 이슈를 등록해주세요.

---

**Made with ❤️ using SwiftUI**

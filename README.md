<div align="center">

# Perfect Split

**한 번의 스와이프. 완벽한 절단.**

정밀함의 예술을 추구하는 3D 퍼즐 게임

[![Platform](https://img.shields.io/badge/platform-iOS%2017.0+-lightgrey.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-16.0-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](#license)

</div>

---

## 소개

> **0.1% 이하의 오차로 `DIVINE`을 달성할 수 있을까?**

**Perfect Split**은 3D 도형을 정확히 반으로 가르는 단순하지만 깊이 있는 퍼즐 게임입니다.
손가락 하나로 화면을 가르면, 커스텀 Mesh Cutting 엔진이 실시간으로 도형을 이등분하고
**부피 오차율**로 정확도를 평가합니다.

| 정확도 | 등급 |
|:---:|:---:|
| `오차 ≤ 0.1%` | **DIVINE** |
| `오차 ≤ 1%` | **PERFECT** |
| `오차 ≤ 5%` | **GREAT** |
| `오차 ≤ 15%` | **GOOD** |

<img width="1170" height="2407" alt="KakaoTalk_Photo_2026-04-23-23-10-41" src="https://github.com/user-attachments/assets/73da6a8a-3af7-4858-a788-e99d8847b083" />
<img width="1170" height="2391" alt="KakaoTalk_Photo_2026-04-23-23-10-35 001" src="https://github.com/user-attachments/assets/21619490-2b4f-48a8-ab14-585358775273" />
<img width="1170" height="2391" alt="KakaoTalk_Photo_2026-04-23-23-10-35 002" src="https://github.com/user-attachments/assets/aa6a917c-95bf-41fc-adc9-65e8f968cf82" />

---

## 주요 기능

### 실시간 Mesh Cutting 엔진
임의의 평면으로 3D 메쉬를 절단하고, 새로운 절단면(cap)을 삼각분할로 생성합니다.
자체 구현한 **Ear Clipping** 알고리즘으로 볼록/오목 다각형 모두 처리 가능.

### 20종 도형 × 80 스테이지
기본 입체부터 비대칭 크리스털, Chaos Polyhedron까지 점진적 난이도 설계.

```
큐브  →  프리즘  →  다이아몬드  →  별 프리즘  →  Razor Crystal  →  Chaos Polyhedron
```

### 난이도 모드
| 모드 | 특징 |
|---|---|
| **Easy** | 도형 회전 고정, 시각 가이드 제공 |
| **Hard** | 무작위 회전, 가이드 최소화 |

### 연속 자르기 모드 (Continuous Split)
하나의 도형을 여러 번 연속으로 잘라 누적 점수를 경쟁합니다.

---

## 기술 스택

| 영역 | 사용 기술 |
|---|---|
| **언어** | Swift 6 |
| **UI** | SwiftUI |
| **3D 렌더링** | SceneKit |
| **지오메트리 코어** | 순수 Swift (의존성 없음) |
| **사운드** | AVFoundation |
| **수익화** | Google Mobile Ads SDK |
| **개인정보 프레임워크** | App Tracking Transparency |

---

## 프로젝트 구조

```
Perfect_Split/
├── Audio/                          음향 리소스 (BGM, SFX)
│   ├── bgm.mp3
│   ├── Click.mp3 / Slice.mp3
│   ├── Clear.mp3 / fail.mp3
│   └── Divine.mp3
│
└── Perfect_Split/
    ├── Core/
    │   ├── Geometry/               MeshCutter · Plane · VolumeCalculator
    │   └── Mesh/                   Mesh · MeshConversion
    │
    ├── Game/
    │   ├── Input/                  SwipeToPlaneConverter
    │   ├── Scenes/                 SceneKitView · ShapeController
    │   └── Shapes/                 ShapeFactory (20종 도형 생성)
    │
    ├── Data/                       Stage · ProgressStore · CutStats
    ├── Services/                   AdService · SoundManager
    ├── UI/
    │   ├── Views/                  Main · Game · Settings · StageSelect
    │   └── HUD/                    ResultOverlay
    └── Assets.xcassets
```

### 핵심 모듈

**`Core/Geometry/MeshCutter.swift`**
삼각형 단위로 메쉬를 순회하며 평면과의 교점을 계산, 양/음 반공간으로 분할.
절단면은 `CutPiece { body, cap }` 구조로 분리 저장되어 캡만 별도 처리 가능.

**`Core/Geometry/VolumeCalculator.swift`**
부호 있는 사면체 부피 합산법으로 임의 메쉬의 체적 계산.
원본 부피와 절단 조각의 비율로 정확도 산출.

**`Game/Input/SwipeToPlaneConverter.swift`**
2D 스와이프 좌표를 카메라 공간의 3D 절단 평면으로 변환.

---

## 빌드 방법

### 요구사항
- macOS 14.0+ (Sonoma 이상)
- Xcode 16.0+
- iOS 17.0+ 타겟 기기 또는 시뮬레이터

### 실행
```bash
git clone https://github.com/dlalsdyd01/Perfect_Split.git
cd Perfect_Split
open Perfect_Split.xcodeproj
```

Xcode에서 `Cmd + R`로 빌드 및 실행.

> **Note**: `Config/Info.plist`는 보안상 리포지토리에서 제외되어 있습니다.
> AdMob 통합을 테스트하려면 본인의 AdMob App ID로 `Config/Info.plist`를 생성해야 합니다.

---

## 설정 커스터마이징

`SettingsView`에서 다음 항목을 조정할 수 있습니다.

- BGM 활성화 및 볼륨
- SFX 활성화 및 볼륨
- 기록 초기화

진행 상황은 `UserDefaults`에 `perfect_split.*` 네임스페이스로 저장됩니다.

---

## 로드맵

- [x] 1.0 — 첫 출시 (80 스테이지, 2 난이도)
- [ ] 1.1 — 광고 제거 인앱 결제
- [ ] 1.2 — Game Center 리더보드 연동

---

## License

Copyright © 2026 Minyong Lee. All rights reserved.

이 프로젝트의 소스 코드는 공개되어 있지만, **상업적 재배포 및 2차 창작을 금지**합니다.
학습 목적의 참고는 자유롭게 허용됩니다.

---

<div align="center">


</div>

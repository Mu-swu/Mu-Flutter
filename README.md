# 🎙️ MU (Messy to Unmessy) - 성향 맞춤형 비움 실천 서비스

> **"비워야 공간이 생긴다"**
> MU는 사용자의 비움 성향을 분석하고, 공간 밀집도 기반의 실시간 AI 미션 스케줄링을 통해 실질적인 행동 변화를 이끄는 태블릿 전용 비움 실천 솔루션입니다.

---

## ✨ Key Experience

### 1. 성향별 맞춤 비움 솔루션 (Psychological Customization)
사용자의 심리적 특성에 따라 3가지 유형의 AI 코디네이터가 매칭되어 최적의 비움 경험을 제공합니다.
* **방치형**: 실행력이 부족한 사용자를 위해 **단호한 멘트와 타이머**로 긴장감 있는 미션 수행을 유도합니다.
* **감정형**: 물건을 놓지 못하는 사용자를 위해 **따뜻한 공감과 모래시계**를 활용해 심리적 부담을 완화합니다.
* **몰라형**: 정리 기준이 없는 사용자를 위해 **구체적인 예시 가이드와 답변형 인터랙션**으로 스스로 판단할 수 있도록 돕습니다.

### 2. AI 실시간 맞춤형 미션 생성 (AI-Driven Mission Engine)
* **On-Device AI 분석**: 사진으로 촬영된 비움 환경(냉장고, 옷장, 서랍장 등)의 밀집도를 분석합니다.
* **실시간 미션 설계**: 사용자의 성향 데이터와 공간 밀집도 데이터를 결합하여, AI가 실시간으로 최적의 미션 순서와 실천 시간을 계산해 행동을 유도합니다.

### 3. 음성 기반 자동 카테고리 분류 (AI Voice Classification)
* **간편한 물품 등록**: 버릴 물품의 이름을 목소리로 말하면, STT(Speech-to-Text) 기술을 통해 즉시 인식합니다.
* **지능형 카테고리 매핑**: 인식된 물품 데이터를 분석하여 AI가 자동으로 적절한 카테고리에 분류하고 등록해줍니다.

### 4. 태블릿 최적화 UX (Tablet-First Design)
* **대화면 특화 레이아웃**: 태블릿 환경에 최적화된 대시보드를 통해 비움 현황, 보관 잔여일, 스케줄을 한눈에 관리합니다.
* **풍부한 인터랙션**: Lottie 애니메이션과 비디오 요소를 활용하여 AI 코디네이터와 실제로 소통하는 듯한 몰입형 경험을 제공합니다.

---

## 🛠 Technical Deep Dive

### 1️⃣ LLM & On-Device AI 통합
* **Google Generative AI**: 사용자의 성향과 상황에 맞는 실시간 맞춤형 미션 멘트와 가이드를 생성합니다.
* **TFLite 기반 분석**: 객체 탐지 기술을 활용하여 공간 내 물품의 밀집도를 분석하고 비움 스케줄링의 기초 데이터로 활용합니다.

### 2️⃣ 고도화된 음성 및 시각 인터랙션
* **STT/TTS**: `speech_to_text`와 `flutter_tts`를 결합하여 손이 자유롭지 않은 비움 상황에서도 원활한 인터랙션이 가능하도록 구현했습니다.
* **멀티미디어 활용**: `just_audio`와 `video_player`를 통해 성향별 맞춤 배경음악(BGM)과 로딩 영상을 제공하여 UX 완성도를 높였습니다.

### 3️⃣ 로컬 데이터 최적화 및 상태 관리
* **Drift (SQLite)**: 사용자의 성향 테스트 결과, 비움 히스토리, 공간별 밀집도 데이터를 로컬 환경에서 안정적으로 관리합니다.
* **Provider**: 복잡한 AI 인터랙션과 실시간 미션 상태를 효율적으로 관리하여 끊김 없는 사용자 경험을 제공합니다.

---

## ⚙️ Tech Stack
- **Framework**: Flutter (Dart)
- **AI**: Google Generative AI (Gemini), TFLite (TensorFlow Lite)
- **Database**: Drift (SQLite)
- **Speech**: Speech-to-Text (STT), Flutter TTS
- **State Management**: Provider
- **Design**: Tablet-Optimized Layout, Lottie Animations

---

## 👨‍💻 Team
- **Flutter Developer**: 이유진, 김정아
- **PM**: 홍재원
- **UX Designer**: 김지안
- **Visual Designer**: 김윤영
- **Advisors**: 고혜영 교수님, 이기한 교수님

---
Copyright © 2026 MU Team. All rights reserved.
<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/daaf4b7c-2dad-478a-aed6-feb3dfe9e9ad" />

<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/ead7b260-b6ae-4849-82e6-105e2059953c" />

<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/e14ad5df-41b2-470b-95c5-4e1a90b25351" />

<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/3a9875bc-e8fe-4aa4-b834-0cc120385aa2" />

<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/0a5f645d-8f11-46e8-a195-98d2757a710e" />

<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/df79510f-0f02-4094-bc14-1a6a4f083d83" />

<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/f35a9af8-e551-48ee-843f-a200e4d53a32" />
<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/35df4374-5caa-4bd5-8d35-ada6b4ede572" />
<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/12dab9ce-8b51-4cb8-9066-ad51294ebb8d" />

<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/838760f2-4b40-4224-b9a2-373e998f7df1" />

<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/8f04aa1d-e9f8-4e48-bf92-abe0c939fac3" />
